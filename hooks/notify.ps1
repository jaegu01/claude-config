# =============================================================================
# Notification Hook: Desktop Alerts (PowerShell version)
# =============================================================================
# This hook runs when Claude Code sends notifications.
# It triggers Windows toast notifications.
# =============================================================================

$ErrorActionPreference = "SilentlyContinue"

# Read JSON input from stdin
$input = [Console]::In.ReadToEnd()
$data = $input | ConvertFrom-Json

$content = $data.content
if (-not $content) {
    $content = "Claude needs your attention"
}

# Truncate long messages
if ($content.Length -gt 100) {
    $content = $content.Substring(0, 100) + "..."
}

# -----------------------------------------------------------------------------
# Send Windows Toast Notification
# -----------------------------------------------------------------------------

try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

    $title = "Claude Code"
    $template = @"
<toast>
    <visual>
        <binding template="ToastText02">
            <text id="1">$title</text>
            <text id="2">$content</text>
        </binding>
    </visual>
</toast>
"@

    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml($template)
    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code").Show($toast)
}
catch {
    # Fallback: console beep
    [Console]::Beep()
}

exit 0
