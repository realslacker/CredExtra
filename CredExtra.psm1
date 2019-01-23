# module variables
$ScriptPath = Split-Path (Get-Variable MyInvocation -Scope Script).Value.Mycommand.Definition -Parent
$ModuleName = (Get-Item (Get-Variable MyInvocation -Scope Script).Value.Mycommand.Definition).BaseName

# include module header
. ( Join-Path $ScriptPath 'inc\Header.ps1' )

# dot sourcing libs, no recursion in case you want to include lib files in sub folders
# and dot source from top level
Get-ChildItem -Path ( Join-Path $ScriptPath '3rd_party' ) -Filter "*.ps1" -File |
    ForEach-Object {
    
        . $_.FullName
        
    }
 
# dot sourcing private script files
Get-ChildItem -Path ( Join-Path $ScriptPath 'functions\private' ) -Recurse -Filter "*.ps1" -File |
    ForEach-Object {
    
        . $_.FullName
        
    }
 
# dot sourcing public function files
Get-ChildItem -Path ( Join-Path $ScriptPath 'functions\public' ) -Recurse -Filter "*.ps1" -File |
    ForEach-Object {

        . $_.FullName
 
        # Find all the functions defined no deeper than the first level deep and export it.
        # This looks ugly but allows us to not keep any uneeded variables from poluting the module.
        ([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $_.FullName -Raw), [ref]$null, [ref]$null)).FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) |
            ForEach-Object {
                Export-ModuleMember $_.Name
            }
    }

# include module footer
. ( Join-Path $ScriptPath 'inc\Footer.ps1' )