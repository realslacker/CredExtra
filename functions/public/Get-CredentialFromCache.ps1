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

    [CmdletBinding(DefaultParameterSetName='ByUserName')]
    Param()

    dynamicparam {

        $CacheFolderRegex = [regex]::Escape($DefaultCacheFolder)

        $PasswordFiles = (Get-ChildItem -Path $DefaultCacheFolder -Filter *.xml -Recurse).FullName -replace "^$CacheFolderRegex\\(.*)\.xml$", '$1'

        $DPDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        $UserNameParam = @{
            Name                = 'UserName'
            ParameterSetName    = 'ByUserName'
            ValidateSet         = $PasswordFiles
            Position            = 1
            DPDictionary        = $DPDictionary
        }
        New-DynamicParam @UserNameParam

        $PathParam = @{
            Name                = 'Path'
            ParameterSetName    = 'ByPath'
            Position            = 1
            Type                = [System.IO.FileInfo]
            DPDictionary        = $DPDictionary
        }
        New-DynamicParam @PathParam

        $FilterParam = @{
            Name                = 'Filter'
            ParameterSetName    = 'ByFilter'
            Position            = 1
            DPDictionary        = $DPDictionary
        }
        New-DynamicParam @FilterParam

        <#$UpnSuffixParam = @{
            Name                = 'UpnSuffix'
            Position            = 2
            Type                = [string]
            DPDictionary        = $DPDictionary
        }#>

        $ExcludeDomainParam = @{
            Name                = 'ExcludeDomain'
            Position            = 3
            Type                = [switch]
            DPDictionary        = $DPDictionary
        }
        New-DynamicParam @ExcludeDomainParam

        $ListParam = @{
            Name                = 'List'
            ParameterSetName    = 'List'
            Position            = 4
            Type                = [switch]
            DPDictionary        = $DPDictionary
        }
        New-DynamicParameter @ListParam

        $DPDictionary

    }
    
    process {

        # build the actual path to the credential file
        switch ($PSCmdlet.ParameterSetName ) {
            
            'ByPath' {
            
                $FilePath = $PSBoundParameters.Path
            
            }

            'ByUserName' {
            
                $FilePath = Join-Path $DefaultCacheFolder ( '{0}.xml' -f $PSBoundParameters.UserName )
            
            }

            'ByFilter' {
            
                $FilePath = (Get-ChildItem -Path $DefaultCacheFolder -Filter *.xml -Recurse).FullName -like ( Join-Path $DefaultCacheFolder ( '{0}.xml' -f $PSBoundParameters.Filter ) )
            
            }

            'List' {

                $CacheFolderRegex = [regex]::Escape($DefaultCacheFolder)

                $PasswordFiles = (Get-ChildItem -Path $DefaultCacheFolder -Filter *.xml -Recurse).FullName -replace "^$CacheFolderRegex\\(.*)\.xml$", '$1'

                return $PasswordFiles

            }
        
        }

        foreach ( $FilePathItem in $FilePath ) {

            # if there is no cached credential we throw an error
            if ( -not (Test-Path -Path $FilePathItem -PathType Leaf ) ) {

                Write-Error $Messages.CacheMissError

            }

            # fetch the credential object
            $CacheCredential = Import-Clixml -Path $FilePathItem

            # if the -ExcludeDomain param is included we rebuild the credential without the domain
            if ( $PSBoundParameters.ExcludeDomain ) {
            
                New-Object System.Management.Automation.PSCredential($CacheCredential.GetNetworkCredential().UserName, $CacheCredential.Password)

            # otherwise we return the cached credential
            } else {
            
                $CacheCredential
            
            }

        }

    }

}
