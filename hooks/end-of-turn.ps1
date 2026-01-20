# =============================================================================
# End-of-Turn Quality Gate Hook (PowerShell version)
# =============================================================================
# This hook runs when Claude finishes responding (Stop event).
# It performs quality checks to catch issues before they accumulate.
# =============================================================================

$ErrorActionPreference = "SilentlyContinue"
$TIMEOUT = 30

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

function Test-NodeJs { Test-Path "package.json" }
function Test-TypeScript { Test-Path "tsconfig.json" }
function Test-Python { (Test-Path "pyproject.toml") -or (Test-Path "setup.py") -or (Test-Path "requirements.txt") }
function Test-Rust { Test-Path "Cargo.toml" }
function Test-Go { Test-Path "go.mod" }

# -----------------------------------------------------------------------------
# Project-Specific Checks
# -----------------------------------------------------------------------------

function Check-NodeJs {
    if (-not (Test-Path "node_modules")) { return }

    $packageJson = Get-Content "package.json" -Raw -ErrorAction SilentlyContinue

    # Run lint if available
    if ($packageJson -match '"lint"') {
        npm run lint --silent 2>$null
    }

    # Run typecheck if TypeScript
    if (Test-TypeScript) {
        if ($packageJson -match '"typecheck"') {
            npm run typecheck --silent 2>$null
        }
        elseif (Get-Command tsc -ErrorAction SilentlyContinue) {
            tsc --noEmit 2>$null
        }
    }
}

function Check-Python {
    # Ruff
    if (Get-Command ruff -ErrorAction SilentlyContinue) {
        ruff check . --fix --silent 2>$null
    }
    # Black
    if (Get-Command black -ErrorAction SilentlyContinue) {
        black --check --quiet . 2>$null
    }
}

function Check-Rust {
    if (Get-Command cargo -ErrorAction SilentlyContinue) {
        cargo check --quiet 2>$null
        cargo clippy --quiet -- -D warnings 2>$null
    }
}

function Check-Go {
    if (Get-Command go -ErrorAction SilentlyContinue) {
        go vet ./... 2>$null
    }
    if (Get-Command staticcheck -ErrorAction SilentlyContinue) {
        staticcheck ./... 2>$null
    }
}

# -----------------------------------------------------------------------------
# Universal Checks
# -----------------------------------------------------------------------------

function Check-Secrets {
    $gitDir = git rev-parse --git-dir 2>$null
    if (-not $gitDir) { return }

    $stagedFiles = git diff --cached --name-only 2>$null
    if ($stagedFiles) {
        foreach ($file in $stagedFiles) {
            $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
            if ($content -match '(API_KEY|SECRET|TOKEN|PASSWORD)\s*[=:]\s*[''"][A-Za-z0-9_\-]{16,}') {
                Write-Warning "Possible hardcoded secrets in staged file: $file"
            }
        }
    }
}

function Check-EnvCommitted {
    $gitDir = git rev-parse --git-dir 2>$null
    if (-not $gitDir) { return }

    $stagedFiles = git diff --cached --name-only 2>$null
    if ($stagedFiles -match "^\.env") {
        Write-Warning ".env file is staged for commit!"
    }
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

# Run project-specific checks
if (Test-NodeJs) { Check-NodeJs }
if (Test-Python) { Check-Python }
if (Test-Rust) { Check-Rust }
if (Test-Go) { Check-Go }

# Universal checks
Check-Secrets
Check-EnvCommitted

exit 0
