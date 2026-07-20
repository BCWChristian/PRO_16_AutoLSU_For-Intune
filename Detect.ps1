<#
.SYNOPSIS
    Detection script for Lenovo Driver Updates via Lenovo System Update.
.DESCRIPTION
    Checks if the Lenovo driver update has run in the last 14 days.
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
    Write-Output "Compliant: This is a $Manufacturer device, not a LENOVO. Skipping update process."
    exit 0
}

$RegKey = "HKLM:\SOFTWARE\IT_Config\LenovoUpdate"
$RegValueName = "LastDriverUpdate"
$MaxDaysOld = 14

try {
    if (Test-Path -Path $RegKey) {
        $LastRunStr = Get-ItemPropertyValue -Path $RegKey -Name $RegValueName -ErrorAction SilentlyContinue
        
        if ($LastRunStr) {
            $LastRunDate = [datetime]::Parse($LastRunStr)
            $DaysSinceRun = (Get-Date) - $LastRunDate
            
            if ($DaysSinceRun.TotalDays -lt $MaxDaysOld) {
                Write-Output "Compliant: Lenovo update was run $($DaysSinceRun.ToString('dd')) days ago (Threshold: $MaxDaysOld days)."
                exit 0
            } else {
                Write-Output "Non-Compliant: Lenovo update was run $($DaysSinceRun.ToString('dd')) days ago. Needs remediation."
                exit 1
            }
        }
    }
    
    Write-Output "Non-Compliant: Lenovo update has never been recorded on this device."
    exit 1
} catch {
    Write-Warning "Error during detection: $_"
    exit 1
}
