<#
.SYNOPSIS
 Retrieve a credential from a local cache.

.PARAMETER Username
 The username to retrieve the credential for.

.PARAMETER Path
 Where to get the credential.

.PARAMETER UpnSuffix
 Replaces the UPN suffix portion with the specified UPN suffix.

.PARAMETER Domain
 Replaces the domain portion with the specified domain.

.PARAMETER ExcludeDomain
 Return a credential object that excludes the domain portion of the credential.

.OUTPUTS
 Returns a credential object.

.EXAMPLE
 Get-CredentialToCache -Username DOMAIN\User

.EXAMPLE
 Get-CredentialToCache -Username user@domain.local

#>
function Get-CredentialFromCache {

    [CmdletBinding( DefaultParameterSetName='ByUserName' )]
    Param(

        [Parameter( Mandatory, Position=1, ParameterSetName='ByUserName' )]
        [ArgumentCompleter({

            param( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters )

            $CacheFolder = CredExtra\Get-CredentialCachePath
            $CacheFolderRegex = [regex]::Escape( $CacheFolder )

            Get-ChildItem -Path $CacheFolder -Filter '*.xml' -Recurse |
                ForEach-Object { $_.FullName -replace "^$CacheFolderRegex\\(.*)\.xml$", '$1' } |
                Where-Object { $_ -like "$WordToComplete*" }
        
        })]
        [SupportsWildcards()]
        [Alias('Filter')]
        [string]
        $UserName,

        [Parameter( Mandatory, Position=1, ParameterSetName='ByPath' )]
        [System.IO.FileInfo]
        $Path,

        [switch]
        $ExcludeDomain,

        [Parameter( Mandatory, ParameterSetName='List' )]
        [switch]
        $List,

        [TranslateType]
        $OutputType,

        [TranslateContext]
        $Context = 'GlobalCatalog',

        [System.IO.DirectoryInfo]
        $CacheFolder = (Get-CredentialCachePath)
    )

    process {

        $CacheFolderRegex = [regex]::Escape( $CacheFolder )

        # build the actual path to the credential file
        switch ($PSCmdlet.ParameterSetName ) {
            
            'ByPath' {
            
                $FilePath = $PSBoundParameters.Path
            
            }

            'ByUserName' {

                $FilePath = Get-ChildItem -Path $CacheFolder -Filter '*.xml' -Recurse |
                    Where-Object { ( $_.FullName -replace "^$CacheFolderRegex\\(.*)\.xml$", '$1' ) -like "$UserName" } |
                    Select-Object -ExpandProperty FullName
            
            }

            'List' {

                Get-ChildItem -Path $CacheFolder -Filter '*.xml' -Recurse |
                    ForEach-Object { $_.FullName -replace "^$CacheFolderRegex\\(.*)\.xml$", '$1' }

                return

            }
        
        }

        foreach ( $FilePathItem in $FilePath ) {

            # if there is no cached credential we throw an error
            if ( -not (Test-Path -Path $FilePathItem -PathType Leaf ) ) {

                Write-Error $Messages.CacheMissError

            }

            # fetch the credential object
            $CacheCredential = Import-Clixml -Path $FilePathItem

            # if the -OutputType is specified we translate the username and return
            if ( $OutputType ) {

                $TranslatedUserName = Convert-UserNameFormat -UserName $CacheCredential.UserName -OutputType $OutputType -Context $Context

                New-Object System.Management.Automation.PSCredential( $TranslatedUserName, $CacheCredential.Password )

            # if the -ExcludeDomain param is included we rebuild the credential without the domain
            } elseif ( $PSBoundParameters.ExcludeDomain ) {
            
                New-Object System.Management.Automation.PSCredential($CacheCredential.GetNetworkCredential().UserName, $CacheCredential.Password)

            # otherwise we return the cached credential as-is
            } else {
            
                $CacheCredential
            
            }

        }

    }

}
