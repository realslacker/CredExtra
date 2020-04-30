<#
.SYNOPSIS
 Tests that a credential is available in the cache.

.PARAMETER UserName
 The user name to check.

#>
function Test-CredentialCached {

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $UserName,

        [System.IO.DirectoryInfo]
        $CacheFolder = ( '{0}\PowerShell\{1}\{2}' -f [environment]::GetFolderPath('LocalApplicationData'), 'brooksworks.com', 'CredExtra' )

    )

    $CredentialFile = Join-Path $CacheFolder ( '{0}.xml' -f $UserName )

    Test-Path -Path $CredentialFile

}
