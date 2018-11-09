<#
    .SYNOPSIS
        Helper function to simplify creating dynamic parameters
    
    .DESCRIPTION
        Helper function to simplify creating dynamic parameters

        Example use cases:
            Include parameters only if your environment dictates it
            Include parameters depending on the value of a user-specified parameter
            Provide tab completion and intellisense for parameters, depending on the environment

        Please keep in mind that all dynamic parameters you create will not have corresponding variables created.
           One of the examples illustrates a generic method for populating appropriate variables from dynamic parameters
           Alternatively, manually reference $PSBoundParameters for the dynamic parameter value

    .NOTES
        Credit to http://jrich523.wordpress.com/2013/05/30/powershell-simple-way-to-add-dynamic-parameters-to-advanced-function/
            Added logic to make option set optional
            Added logic to add RuntimeDefinedParameter to existing DPDictionary
            Added a little comment based help

        Credit to BM for alias and type parameters and their handling

    .PARAMETER Name
        Name of the dynamic parameter

    .PARAMETER Type
        Type for the dynamic parameter.  Default is string

    .PARAMETER Alias
        If specified, one or more aliases to assign to the dynamic parameter

    .PARAMETER ValidateSet
        If specified, set the ValidateSet attribute of this dynamic parameter

    .PARAMETER Mandatory
        If specified, set the Mandatory attribute for this dynamic parameter

    .PARAMETER ParameterSetName
        If specified, set the ParameterSet attribute for this dynamic parameter

    .PARAMETER Position
        If specified, set the Position attribute for this dynamic parameter

    .PARAMETER ValueFromPipelineByPropertyName
        If specified, set the ValueFromPipelineByPropertyName attribute for this dynamic parameter

    .PARAMETER HelpMessage
        If specified, set the HelpMessage for this dynamic parameter
    
    .PARAMETER DPDictionary
        If specified, add resulting RuntimeDefinedParameter to an existing RuntimeDefinedParameterDictionary (appropriate for multiple dynamic parameters)
        If not specified, create and return a RuntimeDefinedParameterDictionary (appropriate for a single dynamic parameter)

        See final example for illustration

    .EXAMPLE
        
        function Show-Free
        {
            [CmdletBinding()]
            Param()
            DynamicParam {
                $options = @( gwmi win32_volume | %{$_.driveletter} | sort )
                New-DynamicParam -Name Drive -ValidateSet $options -Position 0 -Mandatory
            }
            begin{
                #have to manually populate
                $drive = $PSBoundParameters.drive
            }
            process{
                $vol = gwmi win32_volume -Filter "driveletter='$drive'"
                "{0:N2}% free on {1}" -f ($vol.Capacity / $vol.FreeSpace),$drive
            }
        } #Show-Free

        Show-Free -Drive <tab>

    # This example illustrates the use of New-DynamicParam to create a single dynamic parameter
    # The Drive parameter ValidateSet populates with all available volumes on the computer for handy tab completion / intellisense

    .EXAMPLE

    # I found many cases where I needed to add more than one dynamic parameter
    # The DPDictionary parameter lets you specify an existing dictionary
    # The block of code in the Begin block loops through bound parameters and defines variables if they don't exist

        Function Test-DynPar{
            [cmdletbinding()]
            param(
                [string[]]$x = $Null
            )
            DynamicParam
            {
                #Create the RuntimeDefinedParameterDictionary
                $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
                New-DynamicParam -Name AlwaysParam -ValidateSet @( gwmi win32_volume | %{$_.driveletter} | sort ) -DPDictionary $Dictionary

                #Add dynamic parameters to $dictionary
                if($x -eq 1)
                {
                    New-DynamicParam -Name X1Param1 -ValidateSet 1,2 -mandatory -DPDictionary $Dictionary
                    New-DynamicParam -Name X1Param2 -DPDictionary $Dictionary
                    New-DynamicParam -Name X3Param3 -DPDictionary $Dictionary -Type DateTime
                }
                else
                {
                    New-DynamicParam -Name OtherParam1 -Mandatory -DPDictionary $Dictionary
                    New-DynamicParam -Name OtherParam2 -DPDictionary $Dictionary
                    New-DynamicParam -Name OtherParam3 -DPDictionary $Dictionary -Type DateTime
                }
        
                #return RuntimeDefinedParameterDictionary
                $Dictionary
            }
            Begin
            {
                #This standard block of code loops through bound parameters...
                #If no corresponding variable exists, one is created
                    #Get common parameters, pick out bound parameters not in that set
                    Function _temp { [cmdletbinding()] param() }
                    $BoundKeys = $PSBoundParameters.keys | Where-Object { (get-command _temp | select -ExpandProperty parameters).Keys -notcontains $_}
                    foreach($param in $BoundKeys)
                    {
                        if (-not ( Get-Variable -name $param -scope 0 -ErrorAction SilentlyContinue ) )
                        {
                            New-Variable -Name $Param -Value $PSBoundParameters.$param
                            Write-Verbose "Adding variable for dynamic parameter '$param' with value '$($PSBoundParameters.$param)'"
                        }
                    }

                #Appropriate variables should now be defined and accessible
                    Get-Variable -scope 0
            }
        }

    # This example illustrates the creation of many dynamic parameters using New-DynamicParam
        # You must create a RuntimeDefinedParameterDictionary object ($dictionary here)
        # To each New-DynamicParam call, add the -DPDictionary parameter pointing to this RuntimeDefinedParameterDictionary
        # At the end of the DynamicParam block, return the RuntimeDefinedParameterDictionary
        # Initialize all bound parameters using the provided block or similar code

    .FUNCTIONALITY
        PowerShell Language

#>
Function New-DynamicParam {
    param(
    
        [string]
        $Name,
    
        [System.Type]
        $Type = [string],

        [string[]]
        $Alias = @(),

        [string[]]
        $ValidateSet,
    
        [switch]
        $Mandatory,
    
        [string]
        $ParameterSetName="__AllParameterSets",
    
        [int]
        $Position,
    
        [switch]
        $ValueFromPipelineByPropertyName,
    
        [string]
        $HelpMessage,

        [validatescript({
            if(-not ( $_ -is [System.Management.Automation.RuntimeDefinedParameterDictionary] -or -not $_) )
            {
                Throw "DPDictionary must be a System.Management.Automation.RuntimeDefinedParameterDictionary object, or not exist"
            }
            $true
        })]
        $DPDictionary = $false
 
    )

    #Create attribute object, add attributes, add to collection   
    $ParamAttr = New-Object System.Management.Automation.ParameterAttribute
    $ParamAttr.ParameterSetName = $ParameterSetName
    if($mandatory)
    {
        $ParamAttr.Mandatory = $true
    }
    if($Position -ne $null)
    {
        $ParamAttr.Position=$Position
    }
    if($ValueFromPipelineByPropertyName)
    {
        $ParamAttr.ValueFromPipelineByPropertyName = $true
    }
    if($HelpMessage)
    {
        $ParamAttr.HelpMessage = $HelpMessage
    }
 
    $AttributeCollection = New-Object 'Collections.ObjectModel.Collection[System.Attribute]'
    $AttributeCollection.Add($ParamAttr)
    
    #param validation set if specified
    if($ValidateSet)
    {
        $ParamOptions = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $ValidateSet
        $AttributeCollection.Add($ParamOptions)
    }

    #Aliases if specified
    if($Alias.count -gt 0) {
        $ParamAlias = New-Object System.Management.Automation.AliasAttribute -ArgumentList $Alias
        $AttributeCollection.Add($ParamAlias)
    }

 
    #Create the dynamic parameter
    $Parameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList @($Name, $Type, $AttributeCollection)
    
    #Add the dynamic parameter to an existing dynamic parameter dictionary, or create the dictionary and add it
    if($DPDictionary)
    {
        $DPDictionary.Add($Name, $Parameter)
    }
    else
    {
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $Dictionary.Add($Name, $Parameter)
        $Dictionary
    }
}


<#
.SYNOPSIS
    Add a credential to a local cache.

.DESCRIPTION
    Caches an encrypted credential file on the local disk that is tied to the current user on the current machine.

.PARAMETER Credential
    The credential to cache.

.PARAMETER UserName
    The user name to cache.

.PARAMETER Password
    The secure string password to cache.

.PARAMETER Prompt
    Prompt for the credential to store.

.PARAMETER Force
    Overwrite an existing credential.

.PARAMETER CacheFolder
    Where the credentials should be stored.

.EXAMPLE
    Add-CredentialToCache -Username DOMAIN\User

.EXAMPLE
    Add-CredentialToCache -Username user@domain.local

#>
Function Add-CredentialToCache {

    [CmdletBinding(DefaultParameterSetName='PromptForCredential')]
    Param(
    
        [Parameter(ParameterSetName='UsingCredential', Mandatory=$true)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter(ParameterSetName='UsingUserNameAndPassword', Mandatory=$true)]
        [ValidateNotNull()]
        [string]
        $UserName,

        [Parameter(ParameterSetName='UsingUserNameAndPassword')]
        [ValidateNotNull()]
        [System.Security.SecureString]
        $Password,

        [Parameter(ParameterSetName='PromptForCredential')]
        [switch]
        $Prompt,

        [switch]
        $Force,

        [System.IO.DirectoryInfo]
        $CacheFolder = "$([environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\CredentialCache\$env:COMPUTERNAME"
        
    )

    process {

        # build the credential
        switch ( $PSCmdlet.ParameterSetName ) {

            'UsingUserNameAndPassword' {

                # prompt for password if not provided
                if ( $null -eq $Password ) {

                    $Password = Read-Host -Prompt 'Enter Password' -AsSecureString

                }
                
                # build a credential object
                $Credential = New-Object System.Management.Automation.PSCredential( $UserName, $Password )
            
            }

            'PromptForCredential' {
            
                # prompt the user for a credential
                $Credential = Get-Credential

            }

        }

        # destination file name
        $FileName = $Credential.GetNetworkCredential().Domain + '\' + $Credential.GetNetworkCredential().UserName + '.xml'

        # destination file path
        [System.IO.FileInfo]$FilePath = Join-Path $CacheFolder $FileName

        # verify any domain or machine sub-directory exists
        if ( -not(Test-Path -Path $FilePath.Directory.FullName -PathType Container) ) {
        
            New-Item -Path $FilePath.Directory -ItemType Directory -Force -Confirm:$false > $null
        
        }

        # validate output file
        if ( -not($Force) -and (Test-Path -Path $FilePath) ) {

            Write-Error "Cached credentials exist, use -Force to replace."

        }

        # output credential xml
        $Credential | Export-Clixml -Path $FilePath -Force
        
    }

}

<#
.SYNOPSIS
    Retrieve a credential from a local cache.
.DESCRIPTION
    Takes a username to retrieve the credential for.
    Optionally takes a Path to the credential cache.
.PARAMETER Username
    The username to cache the credential for.
.PARAMETER Path
    Where to save the credential.
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

        $CacheFolder = Get-Item "$([environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\CredentialCache\$env:COMPUTERNAME" -ErrorAction Stop

        $CacheFolderRegex = [regex]::Escape($CacheFolder.FullName)

        $PasswordFiles = (Get-ChildItem -Path $CacheFolder -Filter *.xml -Recurse).FullName -replace "^$CacheFolderRegex\\(.*)\.xml$", '$1'

        $DPDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        $UserNameParam = @{
            Name             = 'UserName'
            ParameterSetName = 'ByUserName'
            ValidateSet      = $PasswordFiles
            Position         = 1
            DPDictionary     = $DPDictionary
        }
        New-DynamicParam @UserNameParam

        $PathParam = @{
            Name             = 'Path'
            ParameterSetName = 'ByPath'
            Position         = 1
            Type             = [System.IO.FileInfo]
            DPDictionary     = $DPDictionary
        }
        New-DynamicParam @PathParam

        $DPDictionary

    }
    
    process {

        # build the actual path to the credential file
        switch ($PSCmdlet.ParameterSetName ) {
            
            'ByPath' {
            
                $FilePath = $PSBoundParameters.Path
            
            }

            'ByUserName' {
            
                $FilePath = "$([environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\CredentialCache\$env:COMPUTERNAME\$($PSBoundParameters.UserName).xml"
            
            }
        
        }

        # if there is no cached credential we throw an error
        if ( -not (Test-Path -Path $FilePath -PathType Leaf ) ) {

            Write-Error "Password is not cached."

        }

        # return the credential
        Import-Clixml -Path $FilePath

    }

}

<#
.SYNOPSIS
    Creates a credential from a plaintext string.
.PARAMETER Username
    The username to create the credential from.
.PARAMETER Password
    The plaintext password to create the credential from.
.OUTPUTS
    Returns a credential object.
.EXAMPLE
    $cred = Get-CredentialFromPlaintext -Username DOMAIN\User -Password "P@ssword"
.EXAMPLE
    $cred = Get-CredentialToCache -Username user@domain.local -Password "P@ssword"
#>
Function Get-CredentialFromPlaintext {

    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
        [Alias('User','Email','sAMAccountName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $UserName,

        [Parameter(Mandatory=$true, Position=2, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        $Password
        
    )

    process {

        $Password = $Password | ConvertTo-SecureString -AsPlainText -Force
    
        New-Object System.Management.Automation.PSCredential($UserName, $Password)

    }

}

<#
.SYNOPSIS
    Tests a credential to make sure it is valid.

.DESCRIPTION
    Tests a credential to make sure it is valid.

.PARAMETER Credential
    The credential to test.

.PARAMETER Domain
    Switch to indicate that the credential is a domain credential.

#>
Function Test-Credential {
    
    [CmdletBinding(DefaultParameterSetName='MachineContext')]
    Param(
    
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter(ParameterSetName='DomainContext')]
        [switch]
        $Domain

    )

    begin {

        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    
    }

    process {
    
        $UserName   = $Credential.GetNetworkCredential().UserName
        $Password   = $Credential.GetNetworkCredential().Password
        $DomainName = $Credential.GetNetworkCredential().Domain

        if ( $PSCmdlet.ParameterSetName -eq 'DomainContext' ) {

            Write-Verbose "Validating credential for '$UserName' in domain '$DomainName'..."

            $AuthObj = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('Domain', $DomainName)

        } elseif ( $PSCmdlet.ParameterSetName -eq 'MachineContext' -and -not([string]::IsNullOrEmpty($DomainName)) ) {
        
            Write-Verbose "Validating credential for '$UserName' on machine '$DomainName'..."
            
            $AuthObj = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('Machine', $DomainName)

        } else {

            Write-Verbose "Validating credential for '$UserName' on machine '$env:COMPUTERNAME'..."

            $AuthObj = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('Machine', $env:COMPUTERNAME)

        }

        $AuthObj.ValidateCredentials($UserName, $Password)

    }
    
}
