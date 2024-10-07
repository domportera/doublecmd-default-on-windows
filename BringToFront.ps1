# See https://www.reddit.com/r/PowerShell/comments/73wi5e/comment/dnubwly/
# As im certain the way i am passing app cli arguments isn't quite right

# example CLI usage - BringToFrontOrLaunch doublecmd 'C:/Program Files/Double Commander/doublecmd' -C
# example inclusion in ~Documents/Powershell/Profile.ps1: 
# $BringToFrontScript = 'C:/Path/To/BringToFront.ps1' 
# if (Test-Path($BringToFrontScript)) {
#   Import-Module "$BringToFrontScript"
# }

$dir = "$env:LOCALAPPDATA/doublecmdscript"
$logFilePath = $dir + "/log.log"

function OpenLogFile() {
    # open log file in default app
    Start-Process -FilePath $logFilePath
}

function logmepls($loginfo, $first = $false) {
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
    Start-Sleep 0.1
    Write-Host $loginfo
}

function BringProcessToFront($process) {

    $windowPid = $process.Id
    logmepls "Process id: $windowPid"
    if ($windowPid -eq 0) {
        logmepls "Process id is 0"
        OpenLogFile
        return;
    }
    $countTime = 0
    while ($process.MainWindowHandle -eq 0) {
        Start-Sleep 0.05
        $countTime += 0.05
        if ($countTime -gt 5) {
            logmepls "Process window not found: $process"
            OpenLogFile
            return;
        }
        logmepls "Trying to get  window again: $process"
    }

    logmepls "Confirmed window exists"
        
    logmepls "Bringing process to front: $process"
    Add-Type -AssemblyName Microsoft.VisualBasic
    [Microsoft.VisualBasic.Interaction]::AppActivate($windowPid)
    Start-Sleep 0.1
    logmepls "Success?"
    # For some reason the sleep here is very important or the window will not 
    # be focused (or will be less reliable). You could experiment with its
    # value if you need to perform work after calling this function.
}

function GetProcess($process_name) {
    $processes = Get-Process -Name "*${process_name}*"
    return $processes | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
}

function BringToFrontOrLaunch {
    param(
        [Parameter(Mandatory = $True, Position = 0)][string]$process_name,
        [Parameter(Mandatory = $True, Position = 1)][string]$process_path,
        [Parameter(Mandatory = $True, ValueFromRemainingArguments = $true, Position = 2)][string[]]
        $argies
    )

    # print working directory
    logmepls "Working directory: $pwd" $true

    logmepls "Beginning process launch: $process_name $process_path $argies"

    # check process path exists
    if (![System.IO.File]::Exists($process_path)) {
        # write to log
        logmepls "Process path does not exist: $process_path"
        OpenLogFile
        return;
    }
 
    $process = GetProcess $process_name
    if ($null -eq $process) {
        Start-Process -FilePath $process_path $argies
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
