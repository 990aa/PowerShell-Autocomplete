<#
.SYNOPSIS
    Installation script for PowerShell Autocomplete module

.DESCRIPTION
    This script installs the PowerShell Autocomplete module from GitHub
    and sets it up to load automatically in all PowerShell sessions.

.EXAMPLE
    .\install.ps1
#>

param(
    [switch]$Force
)

Write-Host "=== PowerShell Autocomplete Installer ===" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# Determine install scope
if ($isAdmin) {
    $installScope = "AllUsers"
    $modulePath = $env:ProgramFiles + "\PowerShell\Modules"
} else {
    $installScope = "CurrentUser"
    $modulePath = Join-Path $HOME "Documents\PowerShell\Modules"
}

Write-Host "Installation Scope: $installScope" -ForegroundColor Yellow
if (-not $isAdmin) {
    Write-Host "Run as Administrator to install for all users" -ForegroundColor Cyan
}

# Create module directory
$moduleName = "PowerShellAutocomplete"
$targetPath = Join-Path $modulePath $moduleName

if (Test-Path $targetPath) {
    if ($Force) {
        Write-Host "Removing existing module..." -ForegroundColor Yellow
        Remove-Item $targetPath -Recurse -Force
    } else {
        Write-Host "Module already exists at: $targetPath" -ForegroundColor Red
        Write-Host "Use -Force to overwrite or manually remove the folder" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "Creating module directory..." -ForegroundColor Green
New-Item -ItemType Directory -Path $targetPath -Force | Out-Null

# Copy module files
Write-Host "Copying module files..." -ForegroundColor Green
$files = @(
    "PowerShellAutocomplete.psd1",
    "PowerShellAutocomplete.psm1"
)

foreach ($file in $files) {
    $sourceFile = Join-Path $PSScriptRoot $file
    if (Test-Path $sourceFile) {
        Copy-Item $sourceFile $targetPath
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (not found)" -ForegroundColor Red
    }
}

# Check for PSReadLine
Write-Host "`nChecking dependencies..." -ForegroundColor Cyan
if (Get-Module -ListAvailable -Name PSReadLine) {
    Write-Host "  ✓ PSReadLine is available" -ForegroundColor Green
} else {
    Write-Host "  ! PSReadLine not found - installing will enhance experience" -ForegroundColor Yellow
    Write-Host "    Run: Install-Module PSReadLine -Force -Scope $installScope" -ForegroundColor Cyan
}

# Add to PowerShell profile
$profileFile = $PROFILE
if (-not (Test-Path $profileFile)) {
    Write-Host "Creating PowerShell profile..." -ForegroundColor Green
    New-Item -ItemType File -Path $profileFile -Force | Out-Null
}

$importCommand = "Import-Module PowerShellAutocomplete"

$profileContent = Get-Content $profileFile -ErrorAction SilentlyContinue
if ($profileContent -notcontains $importCommand) {
    Write-Host "Adding to PowerShell profile..." -ForegroundColor Green
    Add-Content -Path $profileFile -Value "`n# PowerShell Autocomplete Module`n$importCommand"
} else {
    Write-Host "Module already in PowerShell profile" -ForegroundColor Yellow
}

Write-Host "`n=== Installation Complete! ===" -ForegroundColor Cyan
Write-Host "The module will load automatically in new PowerShell sessions." -ForegroundColor Green
Write-Host "`nTo use it immediately in this session, run:" -ForegroundColor Yellow
Write-Host "  Import-Module PowerShellAutocomplete" -ForegroundColor White
Write-Host "`nFeatures:" -ForegroundColor Cyan
Write-Host "  • Inline suggestions (light gray text)" -ForegroundColor White
Write-Host "  • Press → to accept suggestions" -ForegroundColor White
Write-Host "  • Press Tab for all options" -ForegroundColor White
Write-Host "  • Learns from your command history" -ForegroundColor White