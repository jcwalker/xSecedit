
$rule = @{

    Policy   = 'Access_Credential_Manager_as_a_trusted_caller'
    Identity = 'builtin\Administrators','contoso\testuser1'
}

$removeAll = @{
    
    Policy = 'Act_as_part_of_the_operating_system'
    Identity = 'NULL'
}

configuration MSFT_UserRightsAssignment_config {
    Import-DscResource -ModuleName SecurityPolicyDsc
    
    xUserRightsAssignment AccessCredentialManagerAsaTrustedCaller
    {
        #Assign shutdown privileges to only Builtin\Administrators
        Policy   = $rule.Policy
        Identity = $rule.Identity
    }
    
    UserRightsAssignment RemoveAllActAsOS
    {
        Policy   = $removeAll.Policy
        Identity = $removeAll.Identity
    }
    
}