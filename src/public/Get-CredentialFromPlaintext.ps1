<#
.SYNOPSIS
    Creates a credential from a plaintext string.
.PARAMETER Username
    The username to create the credential from.
.PARAMETER Password
    The plaintext password to create the credential from.
.OUTPUTS
    Returns a credential object.
.EXAMPLE
    $cred = Get-CredentialFromPlaintext -Username DOMAIN\User -Password "P@ssword"
.EXAMPLE
    $cred = Get-CredentialToCache -Username user@domain.local -Password "P@ssword"
#>
Function Get-CredentialFromPlaintext {

    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
        [Alias('User','Email','sAMAccountName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $UserName,

        [Parameter(Mandatory=$true, Position=2, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        $Password
        
    )

    process {

        $Password = $Password | ConvertTo-SecureString -AsPlainText -Force
    
        New-Object System.Management.Automation.PSCredential($UserName, $Password)

    }

}
