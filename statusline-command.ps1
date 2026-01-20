# =============================================================================
# Claude Code Enhanced Status Line Script (PowerShell) - Windows Optimized
# =============================================================================

$ErrorActionPreference = "SilentlyContinue"

# Read JSON input from stdin (try multiple methods)
$inputData = ""
try {
    # Method 1: Pipeline input
    $inputData = @($input) -join "`n"
} catch {}

if (-not $inputData -or $inputData.Length -lt 2) {
    try {
        # Method 2: Console stdin
        $inputData = [Console]::In.ReadToEnd()
    } catch {}
}

# Remove BOM and clean up
$inputData = $inputData.Trim()
if ($inputData.Length -gt 0 -and $inputData[0] -ne '{') {
    # Find first { character
    $idx = $inputData.IndexOf('{')
    if ($idx -ge 0) {
        $inputData = $inputData.Substring($idx)
    }
}

$data = $null
try {
    $data = $inputData | ConvertFrom-Json
} catch {
    Write-Output "Claude | Parse Error"
    exit 0
}

if (-not $data) {
    Write-Output "Claude | No Data"
    exit 0
}

# ==================== Extract Info with multiple fallbacks ====================
# Model name
$model = "Claude"
if ($data.model) {
    if ($data.model.display_name) { $model = $data.model.display_name }
    elseif ($data.model.name) { $model = $data.model.name }
    elseif ($data.model.id) { $model = $data.model.id }
}

# Shorten model name for cleaner display
$modelShort = $model
$modelShort = $modelShort -replace "claude-", "" -replace "Claude ", ""
$modelShort = $modelShort -replace "-\d{8}$", ""  # Remove date suffix
$modelShort = $modelShort -replace "sonnet", "S" -replace "opus", "O" -replace "haiku", "H"
$modelShort = $modelShort -replace " ", ""

# Current working directory
$cwd = $null
if ($data.cwd) { $cwd = $data.cwd }
elseif ($data.workspace -and $data.workspace.current_dir) { $cwd = $data.workspace.current_dir }
elseif ($data.workspace -and $data.workspace.cwd) { $cwd = $data.workspace.cwd }

# Format directory path (show parent\current for better context)
$dirDisplay = "?"
if ($cwd) {
    $leaf = Split-Path -Leaf $cwd
    $parent = Split-Path -Parent $cwd
    if ($parent) {
        $parentLeaf = Split-Path -Leaf $parent
        $dirDisplay = "$parentLeaf\$leaf"
    } else {
        $dirDisplay = $leaf
    }
    # Limit length for very long paths
    if ($dirDisplay.Length -gt 30) {
        $dirDisplay = "..." + $dirDisplay.Substring($dirDisplay.Length - 27)
    }
}

# Version
$version = if ($data.version) { $data.version } else { $null }

# Output style
$outputStyle = $null
if ($data.output_style -and $data.output_style.name -and $data.output_style.name -ne "default") {
    $outputStyle = $data.output_style.name
}

# Context window
$ctxRemaining = $null
$ctxUsed = $null
if ($data.context_window) {
    if ($null -ne $data.context_window.remaining_percentage) {
        $ctxRemaining = [math]::Round($data.context_window.remaining_percentage, 0)
    }
    if ($null -ne $data.context_window.used_percentage) {
        $ctxUsed = [math]::Round($data.context_window.used_percentage, 0)
    }
}

# ==================== Build Status Parts ====================
$parts = @()

# 1. Model (compact display)
$parts += "[$modelShort]"

# 2. Output style (if non-default)
if ($outputStyle) {
    $parts += "style:$outputStyle"
}

# 3. Vim mode (if enabled)
if ($data.vim -and $data.vim.mode) {
    $vimDisplay = if ($data.vim.mode -eq "INSERT") { "INSERT" } else { "NORMAL" }
    $parts += "vim:$vimDisplay"
}

# 4. Directory
$parts += $dirDisplay

# 5. Git branch + status
if ($cwd -and (Test-Path $cwd)) {
    try {
        Push-Location $cwd
        $isGit = git rev-parse --is-inside-work-tree 2>$null
        if ($isGit -eq "true") {
            $branch = git symbolic-ref --short HEAD 2>$null
            if (-not $branch) {
                $branch = git rev-parse --short HEAD 2>$null
                if ($branch) { $branch = "detached:$branch" }
            }

            if ($branch) {
                # Get changes count (with timeout for large repos)
                $statusLines = git status --porcelain --no-optional-locks 2>$null
                $gitStatus = "git:$branch"

                if ($statusLines) {
                    $modified = @($statusLines | Where-Object { $_ -match '^.M|^M.' }).Count
                    $added = @($statusLines | Where-Object { $_ -match '^\?\?|^A' }).Count
                    $deleted = @($statusLines | Where-Object { $_ -match '^.D|^D.' }).Count

                    $changes = @()
                    if ($modified -gt 0) { $changes += "~$modified" }
                    if ($added -gt 0) { $changes += "+$added" }
                    if ($deleted -gt 0) { $changes += "-$deleted" }

                    if ($changes.Count -gt 0) {
                        $gitStatus += " ($($changes -join ' '))"
                    }
                } else {
                    $gitStatus += " (clean)"
                }

                $parts += $gitStatus
            }
        }
        Pop-Location
    } catch {
        Pop-Location -ErrorAction SilentlyContinue
    }
}

# ==================== Context & Token Info ====================
$metaParts = @()

# Context usage with visual indicator
if ($null -ne $ctxUsed -and $null -ne $ctxRemaining) {
    $ctxIndicator = ""
    if ($ctxRemaining -lt 10) {
        $ctxIndicator = " [!CRITICAL!]"
    } elseif ($ctxRemaining -lt 20) {
        $ctxIndicator = " [!WARNING!]"
    } elseif ($ctxRemaining -lt 40) {
        $ctxIndicator = " [*]"
    }
    $metaParts += "Context: ${ctxUsed}% used, ${ctxRemaining}% left${ctxIndicator}"
}

# Current message tokens
if ($data.context_window -and $data.context_window.current_usage) {
    $cu = $data.context_window.current_usage
    $inT = if ($cu.input_tokens) { $cu.input_tokens } else { 0 }
    $outT = if ($cu.output_tokens) { $cu.output_tokens } else { 0 }

    $inK = if ($inT -ge 1000) { "$([math]::Round($inT/1000,1))k" } else { "$inT" }
    $outK = if ($outT -ge 1000) { "$([math]::Round($outT/1000,1))k" } else { "$outT" }

    $metaParts += "Last: ${inK}in/${outK}out"

    # Cache info
    if ($cu.cache_read_input_tokens -gt 0) {
        $cacheK = if ($cu.cache_read_input_tokens -ge 1000) {
            "$([math]::Round($cu.cache_read_input_tokens/1000,1))k"
        } else {
            "$($cu.cache_read_input_tokens)"
        }
        $metaParts += "Cache: ${cacheK}"
    }
}

# Session total tokens
if ($data.context_window) {
    $totalIn = $data.context_window.total_input_tokens
    $totalOut = $data.context_window.total_output_tokens
    if ($totalIn -or $totalOut) {
        $tInK = if ($totalIn -ge 1000) { "$([math]::Round($totalIn/1000,1))k" } else { "$totalIn" }
        $tOutK = if ($totalOut -ge 1000) { "$([math]::Round($totalOut/1000,1))k" } else { "$totalOut" }
        $metaParts += "Total: ${tInK}in/${tOutK}out"
    }
}

# App version
if ($version) {
    $metaParts += "v$version"
}

# ==================== Output ====================
$output = $parts -join " | "
if ($metaParts.Count -gt 0) {
    $output += " -- " + ($metaParts -join " | ")
}

Write-Output $output
