function Get-CredentialCachePath {

    '{0}\PowerShell\{1}\{2}' -f [environment]::GetFolderPath('LocalApplicationData'), 'brooksworks.com', $ModuleName
    
}