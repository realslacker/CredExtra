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
        $CacheFolder = "$([environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\CredentialCache\$env:COMPUTERNAME"

    )

    $CredentialFile = Join-Path $CacheFolder "$UserName.xml"

    Test-Path -Path $CredentialFile

}
