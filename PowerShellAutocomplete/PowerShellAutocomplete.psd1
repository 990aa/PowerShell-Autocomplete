@{
    RootModule = 'PowerShellAutocomplete.psm1'
    ModuleVersion = '1.2.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = '990aa'
    CompanyName = 'Community Project'
    Copyright = '(c) 2024. All rights reserved.'
    Description = 'Intelligent autocomplete with inline suggestions and custom autofill statements for PowerShell'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Import-PowerShellAutocomplete', 'Add-CustomSuggestion', 'Remove-CustomSuggestion', 'Get-CustomSuggestions', 'Show-CustomSuggestionsTab')
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('autocomplete', 'tab-completion', 'productivity', 'powershell', 'custom-suggestions')
            LicenseUri = 'https://github.com/990aa/PowerShell-Autocomplete/blob/main/LICENSE'
            ProjectUri = 'https://github.com/990aa/PowerShell-Autocomplete'
            ReleaseNotes = 'Added custom autofill statements with tabbed interface and Ctrl+Space activation'
        }
    }
}