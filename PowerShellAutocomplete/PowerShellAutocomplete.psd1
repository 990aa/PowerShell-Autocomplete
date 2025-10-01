@{
    RootModule = 'PowerShellAutocomplete.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'Your Name'
    CompanyName = 'Community Project'
    Copyright = '(c) 2024. All rights reserved.'
    Description = 'Intelligent autocomplete with inline suggestions for PowerShell'
    PowerShellVersion = '5.1'
    FunctionsToExport = 'Import-PowerShellAutocomplete'
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('autocomplete', 'tab-completion', 'productivity', 'powershell')
            LicenseUri = 'https://github.com/yourusername/PowerShell-Autocomplete/blob/main/LICENSE'
            ProjectUri = 'https://github.com/yourusername/PowerShell-Autocomplete'
            ReleaseNotes = 'Initial release with inline suggestions and command history learning'
        }
    }
}