<#
.SYNOPSIS
 Caches an encrypted credential file on the local disk that is tied to the current user on the current machine.

.PARAMETER Credential
 The credential to cache.

.PARAMETER UserName
 The user name to cache.

.PARAMETER Password
 The secure string password to cache.

.PARAMETER Prompt
 Prompt for the credential to store.

.PARAMETER Force
 Overwrite an existing credential.

.PARAMETER CacheFolder
 Where the credentials should be stored.

.EXAMPLE
 Add-CredentialToCache -Username DOMAIN\User

.EXAMPLE
 Add-CredentialToCache -Username user@domain.local

#>
Function Add-CredentialToCache {

    [CmdletBinding(DefaultParameterSetName='PromptForCredential', SupportsShouldProcess)]
    Param(
    
        [Parameter(ParameterSetName='UsingCredential', Mandatory=$true)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter(Position=1, ParameterSetName='UsingUserNameAndPassword', Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $UserName,

        [Parameter(ParameterSetName='UsingUserNameAndPassword')]
        [ValidateNotNull()]
        [System.Security.SecureString]
        $Password,

        [Parameter(ParameterSetName='PromptForCredential')]
        [switch]
        $Prompt,

        [switch]
        $Force,

        [System.IO.DirectoryInfo]
        $CacheFolder = $DefaultCacheFolder
        
    )

    process {

        # build the credential
        switch ( $PSCmdlet.ParameterSetName ) {

            'UsingUserNameAndPassword' {

                # prompt for password if not provided
                if ( $null -eq $Password ) {

                    $Password = Read-Host -Prompt $Messages.PasswordPrompt -AsSecureString

                }
                
                # build a credential object
                $Credential = New-Object System.Management.Automation.PSCredential( $UserName, $Password )
            
            }

            'PromptForCredential' {
            
                # prompt the user for a credential
                $Credential = Get-Credential

            }

        }

        # destination file name
        $FileName = $Credential.UserName + '.xml'

        # destination file path
        [System.IO.FileInfo]$FilePath = Join-Path $CacheFolder $FileName

        # verify any domain or machine sub-directory exists
        if ( -not(Test-Path -Path $FilePath.Directory.FullName -PathType Container) ) {
        
            New-Item -Path $FilePath.Directory -ItemType Directory -Force -Confirm:$false > $null
        
        }

        # validate output file
        #if ( $PSCmdlet.
        if ( -not($Force) -and (Test-Path -Path $FilePath) ) {

            Write-Error $Messages.CacheOverwriteError

        }

        # output credential xml
        $Credential | Export-Clixml -Path $FilePath -Force
        
    }

}
