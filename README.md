# PowerShell Autocomplete

Intelligent autocomplete with inline suggestions and custom autofill statements for Windows Terminal and PowerShell.

**Created by 990aa**

## Features

- **Inline Suggestions**: See completions in light gray as you type
- **One-Click Acceptance**: Press → (Right Arrow) to accept suggestions  
- **Traditional Tab Completion**: Press Tab to see all options
- **Custom Autofill Statements**: Define your own frequently used commands
- **Tabbed Interface**: Press Ctrl+Space for a beautiful tabbed suggestion interface
- **Command History Learning**: Learns from your frequently used commands
- **Context-Aware**: Smarter suggestions based on previous words

## Quick Install

### Method 1: One-Line Install (Recommended)
```powershell
irm https://raw.githubusercontent.com/990aa/PowerShell-Autocomplete/main/install.ps1 | iex
```

### Method 2: Manual Install
```powershell
# Clone the repository
git clone https://github.com/990aa/PowerShell-Autocomplete.git
cd PowerShell-Autocomplete

# Run the installer
.\install.ps1
```

## Usage

### Basic Autocomplete
1. **Type `p`** → See `ython` in light gray
2. **Press →** → `python` appears fully  
3. **Type `pi`** → Suggestion changes to `p` (for `pip`)
4. **Press → again** → `pip` appears fully
5. **Press Tab** → See all matching commands

### Custom Autofill Statements
1. **Press Ctrl+Space** → Open custom suggestions tab
2. **Use ↑↓ arrows** → Navigate through suggestions
3. **Press Enter** → Insert selected suggestion
4. **Press Esc** → Close without selecting

### Managing Custom Suggestions
```powershell
# Add a custom suggestion
Add-CustomSuggestion -Name "Docker Compose" -Value "docker-compose up -d"

# Remove a custom suggestion  
Remove-CustomSuggestion -Name "Docker Compose"

# List all custom suggestions
Get-CustomSuggestions
```

## Default Custom Suggestions

The module comes with these useful defaults:
- `Git Status` → `git status`
- `Git Commit All` → `git commit -am "`
- `Docker PS` → `docker ps`
- `Docker Compose Up` → `docker-compose up -d`
- `Python HTTP Server` → `python -m http.server 8000`
- `List Directory Details` → `dir /a`
- `Current Path` → `cd $PWD`
- `Home Directory` → `cd ~`

## Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- Windows Terminal (recommended) or any PowerShell host
- .NET Framework 4.6.2+ (for TabInterface)
- PSReadLine (optional but recommended for best experience)

## Enhancing with PSReadLine

For the best experience, install PSReadLine:
```powershell
Install-Module PSReadLine -Force -Scope CurrentUser
```

## Manual Setup

If you prefer manual installation:

```powershell
# 1. Create module directory
$modulePath = "$HOME\Documents\PowerShell\Modules\PowerShellAutocomplete"
New-Item -ItemType Directory -Path $modulePath -Force

# 2. Download all files from GitHub and place in the directory

# 3. Add to your profile
Add-Content $PROFILE "`nImport-Module PowerShellAutocomplete"
```

## Building from Source

The TabInterface is built automatically during installation. To manually build:

```powershell
cd TabInterface
.\build.bat
```

## Contributing

Feel free to submit issues and pull requests!

## License

MIT License - see LICENSE file for details