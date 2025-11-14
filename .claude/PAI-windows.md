# Install

## Claude Code
irm https://claude.ai/install.ps1 | iex

## Bun
powershell -c "irm bun.sh/install.ps1 | iex"

## Git
should be installed

## PAI
cd $Env:USERPROFILE
git clone https://github.com/danielmiessler/Personal_AI_Infrastructure.git PAI
cd PAI

Test-Path $PROFILE
> Add config to PROFILE

```
# ========== PAI Configuration ==========
# Replace C:\path\to\PAI with YOUR actual PAI installation path
$env:PAI_DIR = "C:\path\to\PAI" # Point to the PAI repository root
$env:PAI_HOME = "$env:USERPROFILE" # Your home directory
# Example paths (adjust to YOUR installation path):
# $env:PAI_DIR = "$env:USERPROFILE\Projects\PAI"
# $env:PAI_DIR = "$env:USERPROFILE\Documents\PAI"
# $env:PAI_DIR = "C:\Users\yourname\PAI"
```

### Copy environment template
Copy-Item "$env:PAI_DIR\.claude\.env.example" "$env:USERPROFILE\.claude\.env"

### Open it in Notepad
notepad "$env:USERPROFILE\.claude\.env"

### Option 1: Copy the .claude directory to your home directory
# Note: Copy the directory
Copy-Item -Path "$env:PAI_DIR\.claude" -Destination "$env:USERPROFILE\.claude" -Recurse -Force

### Option 2: Create a symbolic link if you want to keep it in the repo
# Note: This requires admin privileges in PowerShell
$source = "C:\Users\hecjex\PAI\.claude\settings.json"
$dest = "C:\Users\hecjex\.claude\settings.json"
New-Item -ItemType SymbolicLink -Path $dest -Target $source

