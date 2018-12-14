# Current script path
[string]$ScriptPath = Split-Path (Get-Variable MyInvocation -Scope Script).Value.Mycommand.Definition -Parent

# load localized language
Import-LocalizedData -BindingVariable 'Messages' -FileName 'Messages' -BaseDirectory (Join-Path $ScriptPath 'lang')

# dot sourcing libs, no recursion in case you want to include lib files in sub folders
# and dot source from top level
Get-ChildItem -Path (Join-Path $ScriptPath 'lib') -Filter "*.ps1" -File |
    ForEach-Object {
    
        . $_.FullName
        
    }
 
# dot sourcing private script files
Get-ChildItem -Path (Join-Path $ScriptPath 'src\private') -Recurse -Filter "*.ps1" -File |
    ForEach-Object {
    
        . $_.FullName
        
    }
 
# dot sourcing public function files
Get-ChildItem -Path (Join-Path $ScriptPath 'src\public') -Recurse -Filter "*.ps1" -File |
    ForEach-Object {

        . $_.FullName
 
        # Find all the functions defined no deeper than the first level deep and export it.
        # This looks ugly but allows us to not keep any uneeded variables from poluting the module.
        ([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $_.FullName -Raw), [ref]$null, [ref]$null)).FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) |
            ForEach-Object {
                Export-ModuleMember $_.Name
            }
    }

# cleanup
$ExecutionContext.SessionState.Module.OnRemove = {
    # cleanup when unloading module (if any)
}