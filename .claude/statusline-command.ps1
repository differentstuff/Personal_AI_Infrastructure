# PAI Statusline for Windows PowerShell 7

$CURRENCY = "$"

# Get Digital Assistant configuration from environment
$DA_NAME = if ($env:DA) { $env:DA } else { "Assistant" } # Assistant name
$DA_COLOR = if ($env:DA_COLOR) { $env:DA_COLOR } else { "purple" } # Color for the assistant name

# Extract data from JSON input
$json = $input | ConvertFrom-Json
$model_name = $json.model.display_name
$current_dir = $json.workspace.current_dir
if (-not $current_dir) {$current_dir = $pwd}

# Get directory name
$dir_name = Split-Path -Leaf $current_dir

# Cache file and lock file for ccusage data
$CACHE_FILE = "$env:TEMP\.claude_ccusage_cache"
$LOCK_FILE = "$env:TEMP\.claude_ccusage.lock"
$CACHE_AGE = 30 # 30 seconds for more real-time updates

# Count items from specified directories
$claude_dir = if ($env:PAI_DIR) { "$env:PAI_DIR" } else { "$env:USERPROFILE\.claude" }
$commands_count = 0
$mcps_count = 0
$fobs_count = 0
$fabric_count = 0

# Count commands (optimized)
if (Test-Path "$claude_dir\commands") {
    $commands_count = (Get-ChildItem "$claude_dir\commands\*.md" -ErrorAction SilentlyContinue).Count
}

# Count MCPs from .mcp.json (single parse)
$mcp_names_raw = ""
if (Test-Path "$claude_dir\.mcp.json") {
    $mcp_data = Get-Content "$claude_dir\.mcp.json" -Raw | ConvertFrom-Json
    $mcp_names_raw = $mcp_data.mcpServers.PSObject.Properties.Name -join " "
    $mcps_count = @($mcp_data.mcpServers.PSObject.Properties).Count
} else {
    $mcps_count = 0
}

# Count Services (optimized)
$services_dir = "$env:USERPROFILE\Projects\FoundryServices\Services"
if (Test-Path $services_dir) {
    $fobs_count = (Get-ChildItem "$services_dir\*.md" -ErrorAction SilentlyContinue).Count
}

# Count Fabric patterns (optimized)
$fabric_patterns_dir = "$claude_dir\skills\fabric\fabric-repo\patterns"
if (-not (Test-Path $fabric_patterns_dir)) {
    $fabric_patterns_dir = "$env:USERPROFILE\.config\fabric\patterns"
}
if (Test-Path $fabric_patterns_dir) {
    # Count immediate subdirectories only
    $fabric_count = (Get-ChildItem $fabric_patterns_dir -Directory -ErrorAction SilentlyContinue).Count
}

# Get cached ccusage data - SAFE VERSION without background processes
$daily_tokens = ""
$daily_cost = ""

# Check if cache exists and load it
if (Test-Path $CACHE_FILE) {
    # Always load cache data first (if it exists)
    . $CACHE_FILE | Out-Null
}

# If cache is stale, missing, or we have no data, update it SYNCHRONOUSLY with timeout
$cache_needs_update = $false
if (-not (Test-Path $CACHE_FILE) -or [string]::IsNullOrEmpty($daily_tokens)) {
    $cache_needs_update = $true
} elseif (Test-Path $CACHE_FILE) {
    $cache_age = (Get-Date) - (Get-Item $CACHE_FILE).LastWriteTime
    if ($cache_age.TotalSeconds -ge $CACHE_AGE) {
        $cache_needs_update = $true
    }
}

if ($cache_needs_update) {
    # Try to acquire lock (non-blocking)
    if (-not (Test-Path $LOCK_FILE)) {
        try {
            New-Item -Path $LOCK_FILE -ItemType Directory -ErrorAction Stop | Out-Null
            
            # We got the lock - update cache with timeout
            if (Get-Command bunx -ErrorAction SilentlyContinue) {
                # Run ccusage with a timeout (5 seconds for faster updates)
                try {
                    $ccusage_json = bunx ccusage --json 2>$null | ConvertFrom-Json

                    if ($ccusage_json -and $ccusage_json.daily) {
                        # Get today's usage from the daily array
                        $today_data = $ccusage_json.daily[0]

                        if ($today_data) {
                            $daily_tokens = "{0:N0}" -f $today_data.totalTokens
                            $daily_cost = $CURRENCY + ("{0:N2}" -f $today_data.totalCost)

                            # Write to cache file
                            "daily_tokens=`"$daily_tokens`"" | Out-File -FilePath $CACHE_FILE -Encoding utf8
                            "daily_cost=`"$daily_cost`"" | Out-File -FilePath $CACHE_FILE -Encoding utf8 -Append
                            "cache_updated=`"$(Get-Date)`"" | Out-File -FilePath $CACHE_FILE -Encoding utf8 -Append
                        }
                    }
                } catch {
                    # Handle timeout or other errors
                    Write-Verbose "Error running ccusage: $_"
                }
            }
        } catch {
            # Lock creation failed
        } finally {
            # Always remove lock when done
            if (Test-Path $LOCK_FILE) {
                Remove-Item -Path $LOCK_FILE -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    } else {
        # Someone else is updating - check if lock is stale (older than 30 seconds)
        $lock_age = (Get-Date) - (Get-Item $LOCK_FILE).LastWriteTime
        if ($lock_age.TotalSeconds -gt 30) {
            # Stale lock - remove it
            Remove-Item -Path $LOCK_FILE -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Just use cached data if available
        if (Test-Path $CACHE_FILE) {
            . $CACHE_FILE | Out-Null
        }
    }
}

# Tokyo Night Storm Color Scheme (PowerShell ANSI escape codes)
$BACKGROUND = "$([char]27)[48;2;36;40;59m"
$BRIGHT_PURPLE = "$([char]27)[38;2;187;154;247m"
$BRIGHT_BLUE = "$([char]27)[38;2;122;162;247m"
$DARK_BLUE = "$([char]27)[38;2;100;140;200m"
$BRIGHT_GREEN = "$([char]27)[38;2;158;206;106m"
$DARK_GREEN = "$([char]27)[38;2;130;170;90m"
$BRIGHT_ORANGE = "$([char]27)[38;2;255;158;100m"
$BRIGHT_RED = "$([char]27)[38;2;247;118;142m"
$BRIGHT_CYAN = "$([char]27)[38;2;125;207;255m"
$BRIGHT_MAGENTA = "$([char]27)[38;2;187;154;247m"
$BRIGHT_YELLOW = "$([char]27)[38;2;224;175;104m"

# Map DA_COLOR to actual ANSI color code
switch ($DA_COLOR) {
    "purple" { $DA_DISPLAY_COLOR = "$([char]27)[38;2;147;112;219m" }
    "blue" { $DA_DISPLAY_COLOR = $BRIGHT_BLUE }
    "green" { $DA_DISPLAY_COLOR = $BRIGHT_GREEN }
    "cyan" { $DA_DISPLAY_COLOR = $BRIGHT_CYAN }
    "magenta" { $DA_DISPLAY_COLOR = $BRIGHT_MAGENTA }
    "yellow" { $DA_DISPLAY_COLOR = $BRIGHT_YELLOW }
    "red" { $DA_DISPLAY_COLOR = $BRIGHT_RED }
    "orange" { $DA_DISPLAY_COLOR = $BRIGHT_ORANGE }
    default { $DA_DISPLAY_COLOR = "$([char]27)[38;2;147;112;219m" } # Default to purple
}

# Line-specific colors
$LINE1_PRIMARY = $BRIGHT_PURPLE
$LINE1_ACCENT = "$([char]27)[38;2;160;130;210m"
$MODEL_PURPLE = "$([char]27)[38;2;138;99;210m"
$LINE2_PRIMARY = $DARK_BLUE
$LINE2_ACCENT = "$([char]27)[38;2;110;150;210m"
$LINE3_PRIMARY = $DARK_GREEN
$LINE3_ACCENT = "$([char]27)[38;2;140;180;100m"
$COST_COLOR = $LINE3_ACCENT
$TOKENS_COLOR = "$([char]27)[38;2;169;177;214m"
$SEPARATOR_COLOR = "$([char]27)[38;2;140;152;180m"
$DIR_COLOR = "$([char]27)[38;2;135;206;250m"

# MCP colors
$MCP_DAEMON = $BRIGHT_BLUE
$MCP_STRIPE = $LINE2_ACCENT
$MCP_DEFAULT = $LINE2_PRIMARY
$RESET = "$([char]27)[0m"

# Format MCP names efficiently
$mcp_names_formatted = ""
if ($mcp_names_raw) {
    $mcp_names = $mcp_names_raw -split " "
    $formatted_mcp_names = @()
    
    foreach ($mcp in $mcp_names) {
        switch ($mcp) {
            "daemon" { $formatted = "${MCP_DAEMON}Daemon${RESET}" }
            "stripe" { $formatted = "${MCP_STRIPE}Stripe${RESET}" }
            "httpx" { $formatted = "${MCP_DEFAULT}HTTPx${RESET}" }
            "brightdata" { $formatted = "${MCP_DEFAULT}BrightData${RESET}" }
            "naabu" { $formatted = "${MCP_DEFAULT}Naabu${RESET}" }
            "apify" { $formatted = "${MCP_DEFAULT}Apify${RESET}" }
            "content" { $formatted = "${MCP_DEFAULT}Content${RESET}" }
            "Ref" { $formatted = "${MCP_DEFAULT}Ref${RESET}" }
            "pai" { $formatted = "${MCP_DEFAULT}Foundry${RESET}" }
            "playwright" { $formatted = "${MCP_DEFAULT}Playwright${RESET}" }
            default { $formatted = "${MCP_DEFAULT}$($mcp.Substring(0,1).ToUpper() + $mcp.Substring(1))${RESET}" }
        }
        $formatted_mcp_names += $formatted
    }
    
    if (-not ${formatted_mcp_names}) {
        ${mcp_names_formatted} = "None"
    }
    else {
        $mcp_names_formatted = $formatted_mcp_names -join "${SEPARATOR_COLOR}, ${RESET}"
    }
}

# Output the full 3-line statusline
# LINE 1 - PURPLE theme with all counts
Write-Host "${DA_DISPLAY_COLOR}${DA_NAME}${RESET}${LINE1_PRIMARY} here, running ${MODEL_PURPLE}*${model_name}${RESET}${LINE1_PRIMARY} in ${DIR_COLOR}${dir_name}${RESET}${LINE1_PRIMARY}, using: ${RESET}${LINE1_PRIMARY}${fobs_count} Services${RESET}${LINE1_PRIMARY}, ${RESET}${LINE1_PRIMARY}${commands_count} Commands${RESET}${LINE1_PRIMARY}, ${RESET}${LINE1_PRIMARY}${mcps_count} MCPs${RESET}${LINE1_PRIMARY}, & ${RESET}${LINE1_PRIMARY}${fabric_count} Patterns${RESET}"

# LINE 2 - BLUE theme with MCP names
Write-Host "${LINE2_PRIMARY}Active MCPs${RESET}${LINE2_PRIMARY}${SEPARATOR_COLOR}: ${RESET}${mcp_names_formatted}${RESET}"

# LINE 3 - GREEN theme with tokens and cost (show cached or N/A)
# If we have cached data but it's empty, still show N/A
$tokens_display = if ($daily_tokens) { $daily_tokens } else { "N/A" }
$cost_display = if ($daily_cost) { $daily_cost } else { "N/A" }

Write-Host "${LINE3_PRIMARY}* Total Tokens${RESET}${SEPARATOR_COLOR}: ${RESET}${TOKENS_COLOR}${tokens_display}${RESET}${LINE3_PRIMARY} Total Cost${RESET}${SEPARATOR_COLOR}: ${RESET}${TOKENS_COLOR}${cost_display}${RESET}"
