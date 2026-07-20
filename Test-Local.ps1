<#
.SYNOPSIS
    Local testing wrapper for Lenovo Proactive Remediation scripts.
.DESCRIPTION
    Runs the Detection script and, if non-compliant, triggers the Remediation script.
    Run this as Administrator to accurately simulate Intune.
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DetectPath = Join-Path -Path $ScriptDir -ChildPath "Detect.ps1"
$RemediatePath = Join-Path -Path $ScriptDir -ChildPath "Remediate.ps1"

Write-Host "Running Detection Script..." -ForegroundColor Cyan
$Process = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$DetectPath`"" -Wait -PassThru -NoNewWindow
$DetectExitCode = $Process.ExitCode

if ($DetectExitCode -eq 1) {
    Write-Host "`nDetection returned Exit Code 1. Running Remediation Script..." -ForegroundColor Yellow
    $Process = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$RemediatePath`"" -Wait -PassThru -NoNewWindow
    Write-Host "`nRemediation finished with Exit Code: $($Process.ExitCode)" -ForegroundColor Green
    exit $Process.ExitCode
} elseif ($DetectExitCode -eq 0) {
    Write-Host "`nDetection returned Exit Code 0. System is compliant. Skipping Remediation." -ForegroundColor Green
    exit 0
} else {
    Write-Error "Detection failed with exit code: $DetectExitCode"
    exit $DetectExitCode
}
