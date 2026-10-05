# ToggleLANPowerSaving.ps1
# Self-elevate to Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

do {
    # Target active physical wired LAN adapter
    $adapters = Get-NetAdapter -Physical | Where-Object { $_.MediaType -eq '802.3' }

    if (-not $adapters) {
        Write-Host "No physical wired LAN adapters detected!" -ForegroundColor Red
        Pause
        exit
    }

    $adapter = $adapters | Select-Object -First 1

    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " TARGET LAN DEVICE IDENTIFIER" -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " Device Name     : $($adapter.Name)" -ForegroundColor White
    Write-Host " Controller Model: $($adapter.InterfaceDescription)" -ForegroundColor White
    Write-Host " Hardware MAC    : $($adapter.MacAddress)" -ForegroundColor White
    Write-Host " Status          : $($adapter.Status)" -ForegroundColor White
    Write-Host "===================================================" -ForegroundColor Cyan

    # Fetch property objects using wildcards
    $allProps = Get-NetAdapterAdvancedProperty -Name $adapter.Name
    $powerSetting = $allProps | Where-Object { $_.DisplayName -like '*Power Saving*' } | Select-Object -First 1
    $eeeSetting   = $allProps | Where-Object { $_.DisplayName -like '*Energy*Efficient*Ethernet*' -or $_.DisplayName -like '*EEE*' } | Select-Object -First 1

    Write-Host "`nCURRENT POWER SETTINGS:" -ForegroundColor Yellow

    if ($powerSetting) {
        Write-Host " 1. Power Saving Mode       : " -NoNewline
        if ($powerSetting.DisplayValue -eq 'Disabled') {
            Write-Host "Power Saving OFF - Best Performance" -ForegroundColor Green
        } else {
            Write-Host "Power Saving ON - May Cause Drops" -ForegroundColor Yellow
        }
    } else {
        Write-Host " 1. Power Saving Mode       : Not Supported" -ForegroundColor Gray
    }

    if ($eeeSetting) {
        Write-Host " 2. Energy-Efficient Ethernet: " -NoNewline
        if ($eeeSetting.DisplayValue -eq 'Disabled') {
            Write-Host "Power Saving OFF - Best Performance" -ForegroundColor Green
        } else {
            Write-Host "Power Saving ON - May Cause Drops" -ForegroundColor Yellow
        }
    } else {
        Write-Host " 2. Energy-Efficient Ethernet: Not Supported" -ForegroundColor Gray
    }
    Write-Host "---------------------------------------------------" -ForegroundColor Gray

    Write-Host "`nSELECT ACTION:"
    Write-Host " [1] Turn ALL Power Savings OFF (Gaming Preset)"
    Write-Host " [2] Toggle 'Power Saving Mode' Only"
    Write-Host " [3] Toggle 'Energy-Efficient Ethernet' Only"
    Write-Host " [4] Turn ALL Power Savings ON (Windows Defaults)"
    Write-Host " [5] Exit"

    $choice = Read-Host "`nEnter option (1-5)"

    switch ($choice) {
        '1' {
            if ($powerSetting) {$p1 = @{ Name = $adapter.Name; DisplayName =$powerSetting.DisplayName; DisplayValue = 'Disabled'; ErrorAction = 'SilentlyContinue' }
                Set-NetAdapterAdvancedProperty @p1
            }
            if ($eeeSetting) {$p2 = @{ Name = $adapter.Name; DisplayName =$eeeSetting.DisplayName; DisplayValue = 'Disabled'; ErrorAction = 'SilentlyContinue' }
                Set-NetAdapterAdvancedProperty @p2
            }
            Write-Host "`n[SUCCESS] All power savings set to OFF." -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
        '2' {
            if ($powerSetting) {
                $targetVal = if ($powerSetting.DisplayValue -eq 'Disabled') { 'Enabled' } else { 'Disabled' }
                $p = @{ Name = $adapter.Name; DisplayName = $powerSetting.DisplayName; DisplayValue = $targetVal; ErrorAction = 'SilentlyContinue' }
                Set-NetAdapterAdvancedProperty @p
                Write-Host "`n[SUCCESS] Power Saving Mode toggled to $targetVal." -ForegroundColor Green
                Start-Sleep -Seconds 2
            }
        }
        '3' {
            if ($eeeSetting) {
                $targetVal = if ($eeeSetting.DisplayValue -eq 'Disabled') { 'Enabled' } else { 'Disabled' }
                $p = @{ Name =$adapter.Name; DisplayName = $eeeSetting.DisplayName; DisplayValue =$targetVal; ErrorAction = 'SilentlyContinue' }
                Set-NetAdapterAdvancedProperty @p
                Write-Host "`n[SUCCESS] Energy-Efficient Ethernet toggled to $targetVal." -ForegroundColor Green
                Start-Sleep -Seconds 2
            }
        }
        '4' {
            if ($powerSetting) {
                $p1 = @{ Name = $adapter.Name; DisplayName = $powerSetting.DisplayName; DisplayValue = 'Enabled'; ErrorAction = 'SilentlyContinue' }
                Set-NetAdapterAdvancedProperty @p1
            }
            if ($eeeSetting) {
                $p2 = @{ Name = $adapter.Name; DisplayName = $eeeSetting.DisplayName; DisplayValue = 'Enabled'; ErrorAction = 'SilentlyContinue' }
                Set-NetAdapterAdvancedProperty @p2
            }
            Write-Host "`n[SUCCESS] All power savings set to ON." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
        '5' {
            Write-Host "`nExiting..."
            exit
        }
        default {
            Write-Host "`nInvalid selection." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)