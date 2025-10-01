# PowerShell Autocomplete Module
# Provides intelligent tab completion and inline suggestions

# Global variables
### --- AUTOFILL ENHANCEMENT: Custom Suggestions & Tab Navigation --- ###
$global:AutocompleteConfig = @{
    CommandDatabase = @{
        # System commands
        "cd" = @("..", "~", "Desktop", "Documents", "Downloads")
        "dir" = @("/a", "/s", "/b", "/q")
        "cls" = @()
        "clear" = @()
        
        # Common tools
        "winget" = @("install", "search", "upgrade", "list", "uninstall")
        "python" = @("--version", "script.py", "-m", "pip", "manage.py")
        "pip" = @("install", "uninstall", "freeze", "list", "show")
        "node" = @("--version", "app.js", "npm", "yarn")
        "npm" = @("install", "start", "run", "test", "build")
        "docker" = @("ps", "images", "build", "run", "stop", "logs")
        "kubectl" = @("get", "apply", "delete", "describe", "logs")
        
        # Git commands
        "git" = @("clone", "status", "add", "commit", "push", "pull", "log", "branch", "checkout")
        
        # Network commands
        "ping" = @("google.com", "8.8.8.8", "localhost")
        "ipconfig" = @("/all", "/release", "/renew")
        "curl" = @("-L", "-O", "-X", "GET", "POST")
    }
    LearnedCommands = @{}
    CustomSuggestions = @{}
    CommandHistoryFile = Join-Path $PSScriptRoot "command_history.json"
    CustomSuggestionsFile = Join-Path $PSScriptRoot "custom_suggestions.json"
    ShowInlineSuggestions = $true
    MaxHistoryEntries = 50
    SuggestionTab = 0 # 0: built-in/learned, 1: custom
}


# Inline suggestion state
$global:CurrentSuggestion = $null
$global:LastInput = $null
$global:CurrentCustomSuggestion = $null

# Check for PSReadLine
$global:PSReadLineAvailable = (Get-Module -ListAvailable -Name PSReadLine) -ne $null

function Import-PowerShellAutocomplete {
    <#
    .SYNOPSIS
        Imports the PowerShell Autocomplete module with all features.
    
    .DESCRIPTION
        This function initializes the autocomplete system with inline suggestions,
        command history learning, and enhanced tab completion.
    
    .EXAMPLE
        Import-PowerShellAutocomplete
    #>
    
    Write-Host "Loading PowerShell Autocomplete..." -ForegroundColor Green
    
    # Load command history
    Load-CommandHistory
    # Load custom suggestions
    Load-CustomSuggestions
    
    # Set up PSReadLine if available
    if ($global:PSReadLineAvailable) {
        try {
            Import-Module PSReadLine -ErrorAction SilentlyContinue
            Initialize-PSReadLine
            Write-Host "✓ PSReadLine integration enabled" -ForegroundColor Green
        }
        catch {
            Write-Warning "PSReadLine available but could not be imported: $_"
            $global:PSReadLineAvailable = $false
        }
    } else {
        Write-Host "! PSReadLine not found. Installing it will enhance the experience." -ForegroundColor Yellow
        Write-Host "  Run: Install-Module PSReadLine -Force" -ForegroundColor Cyan
    }
    
    # Register tab completion
    Register-TabCompletion
    
    # Set up prompt for inline suggestions
    Initialize-InlineSuggestions
    
    Write-Host "✓ PowerShell Autocomplete successfully loaded!" -ForegroundColor Green
    Write-Host "  - Type 'p' and see light gray suggestions" -ForegroundColor Cyan
    Write-Host "  - Press → (Right Arrow) to accept suggestions" -ForegroundColor Cyan
    Write-Host "  - Press Tab to see all options" -ForegroundColor Cyan
}

function Initialize-PSReadLine {
    <#
    .SYNOPSIS
        Sets up PSReadLine key handlers for inline suggestions.
    #>
    
    if (-not $global:PSReadLineAvailable) { return }
    
    # Right arrow to accept suggestion or switch tab
    Set-PSReadLineKeyHandler -Key RightArrow -ScriptBlock {
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        
        # If at end of line and have a suggestion, accept it
        if ($cursor -eq $line.Length) {
            if ($global:AutocompleteConfig.SuggestionTab -eq 0 -and $global:CurrentSuggestion) {
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($line.Length)
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $global:CurrentSuggestion + " ")
                $global:CurrentSuggestion = $null
                $global:LastInput = $null
            } elseif ($global:AutocompleteConfig.SuggestionTab -eq 1 -and $global:CurrentCustomSuggestion) {
                [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($line.Length)
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $global:CurrentCustomSuggestion + " ")
                $global:CurrentCustomSuggestion = $null
                $global:LastInput = $null
            } else {
                [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar()
            }
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar()
        }
    }

    # Left/Right arrow to switch suggestion tab
    Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -ScriptBlock {
        $global:AutocompleteConfig.SuggestionTab = 0
    }
    Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -ScriptBlock {
        $global:AutocompleteConfig.SuggestionTab = 1
    }
    
    # Tab for traditional completion
    Set-PSReadLineKeyHandler -Key Tab -Function Complete
}

function Initialize-InlineSuggestions {
    <#
    .SYNOPSIS
        Sets up the prompt function to show inline suggestions.
    #>
    
    # Save the original prompt if it exists
    if (Test-Path function:originalPrompt) {
        Remove-Item function:originalPrompt -Force -ErrorAction SilentlyContinue
    }
    
    if (Test-Path function:prompt) {
        Rename-Item function:prompt originalPrompt -Force
    } else {
        function global:originalPrompt {
            "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
        }
    }
    
    # Create our enhanced prompt
    function global:prompt {
        # Learn from the last command
        $lastCommand = (Get-History -Count 1).CommandLine
        if ($lastCommand -and $lastCommand -ne $global:lastLearnedCommand) {
            Learn-FromCommand $lastCommand
            $global:lastLearnedCommand = $lastCommand
        }
        
        # Show inline suggestion if enabled
        if ($global:AutocompleteConfig.ShowInlineSuggestions) {
            Show-InlineSuggestion
        }
        
        # Return original prompt
        originalPrompt
    }
}

function Show-InlineSuggestion {
    <#
    .SYNOPSIS
        Displays inline suggestions in light gray text.
    #>
    
    try {
        $currentInput = $Host.UI.RawUI.ReadLine()
        if (-not $currentInput) { return }
        $inputText = $currentInput.Trim()
        if (-not $inputText) { return }

        if ($global:AutocompleteConfig.SuggestionTab -eq 0) {
            $suggestionSuffix = Get-InlineSuggestion -currentInput $inputText
            if ($suggestionSuffix) {
                $cursorLeft = $Host.UI.RawUI.CursorPosition.X
                $cursorTop = $Host.UI.RawUI.CursorPosition.Y
                Write-Host $suggestionSuffix -NoNewline -ForegroundColor DarkGray
                $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $cursorLeft, $cursorTop
            }
        } elseif ($global:AutocompleteConfig.SuggestionTab -eq 1) {
            $customSuggestionSuffix = Get-CustomSuggestion -currentInput $inputText
            if ($customSuggestionSuffix) {
                $cursorLeft = $Host.UI.RawUI.CursorPosition.X
                $cursorTop = $Host.UI.RawUI.CursorPosition.Y
                Write-Host $customSuggestionSuffix -NoNewline -ForegroundColor Yellow
                $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $cursorLeft, $cursorTop
            }
        }
    } catch {}
function Get-CustomSuggestion {
    param([string]$currentInput)
    if ([string]::IsNullOrWhiteSpace($currentInput)) {
        $global:CurrentCustomSuggestion = $null
        return $null
    }
    $allCustoms = @($global:AutocompleteConfig.CustomSuggestions.Keys)
    $matchingCustoms = $allCustoms | Where-Object { $_ -like "$currentInput*" } | Sort-Object
    if ($matchingCustoms.Count -eq 0) {
        $global:CurrentCustomSuggestion = $null
        return $null
    }
    $bestMatch = $matchingCustoms[0]
    if ($bestMatch -eq $currentInput) {
        $global:CurrentCustomSuggestion = $null
        return $null
    }
    $global:CurrentCustomSuggestion = $bestMatch
    return $bestMatch.Substring($currentInput.Length)
}
# Command history functions
function Load-CustomSuggestions {
    $file = $global:AutocompleteConfig.CustomSuggestionsFile
    if (Test-Path $file) {
        try {
            $content = Get-Content $file -Raw | ConvertFrom-Json
            $global:AutocompleteConfig.CustomSuggestions = @{}
            $content.PSObject.Properties | ForEach-Object {
                $global:AutocompleteConfig.CustomSuggestions[$_.Name] = $_.Value
            }
        } catch {
            Write-Warning "Could not load custom suggestions: $_"
        }
    }
}

function Save-CustomSuggestions {
    try {
        $global:AutocompleteConfig.CustomSuggestions | ConvertTo-Json | Set-Content $global:AutocompleteConfig.CustomSuggestionsFile
    } catch {
        Write-Warning "Could not save custom suggestions: $_"
    }
}

# User function to add custom suggestions
function Add-CustomSuggestion {
    param(
        [Parameter(Mandatory)]
        [string]$Suggestion
    )
    if ([string]::IsNullOrWhiteSpace($Suggestion)) { return }
    if (-not $global:AutocompleteConfig.CustomSuggestions.ContainsKey($Suggestion)) {
        $global:AutocompleteConfig.CustomSuggestions[$Suggestion] = @()
        Save-CustomSuggestions
        Write-Host "Custom suggestion added: $Suggestion" -ForegroundColor Yellow
    } else {
        Write-Host "Custom suggestion already exists: $Suggestion" -ForegroundColor DarkYellow
    }
}
}

function Get-InlineSuggestion {
    param([string]$currentInput)
    
    if ([string]::IsNullOrWhiteSpace($currentInput)) {
        $global:CurrentSuggestion = $null
        return $null
    }
    
    # Get all possible commands
    $allCommands = @($global:AutocompleteConfig.CommandDatabase.Keys) + @($global:AutocompleteConfig.LearnedCommands.Keys)
    $matchingCommands = $allCommands | Where-Object { $_ -like "$currentInput*" } | Sort-Object
    
    if ($matchingCommands.Count -eq 0) {
        $global:CurrentSuggestion = $null
        return $null
    }
    
    $bestMatch = $matchingCommands[0]
    
    # Don't suggest if it's the same as input
    if ($bestMatch -eq $currentInput) {
        $global:CurrentSuggestion = $null
        return $null
    }
    
    $global:CurrentSuggestion = $bestMatch
    return $bestMatch.Substring($currentInput.Length)
}

# Command history functions
function Load-CommandHistory {
    $historyFile = $global:AutocompleteConfig.CommandHistoryFile
    if (Test-Path $historyFile) {
        try {
            $content = Get-Content $historyFile -Raw | ConvertFrom-Json
            $global:AutocompleteConfig.LearnedCommands = @{}
            $content.PSObject.Properties | ForEach-Object {
                $global:AutocompleteConfig.LearnedCommands[$_.Name] = $_.Value
            }
        }
        catch {
            Write-Warning "Could not load command history: $_"
        }
    }
}

function Save-CommandHistory {
    try {
        $global:AutocompleteConfig.LearnedCommands | ConvertTo-Json | Set-Content $global:AutocompleteConfig.CommandHistoryFile
    }
    catch {
        Write-Warning "Could not save command history: $_"
    }
}

function Learn-FromCommand {
    param([string]$FullCommand)
    
    if ([string]::IsNullOrWhiteSpace($FullCommand)) { return }
    
    $parts = $FullCommand -split '\s+' | Where-Object { $_ -and $_ -notmatch '^\s*$' }
    if ($parts.Count -eq 0) { return }
    
    $mainCommand = $parts[0]
    $fullArguments = $parts[1..($parts.Count-1)] -join ' '
    
    if (-not $mainCommand) { return }
    
    if (-not $global:AutocompleteConfig.LearnedCommands.ContainsKey($mainCommand)) {
        $global:AutocompleteConfig.LearnedCommands[$mainCommand] = @()
    }
    
    if ($fullArguments -and -not ($global:AutocompleteConfig.LearnedCommands[$mainCommand] -contains $fullArguments)) {
        $global:AutocompleteConfig.LearnedCommands[$mainCommand] = @($fullArguments) + $global:AutocompleteConfig.LearnedCommands[$mainCommand]
        
        # Trim to max entries
        if ($global:AutocompleteConfig.LearnedCommands[$mainCommand].Count -gt $global:AutocompleteConfig.MaxHistoryEntries) {
            $global:AutocompleteConfig.LearnedCommands[$mainCommand] = $global:AutocompleteConfig.LearnedCommands[$mainCommand][0..($global:AutocompleteConfig.MaxHistoryEntries-1)]
        }
        
        Save-CommandHistory
    }
}

# Tab completion functions
function Register-TabCompletion {
    $allCommands = $global:AutocompleteConfig.CommandDatabase.Keys + $global:AutocompleteConfig.LearnedCommands.Keys
    
    Register-ArgumentCompleter -CommandName $allCommands -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        
        $command = $commandAst.CommandElements[0].Value
        $currentWord = $wordToComplete
        $previousWords = @()
        
        if ($commandAst.CommandElements.Count -gt 1) {
            $previousWords = $commandAst.CommandElements[1..($commandAst.CommandElements.Count-1)] | 
                            ForEach-Object Value | 
                            Where-Object { $_ -and $_ -ne $currentWord }
        }
        
        $suggestions = Get-EnhancedSuggestions -Command $command -CurrentWord $currentWord -PreviousWords $previousWords
        
        $suggestions | ForEach-Object {
            $isLearned = $global:AutocompleteConfig.LearnedCommands[$command] -contains $_
            $toolTip = if ($isLearned) { "Previously used: $_" } else { "Suggestion: $_" }
            $listItemText = if ($isLearned) { "📚 $_" } else { "💡 $_" }
            
            [System.Management.Automation.CompletionResult]::new(
                $_, 
                $listItemText, 
                'ParameterValue', 
                $toolTip
            )
        }
    }
}

function Get-EnhancedSuggestions {
    param([string]$Command, [string]$CurrentWord, [array]$PreviousWords)
    
    $suggestions = @()
    
    # Static suggestions
    if ($global:AutocompleteConfig.CommandDatabase.ContainsKey($Command)) {
        $suggestions += $global:AutocompleteConfig.CommandDatabase[$Command] | Where-Object { 
            $_ -like "$CurrentWord*" 
        }
    }
    
    # Learned suggestions
    if ($global:AutocompleteConfig.LearnedCommands.ContainsKey($Command)) {
        $suggestions += $global:AutocompleteConfig.LearnedCommands[$Command] | Where-Object {
            $_ -like "$CurrentWord*" -and $_ -notin $suggestions
        }
    }
    
    # Context-aware filtering
    if ($PreviousWords.Count -gt 0) {
        $lastWord = $PreviousWords[-1]
        $contextualSuggestions = $suggestions | Where-Object {
            $_ -like "$lastWord *" -or $_ -like "* $lastWord*"
        }
        
        if ($contextualSuggestions.Count -gt 0) {
            $suggestions = @($contextualSuggestions) + @($suggestions | Where-Object { $_ -notin $contextualSuggestions })
        }
    }
    
    return $suggestions | Select-Object -Unique
}

# Export functions
Export-ModuleMember -Function Import-PowerShellAutocomplete,Add-CustomSuggestion

# Auto-import when module is loaded
Import-PowerShellAutocomplete