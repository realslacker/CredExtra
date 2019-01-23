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
        $CacheFolder = $DefaultCacheFolder

    )

    $CredentialFile = Join-Path $CacheFolder ( '{0}.xml' -f $UserName )

    Test-Path -Path $CredentialFile

}
