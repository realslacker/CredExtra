﻿# Current script path
[string]$ScriptPath = Split-Path (Get-Variable MyInvocation -Scope Script).Value.Mycommand.Definition -Parent

# parse module name
[string]$ModuleName = (Get-Item -Path $ScriptPath).BaseName

# create build directory
$BuildNumber = Get-Date -Format yyyy.MM.dd.HHmm
$BuildDirectory = New-Item -Path "$ScriptPath\build\$BuildNumber\$ModuleName" -ItemType Directory -ErrorAction Stop

# copy source files
Copy-Item -Path $ScriptPath\CredExtra.psd1 -Destination $BuildDirectory
Copy-Item -Path $ScriptPath\lang -Destination $BuildDirectory -Recurse

# copy all lib sub-directories to module
Get-ChildItem -Path $ScriptPath\lib -Directory |
    Copy-Item -Destination { "$BuildDirectory\lib\$($_.Name)" } -Recurse

# create module file
$ModuleFile = New-Item -Path "$BuildDirectory\$ModuleName.psm1" -ItemType File

# array for exported functions
$ExportModuleMembers = @()

# add common settings
Add-Content -Path $ModuleFile -Value @'

# Current script path
[string]$ScriptPath = Split-Path (Get-Variable MyInvocation -Scope Script).Value.Mycommand.Definition -Parent

# load localized language
Import-LocalizedData -BindingVariable 'Messages' -FileName 'Messages' -BaseDirectory (Join-Path $ScriptPath 'lang')

'@

# copy all public script contents to module
Get-ChildItem -Path (Join-Path $ScriptPath 'src\public') -Recurse -Filter "*.ps1" -File |
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
Get-ChildItem -Path (Join-Path $ScriptPath 'src\private') -Recurse -Filter "*.ps1" -File |
    ForEach-Object {

        Get-Content -Path $_.FullName -Raw | Add-Content -Path $ModuleFile

    }

# copy all private script contents to module
Get-ChildItem -Path (Join-Path $ScriptPath 'lib') -Filter "*.ps1" -File |
    ForEach-Object {

        Get-Content -Path $_.FullName -Raw | Add-Content -Path $ModuleFile

    }

# update the build version
$ModuleManifestSplat = @{
    Path              = "$BuildDirectory\$ModuleName.psd1"
    ModuleVersion     = $BuildNumber
    FunctionsToExport = $ExportModuleMembers
}
Update-ModuleManifest @ModuleManifestSplat
