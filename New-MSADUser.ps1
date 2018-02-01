<#
.SYNOPSIS
Use the information from the Get-MSNewHire command to create a new Active Directory User

.DESCRIPTION
Take a list of new hires and create Active directory users from them. The users will then
be moved to the correct OU based on their office location. Finally they will have group memberships
copied over from an existing user

.EXAMPLE
import-csv 'C:\Users\FakeUser\desktop\New Hires.csv' | Get-MSNewHire | New-MSADUsers

.EXAMPLE
New-MSADusers -GivenName Timmy -Surname Balmer -Username Timmys -Title....

.NOTES
General notes
#>

#Define CSV and log file location variables
#they have to be on the same location as the script

$logfile = '\\ms\tools\helpdesk\Eric Scripts\logfile.txt'
$i = 0
$date = Get-Date

#Define variable for a server with AD web services installed

$ADServer = 'DC-SM'


#Get Admin accountb credential

$GetAdminact = Get-Credential 

#Import Active Directory Module

Import-Module ActiveDirectory

#Set the OU to add new users.

$location = "OU=$location,OU=Users,OU=MedSol.local,DC=MedicalSolutions,DC=local"


#Import CSV file and update users in the OU with details in the fileh
#Create the function script to update the users

Function New-MSADUsers {
    [CmdletBinding()]
    Param(
        # Parameter help description
        [Parameter(Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]
        $FirstName,

        [Parameter(Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]
        $LastName,

        [Parameter(Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]
        $Manager,

        [Parameter(Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [ValidateSet ("Denver", "Omaha", "Cincinnati", "Tupelo", "San Diego")]
        [string]
        $Location, 

        [Parameter(Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]
        $Title,

        [Parameter(Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [ValidateLength(0, 10)]
        [string]
        $locationPhone,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $True)]
        [ValidateLength(0, 10)]
        [string]
        $MobilePhone,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $True)]
        [string]
        $CopyUser
    )

    "AD user creation logs for( " + $date + "): " | Out-File $logfile -append
    "--------------------------------------------" | Out-File $logfile -append

    ForEach-Object { 

        $FirstName = $_.'FirstName'
        $LastName = $_.'LastName'
        $DisplayName = "$_.FirstName" + "$_.Lastname"
        $Username = $_.username
        $Title = $_.Title
        $location = $_.location
        $OfficePhone = $_.OfficePhone
        $MobilePhone = $_.MobilePhone
        $Fax1 = '+18666885929'
        $Fax = '866.688.5929'
        $Manager = $_.Manager
        $password = 'MedicalSolutions123!'
        $CopyUser = $_.CopyUser
        $ManagerDN = (Get-ADUser -server $ADServer -Credential $GetAdminact -LDAPFilter "(DisplayName=$Manager)").DistinguishedName #Manager required in DN format


        #Define samAccountName to use with NewADUser in the format firstName + last initials as needed

        $sam = $Username

        #Define domain to use for UserPrincipalName (UPN)

        $Domain = '@medicalsolutions.com'


        #Define UerPrincipalname 

        $UPN = $sam + $Domain

        #Now create new users using info from CSV
        #First check whether the user exist, if use is not in ad, create it (This is a 
        #double check in case there are multiple users that end up with the same username)

        Try { $nameinAD = Get-ADUser -server $ADServer -Credential $GetAdminact -LDAPFilter "(sAMAccountName=$sam)" }
        Catch { }
        If (!$nameinAD) {
            $i++


            #Create new AD accounts using the info from the CSV
            #If "-enabled $TRUE" is not set, the account will be disabled by default

            $setpassword = ConvertTo-SecureString -AsPlainText $password -force

            New-ADUser $sam -server $ADServer -Credential $GetAdminact `
                -GivenName $FirstName -ChangePasswordAtLogon $FALSE `
                -Surname $LastName -DisplayName $DisplayName -Office $location `
                -UserPrincipalName $UPN -enabled $TRUE `
                -Title $Title -OfficePhone "+1$OfficePhone" -MobilePhone "+1$MobilePhone" -Fax $Fax1 -AccountPassword $setpassword

            #Change phone number style to 111.222.3333 to add to the attribute for Skype
            #Set manager property#necessary as manager may not exist while the users are being created
            #with New-ADUser command above. Manager switch only accepts name in DN format

            $OfficePhone = '{0}.{1}.{2}' -f $OfficePhone.Substring(0, 3), $OfficePhone.Substring(3, 3), $OfficePhone.Substring(6, 4)
            $MobilePhone = '{0}-{1}-{2}' -f $MobilePhone.Substring(0, 3), $MobilePhone.Substring(3, 3), $MobilePhone.Substring(6, 4)
            Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Manager $ManagerDN -Add @{extensionAttribute6 = "$OfficePhone"} -Add @{extensionAttribute7 = "$MobilePhone"} -Add @{extensionAttribut8 = "$fax"}

            #Use the CopyUser variable to copy the group memeberships over to the new user.
            Get-ADUser -Identity $CopyUser -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $sam

            #Define DN to use in the  Move-ADObject command

            $dn = (Get-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam).DistinguishedName
 
            # Move the users to the OU set above. 

            Move-ADObject -server $ADServer -Credential $GetAdminact -Identity $dn -TargetPath $location 
 
            # Rename the object to a good looking name to avoid displaying sAMAccountNames (eg tests1.user1)
            #First create usernames as DNs, Rename-ADObject only accepts DistinguishedNames
 
            $newdn = (Get-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam).DistinguishedName
            Rename-ADObject -server $ADServer -Credential $GetAdminact -Identity $newdn -NewName $DisplayName
 
            #Update log file with users created successfully

            $DisplayName + " Created successfully" | Out-File $logfile -append

        }

        Else {
            #Update log file with users not created  
            $DisplayName + " Not Created - User Already Exists" | Out-File $logfile -append
        }

    }
}
# Run the function script 
#Finish