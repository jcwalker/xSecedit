
$script:DSCModuleName   = 'SecurityPolicyDsc'
$script:DSCResourceName = 'MSFT_UserRightsAssignment'

#region HEADER
try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'
#endregion

try
{
    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($script:DSCResourceName)_Integration" {

        #region DEFAULT TESTS
        Context "Default Tests" {
            It 'Should compile without throwing' {
                {
                    & "$($script:DSCResourceName)_Config" -OutputPath $TestDrive
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should not throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }
        }
        #endregion

        Context 'Verify Successful Configuration on Trusted Caller' {
            Import-Module "$PSScriptRoot\..\..\DSCResources\MSFT_UserRightsAssignment\MSFT_UserRightsAssignment.psm1"
            Import-Module "$PSScriptRoot\..\..\Modules\SecurityPolicyResourceHelper\SecurityPolicyResourceHelper.psm1"
            It 'Should have set the resource and all the parameters should match' {
                $getResults = Get-TargetResource -Policy $rule.Policy -Identity $rule.Identity
                foreach ($Id in $rule.Identity)
                {
                    $Id = ConvertTo-LocalFriendlyName -Identity $Id
                    $getResults.Identity | Where-Object {$_ -eq $Id} | Should Be $Id
                }

                $rule.Policy | Should Be $getResults.Policy
            }
        }

        Context 'Verify Success on Act as OS remove all' {

            It 'Should have set the resource and all the parameters should match' {
                $getResults = Get-TargetResource -Policy $removeAll.Policy -Identity $removeAll.Identity

                foreach ($Id in $removeAll.Identity)
                {
                    $getResults.Identity | Where-Object {$_ -eq $Id} | Should Be $null
                }

                $removeAll.Policy | Should Be $getResults.Policy
            }
        }

        Context 'Verify Guests removed from deny log on locally' {
            Import-Module "$PSScriptRoot\..\..\DSCResources\MSFT_UserRightsAssignment\MSFT_UserRightsAssignment.psm1"
            $getResults = Get-TargetResource -Policy $removeGuests.Policy -Identity $removeGuests.Identity
            $testResults = Test-TargetResource -Policy $removeGuests.Policy -Identity $removeGuests.Identity -Ensure 'Absent'

            It 'Should remove Guests' {
                $getResults.Identity | Should Not Be $removeGuests.Identity
            }

            It 'Should return true when testing for ABSENT' {
                $testResults | Should Be $true
            }
        }
    }
    #endregion
}

finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
    #endregion
}
