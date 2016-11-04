
data LocalizedData
{
    ConvertFrom-StringData @'
        TaskSuccess=Task successfully completed
        TaskSuccessFail=Task did not complete successfully
        NotDesiredState=Policy: {0} not in a desired state.
'@

}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    $returnValue = @{
        Path = [System.String]$Path
    }

    $returnValue    
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    $securityCdmlets = Get-Module -Name SecurityCmdlets -ListAvailable

    if ($securityCdmlets)
    {
        Restore-SecurityPolicy -Path $Path
    }
    else
    {
        $script:seceditOutput = "$env:TEMP\Secedit-OutPut.txt"
    
        Invoke-Secedit -UserRightsToAddInf $Path -SecEditOutput $script:seceditOutput
    }
    # Verify secedit command was successful
    $testSuccuess = Test-TargetResource -Path $Path -Verbose:0

    if ($testSuccuess -eq $true)
    {
        Write-Verbose -Message ($LocalizedData.TaskSuccess)
    }
    else
    {
        $seceditResult = Get-Content $script:seceditOutput
        Write-Error -Message ($LocalizedData.TaskSuccessFail)        
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path
    )
    
    $securityCdmlets = Get-Module -Name SecurityCmdlets -ListAvailable
    $currentUserRightsInf = ([system.IO.Path]::GetTempFileName()).Replace('tmp','inf')
    $fileExists = Test-Path -Path $Path

    if ($fileExists -eq $false)
    {
        throw "$Path not found"
    }

    if ($securityCdmlets)
    {
        Backup-SecurityPolicy -Path $currentUserRightsInf
    }
    else
    {
        Get-SecInfFile -Path $currentUserRightsInf | Out-Null
    }

    $currentPolicies = Get-CurrentPolicy -Path $currentUserRightsInf
    $desiredPolicies = Get-DesiredPolicy -Path $Path

    $policyNames = $desiredPolicies.keys

    foreach ($policy in $policyNames)
    {
        # Because Compare-Object throws an error if passed a NULL object if have to test NULL values.
        if ([String]::IsNullOrWhiteSpace($currentPolicies[$policy]) -and [String]::IsNullOrWhiteSpace($desiredPolicies[$policy]))
        {
            $testForNull = $true
        }
        else
        {
            try
            {
                $compareResult = $null
                $compareResult = Compare-Object -ReferenceObject $currentPolicies[$policy] -DifferenceObject $desiredPolicies[$policy] -IncludeEqual -ErrorAction Stop
            }
            catch
            {
                Write-Warning $_
            }
        }
        if($compareResult.SideIndicator -ne '==' -and $testForNull -ne $false)
        {
            Write-Verbose -Message ($LocalizedData.NotDesiredState -f $Policy)
            return $false
        }       
    }

    # If the code made it this far all policies must be in a desired state
    return $true
}


Export-ModuleMember -Function *-TargetResource

