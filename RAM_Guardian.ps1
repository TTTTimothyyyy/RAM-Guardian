# Define paths
$LogFile = Join-Path -Path $PSScriptRoot -ChildPath "RAM_Monitor_Log.txt"
$SnapshotFile = Join-Path -Path $PSScriptRoot -ChildPath "Process_Snapshot.txt"

# Critical system processes + Games + Dev Tools + Browsers
$ExcludedProcesses = @(
    "explorer", "dwm", "lsass", "services", "system", "Idle", "wininit", "winlogon", "powershell", "pwsh", 
    "Unity", "UnityHub", "devenv", "Blender", "Steam", "Discord", "EpicGamesLauncher", 
    "OperaGXInternetBrowser", "TaskManager", "RiotClient", "Valorant", 
    "ArenaBreakoutInfinite", "Zero-KLauncher", "Spring", "NvidiaApp", "msedge", "chrome", "opera", "GoogleChrome"
)

function Write-Log {
    param([string]$Message)
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$TimeStamp - $Message" | Out-File -FilePath $LogFile -Append
}

# Notification Function for Windows Popups
function Send-Notification {
    param([string]$Title, [string]$Message)
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $global:balloon = New-Object System.Windows.Forms.NotifyIcon
        $global:balloon.Icon = [System.Drawing.SystemIcons]::Information
        $global:balloon.BalloonTipTitle = $Title
        $global:balloon.BalloonTipText = $Message
        $global:balloon.Visible = $true
        $global:balloon.ShowBalloonTip(5000)
    } catch {
        Write-Log "NOTIFICATION ERROR: Could not display popup ($Message)"
    }
}

function Take-ProcessSnapshot {
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Header = "--- PROCESS SNAPSHOT ($TimeStamp) ---`n"
    $Header += "{0,-30} {1,-15} {2,-15}" -f "ProcessName", "Usage(MB)", "PID"
    $Header += "`n" + ("-" * 60)
    
    $Data = Get-Process | Sort-Object WorkingSet64 -Descending | ForEach-Object {
        "{0,-30} {1,-15} {2,-15}" -f $_.ProcessName, ([Math]::Round($_.WorkingSet64 / 1MB, 2)), $_.Id
    }
    
    $Header + ($Data -join "`n") | Out-File -FilePath $SnapshotFile
    Write-Log "DIAGNOSTIC: Process snapshot updated."
}

# --- SCRIPT START ---
Write-Log "RAM Monitor Re-Started. High-Frequency Mode (1-min) Active."
Send-Notification -Title "RAM Guardian" -Message "High-Frequency Monitoring Started."

try {
    while ($true) {
        # --- PART 1: SYSTEM STATS ---
        $OS = Get-CimInstance Win32_OperatingSystem
        $UsedRAMPercent = [Math]::Round(($OS.TotalVisibleMemorySize - $OS.FreePhysicalMemory) / $OS.TotalVisibleMemorySize * 100, 2)
        $PoolNPP = (Get-Counter '\Memory\Pool Nonpaged Bytes').CounterSamples.CookedValue / 1GB

        # --- PART 2: MAINTENANCE & SNAPSHOT (Every Minute) ---
        Take-ProcessSnapshot

        $AllProcs = Get-Process | Where-Object { $ExcludedProcesses -notcontains $_.ProcessName }
        foreach ($Proc in $AllProcs) {
            try {
                $UsageMB = [Math]::Round($Proc.WorkingSet64 / 1MB, 2)
                
                # If System RAM is high (>70%) and process is heavy, handle it
                if ($UsedRAMPercent -ge 70) {
                    if ($UsedRAMPercent -ge 80 -and $UsageMB -ge 700) {
                        Write-Log "ACTION: TERMINATED | $($Proc.ProcessName) | Usage: $UsageMB MB"
                        Stop-Process -Id $Proc.Id -Force -ErrorAction SilentlyContinue
                    } elseif ($UsageMB -ge 500) {
                        Write-Log "ACTION: THROTTLED | $($Proc.ProcessName) | Priority set to Idle"
                        $Proc.PriorityClass = 'Idle'
                    }
                }
                # Routine background throttling for anything over 500MB regardless of system usage
                elseif ($UsageMB -ge 500) {
                    $Proc.PriorityClass = 'Idle'
                }
            } catch { continue }
        }

        # --- PART 3: KERNEL LEAK MITIGATION (Every Minute) ---
        if ($PoolNPP -gt 3.0) {
            $NPP_Log = [Math]::Round($PoolNPP, 2)
            Write-Log "WARNING: Non-Paged Pool Leak detected ($NPP_Log GB). Refreshing services..."
            Send-Notification -Title "Driver Leak Mitigation" -Message "NPP is high ($NPP_Log GB). Refreshing RGB and Logitech services."

            # Reset services known for leaks
            Get-Service "LEDKeeper2", "Mystic_Light_Service" -ErrorAction SilentlyContinue | Restart-Service -Force
            Get-Service "LGHUBConfigService" -ErrorAction SilentlyContinue | Restart-Service -Force
            Get-Service "NvContainerLocalSystem" -ErrorAction SilentlyContinue | Restart-Service -Force
            
            Write-Log "ACTION: MSI, Logitech, and NVIDIA services refreshed."
        }

        # Pause for 60 seconds
        Start-Sleep -Seconds 60
    }
}
finally {
    if ($global:balloon) { $global:balloon.Dispose() }
    Write-Log "RAM Monitor Service Stopped."
}