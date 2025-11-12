# See https://www.reddit.com/r/PowerShell/comments/73wi5e/comment/dnubwly/
# As im certain the way i am passing app cli arguments isn't quite right

# example CLI usage - BringToFrontOrLaunch doublecmd 'C:/Program Files/Double Commander/doublecmd' -C
# example inclusion in ~Documents/Powershell/Profile.ps1: 
# $BringToFrontScript = 'C:/Path/To/BringToFront.ps1' 
# if (Test-Path($BringToFrontScript)) {
#   Import-Module "$BringToFrontScript"
# }


function OpenLogFile() {
    # open log file in default app
    Start-Process -FilePath GetLogFilePath
}

function GetLogDir() {
    return "$env:LOCALAPPDATA/doublecmdscript"
}

function GetLogFilePath() {
    return "$env:LOCALAPPDATA/doublecmdscript/log.log"
}

function logmepls($loginfo, $first = $false) {

    $dir = GetLogDir;
    $logFilePath = GetLogFilePath;
    # ensure directory is created
    if (!(Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force
    }

    # if file doesnt exist, create it
    if (!(Test-Path $logFilePath)) {
        New-Item -Path $logFilePath -ItemType File -Force
    }

    if ($first) {
        Out-File -FilePath $logFilePath -InputObject $loginfo
    }
    else {
        Out-File -FilePath $logFilePath -InputObject $loginfo -Append
    }

    Write-Host $loginfo
}

function BringProcessToFront($process) {
    $windowPid = $process.Id
    logmepls "Process id: $windowPid"
    if ($windowPid -eq 0) {
        logmepls "Process id is 0"
        OpenLogFile
        return $false
    }

    logmepls "Confirmed window exists - Bringing process to front: $($process.ProcessName)"
    
    # Method 1: Using Microsoft.VisualBasic (simpler but less reliable)
    try {
        Add-Type -AssemblyName Microsoft.VisualBasic
        $activated = [Microsoft.VisualBasic.Interaction]::AppActivate($windowPid)
        Start-Sleep 0.1
        
        logmepls "Success?"
        # For some reason the sleep here is very important or the window will not 
        # be focused (or will be less reliable). You could experiment with its
        # value if you need to perform work after calling this function.
        if ($activated) {
            logmepls "Successfully activated window using AppActivate"
            return $true
        }
    }
    catch {
        logmepls "AppActivate failed: $($_.Exception.Message)"
    }

    # Method 2: Using Win32 API (more complex but more reliable)
    try {
        Add-Type @"
            using System;
            using System.Runtime.InteropServices;
            public class Win32Api {
                [DllImport("user32.dll")]
                [return: MarshalAs(UnmanagedType.Bool)]
                public static extern bool SetForegroundWindow(IntPtr hWnd);
                
                [DllImport("user32.dll")]
                public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
                
                [DllImport("user32.dll")]
                public static extern bool IsIconic(IntPtr hWnd);
            }
"@

        $hWnd = $process.MainWindowHandle
        if ($hWnd -ne [IntPtr]::Zero) {
            # restore if minimized
            if ([Win32Api]::IsIconic($hWnd)) {
                [Win32Api]::ShowWindow($hWnd, 9) # SW_RESTORE = 9
                Start-Sleep -Milliseconds 50
            }
            
            # bring to front
            $result = [Win32Api]::SetForegroundWindow($hWnd)
            logmepls "SetForegroundWindow result: $result"
            
            if ($result) {
                logmepls "Successfully brought window to front using Win32 API"
                return $true
            }
        }
    }
    catch {
        logmepls "Win32 API method failed: $($_.Exception.Message)"
    }

    logmepls "All methods failed to bring window to front"
    return $false
}

function GetProcess($process_name) {
    $processes = Get-Process -Name "${process_name}"
    return $processes | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
}

function BringToFrontOrLaunch {
    param(
        [Parameter(Mandatory = $True, Position = 0)][string]$process_name,
        [Parameter(Mandatory = $True, Position = 1)][string]$process_path,
        [Parameter(Mandatory = $False, ValueFromRemainingArguments = $true, Position = 2)][string[]] # mandatory false to allow no args
        $argies = @() # default to empty array if no args provided
    )

    # print working directory
    logmepls "Beginning process launch: wd: $pwd | name: $process_name | path: $process_path | args: $argies"

    # check process path exists
    if (![System.IO.File]::Exists($process_path)) {
        # write to log
        logmepls "Process path does not exist: $process_path"
        OpenLogFile
        return;
    }
    $process = GetProcess $process_name
    if ($null -eq $process) {
        # process not running, launch it
        if ($argies.Count -gt 0) {
            # launch process with arguments
            logmepls "Launching process with args: $process_name $argies"
            Start-Process -FilePath $process_path -ArgumentList $argies
        }
        else {
            # launch process without arguments
            Start-Process -FilePath $process_path
        }
        $process = GetProcess $process_name

        while ($null -eq $process) {
            $process = GetProcess $process_name
        }
        logmepls "Launched process: $process"
    }
        
    if ($null -eq $process) {
        logmepls "Failed to launch process: $process_name"
        OpenLogFile
        return;
    }

    BringProcessToFront $process
}
