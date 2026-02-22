RAM Guardian & Driver Leak Mitigator
A lightweight PowerShell-based "Janitor" service designed for high-end workstations and gaming rigs. It monitors system resources in real-time, throttles background clutter, and automatically resets leaky drivers before they cause a system crash.

🛠 How It Works
This script operates as a dedicated background security guard for your RAM, performing a three-step inspection every 60 seconds:

1. The Diagnostic Snapshot
The script records every running process and its memory usage into Process_Snapshot.txt. This acts as a "Black Box" recorder—if your PC ever lags, you can check this file to see exactly what was happening in the minute leading up to the issue.

2. The Tiered Janitor (Cleanup)
The script balances performance with stability using a two-tier approach:

Tier 1 (Passive): If RAM usage is >70%, it Throttles background apps (setting them to Idle priority) if they exceed 500MB. This ensures background tasks don't steal CPU cycles from your foreground work.

Tier 2 (Aggressive): If RAM usage hits 80%, any non-excluded app over 700MB is Terminated (killed) instantly to prevent a system-wide lockup or crash.

3. The Leak Defense (Kernel Level)
It specifically monitors the Non-Paged Pool (NPP). If this hidden memory area climbs above 3GB (a common sign of driver failure), it automatically restarts the MSI (Mystic Light), Logitech (G HUB), and NVIDIA control services to force a release of the leaked memory.

---------------------------------------------------------------------------------------------------------

🔔 How It Notifies You
RAM Guardian communicates without being intrusive:

Active Desktop Popups: Triggers a 5-second Windows Balloon Tip for significant actions (Start-up, Emergency Cleans, or Driver Resets).

Muted History: If you are in-game or coding, notifications slide silently into the Windows Notification Center (Win + N) for you to review later.

Audit Log: RAM_Monitor_Log.txt provides a timestamped master record of every process handled and how much RAM was reclaimed.

---------------------------------------------------------------------------------------------------------

⚙️ Installation & Setup
To run this as a persistent background service, it is best to use Windows Task Scheduler:

Download the HighMemHandler.ps1 script to a permanent folder (e.g., C:\Scripts\).

Open Task Scheduler and click Create Task.

General Tab: Name it RAM_Guardian and check Run with highest privileges (required to reset drivers).

Triggers Tab: Set to At log on.

Actions Tab: Start a program: powershell.exe.

Arguments: -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Scripts\HighMemHandler.ps1"

Start in: C:\Scripts

Conditions Tab: Uncheck "Start only if on AC power."

Settings Tab: Uncheck "Stop the task if it runs longer than 3 days."

---------------------------------------------------------------------------------------------------------

📝 Customizing the Whitelist
The "Janitor" is designed to be smart and will never touch apps on your exclusion list. To add your own programs (browsers, specific dev tools, or games), edit the $ExcludedProcesses array at the top of the script:
# Add the 'Process Name' (found in Task Manager Details tab, without .exe)
$ExcludedProcesses = @(
    "explorer", "Unity", "Blender", "Steam", "Discord", "Valorant", "YourAppNameHere"
)
Note: The list is not case-sensitive. If a process name has a space (e.g., "Unity Hub"), ensure you include the space inside the quotes.

---------------------------------------------------------------------------------------------------------
