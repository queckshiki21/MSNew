<#
.SYNOPSIS
Check existing accounts and see if the username exist
.DESCRIPTION
Check with current user accounts and if they exist continue to add one letter from the last name until a useable 
username has been found.
.PARAMETER FirstName
First name passed from the pipeline and used as the first test for username
.PARAMETER LastName
Last name passed from the piepline and broken down letter by letter to adjust the username until a useable one is found.
.Example
Find-MSADUser -Firstname Eric -LastName Smith
Import-csv C:\Users\FakePath\FakeCSV.csv | Find-MSADUser

#>
Function Find-MSADUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FirstName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $LastName

    )
    BEGIN {}
    PROCESS {
        try {
            #If the firstname is found in the Trax Database, then add one letter from the last name.
            #Cycle through until a combination is not found by Database and then check the username against Active Directory.
            If (invoke-sqlcmd -query "select * from Trax.dbo.employee where AdLogin='${FirstName}'" -ServerInstance "sql-sm") {
                $FirstName = $FirstName + $LastName.substring(0, 1)
                $LastName = $LastName.Substring(1)
                Find-MSADUser -FirstName $FirstName -LastName $LastName
            }elseif (Get-ADUser -Identity $FirstName){
                        $FirstName = $FirstName + $LastName.substring(0, 1)
            $LastName = $LastName.Substring(1)
            Find-MSADUser -FirstName $FirstName -LastName $LastName
            }#End ElseIf

        }#End Try
        catch {

                        $FirstName
        }#End Catch

    }#End Process
    END {}
}#End Funtion

