<#
.SYNOPSIS
 Tests a credential to make sure it is valid.

.PARAMETER Credential
 The credential to test.

.PARAMETER Domain
 Switch to indicate that the credential is a domain credential.

#>
Function Test-Credential {
    
    [CmdletBinding(DefaultParameterSetName='MachineContext')]
    Param(
    
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter(ParameterSetName='DomainContext')]
        [switch]
        $Domain

    )

    begin {

        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    
    }

    process {
    
        $UserName   = $Credential.GetNetworkCredential().UserName
        $Password   = $Credential.GetNetworkCredential().Password
        $DomainName = $Credential.GetNetworkCredential().Domain

        if ( $PSCmdlet.ParameterSetName -eq 'DomainContext' ) {

            Write-Verbose ( $Messages.ValidateUserOnDomainVerboseMessage -f $UserName, $DomainName )

            $AuthObj = New-Object System.DirectoryServices.AccountManagement.PrincipalContext( 'Domain', $DomainName )

        } elseif ( $PSCmdlet.ParameterSetName -eq 'MachineContext' -and -not( [string]::IsNullOrEmpty( $DomainName ) ) ) {
        
            Write-Verbose ( $Messages.ValidateUserOnMachineVerboseMessage -f $UserName, $Domain )
            
            $AuthObj = New-Object System.DirectoryServices.AccountManagement.PrincipalContext( 'Machine', $DomainName )

        } else {

            Write-Verbose ( $Messages.ValidateUserOnMachineVerboseMessage -f $UserName, $env:COMPUTERNAME )

            $AuthObj = New-Object System.DirectoryServices.AccountManagement.PrincipalContext( 'Machine', $env:COMPUTERNAME )

        }

        $AuthObj.ValidateCredentials( $UserName, $Password, [System.DirectoryServices.AccountManagement.ContextOptions]::Negotiate )

    }
    
}
