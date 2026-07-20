# PRO_16_AutoLSU_For-Intune

This project contains Proactive Remediation scripts designed to automate driver, firmware, and BIOS updates on Lenovo devices via Intune. It utilizes the **Lenovo System Update (LSU/TVSU)** command-line utility to securely pull the latest updates directly from Lenovo's cloud servers.

## Components
- `Detect.ps1`: Verifies hardware manufacturer (Lenovo) and enforces a 14-day update cycle using a custom registry stamp.
- `Remediate.ps1`: Executes `tvsu.exe` silently to download and install required updates, suppressing reboots and hiding tray icons to avoid disrupting end-users.
- `Test-Local.ps1`: A local wrapper script for testing the detection and remediation logic on a local machine.
