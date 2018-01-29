###########################################################
# AUTHOR  : Victor Ashiedu 
# WEBSITE : iTechguides.com
# BLOG    : iTechguides.com/blog-2/
# DATE    : 25-09-2014
# COMMENT : This  Powershell script creates Active Directory users from a csv file
#           User names are created in the format FirstName.LastName. Script also populates manager, 
#           UPN, email address, and other user properties then sets Password must change at next logon.
###########################################################

#Define location of my script variable
#the -parent switch returns one directory lower from directory defined. 
#below will return up to ImportADUsers folder 
#and since my files are located here it will find it.
#It failes withpout appending "*.*" at the end
#This file is required to update fields for existing users
#Modify this script to create new users in UnifiedGov domain



#Define CSV and log file location variables
#they have to be on the same location as the script

$logfile = $path + "\logfile.txt"
$i        = 0
$date     = Get-Date

#Define variable for a server with AD web services installed

$ADServer = '70411SRV'


#Get Admin accountb credential

$GetAdminact = Get-Credential 

#Import Active Directory Module

Import-Module ActiveDirectory

#Set the OU to add new users.

$location = "OU=FromCSV,OU=TestUsers,DC=70411Lab,DC=com"


#Import CSV file and update users in the OU with details in the fileh
#Create the function script to update the users

Function Create-ADUsers {

"AD user creation logs for( " + $date + "): " | Out-File $logfile -append
"--------------------------------------------" | Out-File $logfile -append

ForEach-Object { 

$GivenName = $_.'FirstName'
$Surname = $_.'LastName'
$DisplayName = $_.'Display Name'
$Username = $_.username
$Title = $_.Title
$Office = $_.location
$Phone = $_.Phone
$Fax = '+18666885929'
$Manager = $_.Manager
$password = $_.Password
$ManagerDN = (Get-ADUser -server $ADServer -Credential $GetAdminact -LDAPFilter "(DisplayName=$Manager)").DistinguishedName #Manager required in DN format


#change country to to be landcodes in order for AD to accept them format, 
#For example,United Kingdom is GB
If ($Country -eq "United Kingdom") {$Country = "GB"} 

#Define samAccountName to use with NewADUser in the format firstName.LastName

$sam = $Username

#Define domain to use for UserPrincipalName (UPN)

$Domain = '@medicalsolutions.com'


#Define UerPrincipalname 

$UPN = $sam + $Domain

#Now create new users using info from CSV
#First check whether the user exist, if use is not in ad, create it

Try   { $nameinAD = Get-ADUser -server $ADServer -Credential $GetAdminact -LDAPFilter "(sAMAccountName=$sam)" }
    Catch { }
    If(!$nameinAD)
    {
      $i++


#Create new AD accounts using the info from the CSV
#If "-enabled $TRUE" is not set, the account will be disabled by default

$setpassword = ConvertTo-SecureString -AsPlainText $password -force
      New-ADUser $sam -server $ADServer -Credential $GetAdminact `
      -GivenName $GivenName -ChangePasswordAtLogon $TRUE `
      -Surname $Surname -DisplayName $DisplayName -Office $Office `
      -Description $Description -EmailAddress $Mail `
      -StreetAddress $StreetAddress -City $City -state $State  `
      -PostalCode $PostCode -Country $Country -UserPrincipalName $UPN `
      -Company $Company -Department $Department -enabled $TRUE `
      -Title $Title -OfficePhone $Phone -AccountPassword $setpassword

 #Set manager property#necessary as manager may not exist while the users are being created
 #with New-ADUser command above. Manager switch only accepts name in DN format

 Set-ADUser -server $ADServer -Credential $GetAdminact -Identity $sam -Manager $ManagerDN

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

Else
    { #Update log file with users not created  
      $DisplayName + " Not Created - User Already Exists" | Out-File $logfile -append
    }

    }
    }
# Run the function script 
Create-ADUsers
#Finish