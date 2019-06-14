param([switch]$Publish)

# module variables
$ScriptPath = Split-Path (Get-Variable MyInvocation -Scope Script).Value.Mycommand.Definition -Parent
$ModuleName = (Get-Item $ScriptPath).BaseName

# create build directory
$BuildNumber = Get-Date -Format yyyy.MM.dd.HHmm
$BuildDirectory = New-Item -Path "$ScriptPath\build\$BuildNumber\$ModuleName" -ItemType Directory -ErrorAction Stop

# copy needed files
@(
    '{0}.psd1' -f $ModuleName
    'DefaultConfig.psd1'
) | ForEach-Object { Get-Item -Path ( Join-Path $ScriptPath $_ ) -ErrorAction SilentlyContinue } | Copy-Item -Destination $BuildDirectory

# copy needed directories
@(
    'lang'
    'lib'
    'tests'
) | ForEach-Object { Get-Item -Path ( Join-Path $ScriptPath $_ ) } | Copy-Item -Destination $BuildDirectory -Recurse

# copy all lib sub-directories to module
Get-ChildItem -Path "$ScriptPath\3rd_party" -Directory |
    Copy-Item -Destination { "$BuildDirectory\3rd_party\$($_.Name)" } -Recurse

# create module file
$ModuleFile = New-Item -Path "$BuildDirectory\$ModuleName.psm1" -ItemType File

# array for exported functions
$ExportModuleMembers = @()

# add common settings
Add-Content -Path $ModuleFile -Value @'
# module variables
$ScriptPath = Split-Path (Get-Variable MyInvocation -Scope Script).Value.Mycommand.Definition -Parent
$ModuleName = (Get-Item (Get-Variable MyInvocation -Scope Script).Value.Mycommand.Definition).BaseName
'@

# include the module header
Get-Content -Path ( Join-Path $ScriptPath 'inc\Header.ps1' ) | Add-Content -Path $ModuleFile

# copy all public script contents to module
Get-ChildItem -Path ( Join-Path $ScriptPath 'functions\public' ) -Recurse -Filter "*.ps1" -File |
    ForEach-Object {

        Get-Content -Path $_.FullName -Raw | Add-Content -Path $ModuleFile
        
        # Find all the functions defined no deeper than the first level deep and export it.
        # This looks ugly but allows us to not keep any uneeded variables from poluting the module.
        ([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $_.FullName -Raw), [ref]$null, [ref]$null)).FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) |
            ForEach-Object {
                $ExportModuleMembers += @( $_.Name )
            }
    }

# copy all private script contents to module
Get-ChildItem -Path ( Join-Path $ScriptPath 'functions\private' ) -Recurse -Filter "*.ps1" -File |
    ForEach-Object {

        Get-Content -Path $_.FullName -Raw | Add-Content -Path $ModuleFile

    }

# copy all private script contents to module
Get-ChildItem -Path ( Join-Path $ScriptPath '3rd_party' ) -Filter "*.ps1" -File |
    ForEach-Object {

        Get-Content -Path $_.FullName -Raw | Add-Content -Path $ModuleFile

    }

# include the module footer
Get-Content -Path ( Join-Path $ScriptPath 'inc\Footer.ps1' ) | Add-Content -Path $ModuleFile

# update the build version
$ModuleManifestSplat = @{
    Path              = "$BuildDirectory\$ModuleName.psd1"
    ModuleVersion     = $BuildNumber
    FunctionsToExport = $ExportModuleMembers
}
Update-ModuleManifest @ModuleManifestSplat

# publish
if ( $Publish ) {

    Publish-Module -Path "$BuildDirectory"

}
