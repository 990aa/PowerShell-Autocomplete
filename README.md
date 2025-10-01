# PowerShell Autocomplete

Intelligent autocomplete with inline suggestions for Windows Terminal and PowerShell.

## Features

- **Inline Suggestions**: See completions in light gray as you type
- **One-Click Acceptance**: Press → (Right Arrow) to accept suggestions  
- **Traditional Tab Completion**: Press Tab to see all options
- **Command History Learning**: Learns from your frequently used commands
- **Context-Aware**: Smarter suggestions based on previous words

## Quick Install

### Method 1: One-Line Install (Recommended)
```powershell
irm https://raw.githubusercontent.com/yourusername/PowerShell-Autocomplete/main/install.ps1 | iex
```

### Method 2: Manual Install
```powershell
# Clone the repository
git clone https://github.com/yourusername/PowerShell-Autocomplete.git
cd PowerShell-Autocomplete

# Run the installer
.\install.ps1
```

## Usage

1. **Type `p`** → See `ython` in light gray
2. **Press →** → `python` appears fully  
3. **Type `pi`** → Suggestion changes to `p` (for `pip`)
4. **Press → again** → `pip` appears fully
5. **Press Tab** → See all matching commands

## Manual Setup

If you prefer manual installation:

```powershell
# 1. Create module directory
$modulePath = "$HOME\Documents\PowerShell\Modules\PowerShellAutocomplete"
New-Item -ItemType Directory -Path $modulePath -Force

# 2. Download and place the .psm1 and .psd1 files in that directory

# 3. Add to your profile
Add-Content $PROFILE "`nImport-Module PowerShellAutocomplete"
```

## Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- Windows Terminal (recommended) or any PowerShell host
- PSReadLine (optional but recommended for best experience)

## Enhancing with PSReadLine

For the best experience, install PSReadLine:
```powershell
Install-Module PSReadLine -Force -Scope CurrentUser
```

## Contributing

Feel free to submit issues and pull requests!

## License

MIT License - see LICENSE file for details