<#
.SYNOPSIS
 Converts user names between formats.

.DESCRIPTION
 Converts user names between formats. Uses the ComObject NameTranslate.

.PARAMETER UserName
 The user(s) to convert.

.PARAMETER InputType
 Supports:
    - Unknown (default)
    - DistinguishedName
    - CanonicalName
    - NTAccount
    - DisplayName
    - DomainSimple
    - EnterpriseSimple
    - GUID
    - UserPrincipalName
    - CanonicalEx
    - ServicePrincipalName
    - SID

.PARAMETER OutputType
 Supports:
    - DistinguishedName
    - CanonicalName
    - NTAccount
    - DisplayName
    - DomainSimple
    - EnterpriseSimple
    - GUID
    - UserPrincipalName
    - CanonicalEx
    - ServicePrincipalName
    - SID

.PARAMETER Credential
 Credential used for binding to domain.
#>
function _ConvertUserNameFormat {

    [CmdletBinding()]
    param (
        
        [Parameter(Mandatory, Position=0)]
        [string[]]
        $UserName,

        [TranslateType]
        $InputType = 'Unknown',

        [Parameter(Mandatory)]
        [ValidateSet(
            'DistinguishedName',
            'CanonicalName',
            'NTAccount',
            'DisplayName',
            'DomainSimple',
            'EnterpriseSimple',
            'GUID',
            'UserPrincipalName',
            'CanonicalEx',
            'ServicePrincipalName',
            'SID'
        )]
        [TranslateType]
        $OutputType,

        [TranslateContext]
        $Context = 'GlobalCatalog',

        [pscredential]
        $Credential

    )

    $NameTranslateComObject = New-Object -ComObject 'NameTranslate'
    $NameTranslateType = $NameTranslateComObject.GetType()

    # if a credential is supplied we use the InitEx method
    if ( $Credential ) {

        $NameTranslateType.InvokeMember( 'InitEx', 'InvokeMethod', $null, $NameTranslateComObject, ( $Context, $null, $Credential.GetNetworkCredential().UserName, $Credential.GetNetworkCredential().Domain, $Credential.GetNetworkCredential().Password ) ) > $null

    # otherwise just init with the default user context
    } else {

        $NameTranslateType.InvokeMember( 'Init', 'InvokeMethod', $null, $NameTranslateComObject, ( $Context, $null ) ) > $null

    }

    $UserName | ForEach-Object {

        # set the current user name
        $NameTranslateType.InvokeMember( 'Set', 'InvokeMethod', $null, $NameTranslateComObject, ( $InputType, [string]$_ ) ) > $null

        # if output type is SID we have to do extra conversion
        if ( $OutputType -eq [TranslateType]::SID ) {

            [System.Security.Principal.NTAccount]$NTAccount = $NameTranslateType.InvokeMember( 'Get', 'InvokeMethod', $null, $NameTranslateComObject, [TranslateType]::NTAccount )

            $NTAccount.Translate( [System.Security.Principal.SecurityIdentifier] )

        # get the requested format
        } else {
    
            $NameTranslateType.InvokeMember( 'Get', 'InvokeMethod', $null, $NameTranslateComObject, $OutputType )

        }

    }

}

