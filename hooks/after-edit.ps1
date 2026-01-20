# =============================================================================
# PostToolUse Hook: After File Edit (PowerShell version)
# =============================================================================
# This hook runs AFTER Claude edits or writes a file.
# Use it for fast operations like formatting that should run immediately.
# =============================================================================

$ErrorActionPreference = "SilentlyContinue"

# Read JSON input from stdin
$input = [Console]::In.ReadToEnd()
$data = $input | ConvertFrom-Json

$filePath = $data.tool_input.file_path
if (-not $filePath) {
    $filePath = $data.tool_input.path
}

if (-not $filePath) {
    exit 0  # No file path, nothing to do
}

# Get file extension
$extension = [System.IO.Path]::GetExtension($filePath).TrimStart('.')

# -----------------------------------------------------------------------------
# Format based on file type
# -----------------------------------------------------------------------------

switch ($extension) {
    { $_ -in @('js', 'jsx', 'ts', 'tsx', 'json', 'md', 'yaml', 'yml', 'css', 'scss', 'html') } {
        # Prettier for web files
        $prettier = Get-Command prettier -ErrorAction SilentlyContinue
        if ($prettier) {
            & prettier --write $filePath 2>$null
        }
    }
    'py' {
        # Black for Python
        $black = Get-Command black -ErrorAction SilentlyContinue
        if ($black) {
            & black --quiet $filePath 2>$null
        }
        # Ruff for linting
        $ruff = Get-Command ruff -ErrorAction SilentlyContinue
        if ($ruff) {
            & ruff check --fix --silent $filePath 2>$null
        }
    }
    'go' {
        # gofmt for Go
        $gofmt = Get-Command gofmt -ErrorAction SilentlyContinue
        if ($gofmt) {
            & gofmt -w $filePath 2>$null
        }
    }
    'rs' {
        # rustfmt for Rust
        $rustfmt = Get-Command rustfmt -ErrorAction SilentlyContinue
        if ($rustfmt) {
            & rustfmt $filePath 2>$null
        }
    }
}

# Always exit 0 - formatting failures shouldn't block work
exit 0
