# turn on informational messages
$InformationPreference = 'Continue'

# load localized language
Import-LocalizedData -BindingVariable 'Messages' -FileName 'Messages' -BaseDirectory (Join-Path $ScriptPath 'lang')

# default cache folder
$DefaultCacheFolder = '{0}\PowerShell\{1}\{2}' -f [environment]::GetFolderPath('LocalApplicationData'), 'brooksworks.com', $ModuleName

# configuration parameters
# we have to add it in the loader script so that it's available to the dot sourced files
#$ConfigSplat = @{
#    Name        = $ModuleName
#    CompanyName = 'brooksworks.com'
#}

# create config variable
# we have to add it in the loader script so that it's available to the dot sourced files
#$Config = Import-Configuration @ConfigSplat
