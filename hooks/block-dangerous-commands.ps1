# =============================================================================
# PreToolUse Hook: Block Dangerous Bash Commands (PowerShell version)
# =============================================================================
# Exit codes:
#   0 = Allow command
#   2 = Block command (stderr fed back to Claude)
# =============================================================================

$ErrorActionPreference = "SilentlyContinue"

# Read JSON input from stdin
$input = [Console]::In.ReadToEnd()
$data = $input | ConvertFrom-Json

$command = $data.tool_input.command

if (-not $command) {
    exit 0  # No command, allow
}

# -----------------------------------------------------------------------------
# Dangerous Patterns
# -----------------------------------------------------------------------------

# rm -rf with dangerous paths
if ($command -match 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive\s+--force|-rf|-fr)\s+(/|~|\.\.|\$HOME|\$\{HOME\})') {
    Write-Error "BLOCKED: Destructive rm command targeting root, home, or parent directory"
    Write-Error "Command: $command"
    exit 2
}

# rm -rf /* or rm -rf ~/*
if ($command -match 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive\s+--force|-rf|-fr)\s+(/\*|~/\*|/home)') {
    Write-Error "BLOCKED: Destructive rm command with wildcard on sensitive path"
    Write-Error "Command: $command"
    exit 2
}

# Force push to main/master
if ($command -match 'git\s+push\s+.*(-f|--force)\s+.*(main|master|production|release)') {
    Write-Error "BLOCKED: Force push to protected branch"
    Write-Error "Command: $command"
    Write-Error "Tip: Create a PR instead of force pushing to main/master"
    exit 2
}

# chmod 777 (world-writable)
if ($command -match 'chmod\s+(777|a\+rwx)') {
    Write-Error "BLOCKED: Setting world-writable permissions (777)"
    Write-Error "Command: $command"
    Write-Error "Tip: Use 755 for directories, 644 for files"
    exit 2
}

# Piping curl directly to shell
if ($command -match 'curl\s+.*\|\s*(ba)?sh') {
    Write-Error "BLOCKED: Piping curl output directly to shell"
    Write-Error "Command: $command"
    Write-Error "Tip: Download script first, review it, then execute"
    exit 2
}

# wget piped to shell
if ($command -match 'wget\s+.*\|\s*(ba)?sh') {
    Write-Error "BLOCKED: Piping wget output directly to shell"
    Write-Error "Command: $command"
    exit 2
}

# dd writing to disk devices
if ($command -match 'dd\s+.*of=/dev/(sd|hd|nvme|disk)') {
    Write-Error "BLOCKED: dd command writing directly to disk device"
    Write-Error "Command: $command"
    exit 2
}

# mkfs (format disk)
if ($command -match 'mkfs') {
    Write-Error "BLOCKED: mkfs command (disk formatting)"
    Write-Error "Command: $command"
    exit 2
}

# Commands that could exfiltrate data
if ($command -match '(curl|wget|nc|netcat)\s+.*\.(env|pem|key|secret)') {
    Write-Error "BLOCKED: Command appears to exfiltrate sensitive files"
    Write-Error "Command: $command"
    exit 2
}

# Reading .env files via cat/less/head/tail
if ($command -match '(cat|less|head|tail|more|bat)\s+.*\.env') {
    Write-Error "BLOCKED: Reading .env file via command"
    Write-Error "Tip: Use environment variables instead of reading .env directly"
    exit 2
}

# Command is safe, allow it
exit 0
