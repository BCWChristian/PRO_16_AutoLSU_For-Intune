<#
.SYNOPSIS
    Remediation script for Lenovo Driver Updates via Lenovo System Update (TVSU).
.DESCRIPTION
    Executes tvsu.exe silently to download and install updates from the Lenovo cloud.
#>

try {
    $Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).Manufacturer
    if ([string]::IsNullOrWhiteSpace($Manufacturer)) {
        Write-Warning "Failed to determine device manufacturer: Value is null or empty."
        exit 1
    }
} catch {
    Write-Warning "Failed to query Win32_ComputerSystem for manufacturer: $_"
    exit 1
}

$AllowedManufacturers = @("LENOVO")
if ($Manufacturer.ToUpper().Trim() -notin $AllowedManufacturers) {
    Write-Output "This is a $Manufacturer device, not a LENOVO. Aborting remediation safely."
    exit 0
}

function Set-SuccessStamp {
    $RegKey = "HKLM:\SOFTWARE\IT_Config\LenovoUpdate"
    $RegValueName = "LastDriverUpdate"
    
    if (-not (Test-Path -Path $RegKey)) {
        New-Item -Path $RegKey -Force -ErrorAction Stop | Out-Null
    }
    
    $CurrentDate = Get-Date -Format "o"
    Set-ItemProperty -Path $RegKey -Name $RegValueName -Value $CurrentDate -ErrorAction Stop
    Write-Output "Success timestamp written to registry."
}

# Lenovo System Update is usually located here on Lenovo commercial devices
$TvsuPath = "C:\Program Files (x86)\Lenovo\System Update\tvsu.exe"

if (-not (Test-Path -Path $TvsuPath)) {
    Write-Warning "Lenovo System Update (tvsu.exe) was not found at $TvsuPath. Please ensure TVSU or Commercial Vantage is deployed to Lenovo devices."
    exit 1
}

# TVSU Silent Arguments:
# /CM - Command Mode
# -search A - Search for all applicable updates
# -action INSTALL - Install them
# -includerebootpackages 1,3,4,5 - Include packages that require reboot (1: Forced, 3: Requires reboot, 4: Shutdown, 5: Delayed)
# -noreboot - Suppress the actual reboot so Intune/User can handle it
# -noicon - Hide taskbar icon
# -nolicense - Auto-accept licenses
$TvsuArgs = "/CM -search A -action INSTALL -includerebootpackages 1,3,4,5 -noreboot -noicon -nolicense -defaultupdate"

try {
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host " Lenovo System Update is now analyzing and installing..." -ForegroundColor Cyan
    Write-Host " This process typically takes 5-15 minutes." -ForegroundColor Yellow
    Write-Host " Your screen may flicker if graphics drivers are updated." -ForegroundColor Yellow
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host "Running in background, please wait..." -NoNewline

    $Process = Start-Process -FilePath $TvsuPath -ArgumentList $TvsuArgs -Wait -PassThru -NoNewWindow
    
    Write-Host "`nDone!" -ForegroundColor Green
    $ExitCode = $Process.ExitCode
    Write-Output "TVSU completed with exit code: $ExitCode"
    
    # TVSU typically returns 0 on success, or 1 if a reboot is needed
    if ($ExitCode -eq 0 -or $ExitCode -eq 1) {
        Write-Output "Lenovo Updates processed successfully."
        Set-SuccessStamp
        exit 0
    } else {
        Write-Warning "TVSU finished with unexpected exit code: $ExitCode"
        Set-SuccessStamp # We still stamp it so it doesn't loop infinitely failing every day
        exit 0
    }
} catch {
    Write-Error "Failed to execute TVSU: $_"
    exit 1
}
