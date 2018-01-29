<#
.SYNOPSIS
Import list of users and parse out the information

.DESCRIPTION
Import a CSV with the attributes and names of new hires that need to have AD accounts created. Use the attributes from
the CSV to create the username and pass the attributes to various other functions

.PARAMETER NewHires
Parameter that will accept import-csv from the pipeline. It will store the information and allow us to parse it

.PARAMETER FirstName
First name of the new user, will be passed to Find-MSADUser to help create the username

.PARAMETER LastName
Last name of the new hire, it will be passed onto FInd-MSADuser to create the username

.PARAMETER Manager
Manger to complete the manager field in the AD Property.

.PARAMETER Location
Location to complete the Office field in the AD property
.PARAMETER Title
Title to complete the titel field in the AD property
.PARAMETER OfficePhone
Phone number to complete the Telephone field and extension6 attribute.
.PARAMETER MobilePhone
Cell phone number to complete option mobile number field. It will also go into extension7

.PARAMETER CopyUser
This copy user (Existing AD User) will be used to copy group memberships over to the new user.

.EXAMPLE
Import-CSV C:\User\Fakeuser\Fakepath\FakeCSV.csv | Get-MSNewHire

.EXAMPLE
Get-MSNewHire -Firstname Eric -LastName Smith -Manager Jimmy Valmer -Location South Park -Title Comedian -OfficePhone 555.555.5555

.NOTES
This tool was designed to be used with a CSV using these specific headers
#>
function Get-MSNewHire {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True,
            ValueFromPipeline = $True)]
        [string[]]$NewHires,

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
        [ValidateSet ("Denver", "Omaha", "Cincinnati", "Tupelo")]
        [string]
        $Location, 


        [Parameter(Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]
        $Title,

        [Parameter(Mandatory = $True,
            ValueFromPipelineByPropertyName = $True)]
        [string]
        $OfficePhone,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $True)]
        [string]
        $MobilePhone,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $True)]
        [string]
        $CopyUser

    )
    BEGIN {}
    PROCESS {

        ForEach ($NewHire in $NewHires) {
            #Pass the first name and last name variable to Find-MSADuser which will return a useable username
            [String] $username = Find-MSADUser -FirstName $FirstName -LastName $LastName
            
            $properties = @{'FirstName' = $_.firstname
                'LastName' = $_.lastname
                'Manager' = $_.manager
                'Location' = $_.location
                'Title' = $_.title
                'OfficePhone' = $_.officephone
                'MobilePhone' = $_.mobilephone
                'CopyUser' = $_.copyuser
                'Username' = $username
            }#End of Parameters

            $NewUser = New-Object psobject -Property $properties

            Write-Output $NewUser
        }#End ForEach

    } #PROCESS
    END {}
}#End of Function