# See https://www.reddit.com/r/PowerShell/comments/73wi5e/comment/dnubwly/
# As im certain the way i am passing app cli arguments isn't quite right

# example CLI usage - BringToFrontOrLaunch doublecmd 'C:/Program Files/Double Commander/doublecmd' -C
# example inclusion in ~Documents/Powershell/Profile.ps1: 
# $BringToFrontScript = 'C:/Path/To/BringToFront.ps1' 
# if (Test-Path($BringToFrontScript)) {
#   Import-Module "$BringToFrontScript"
# }

function BringProcessToFront($process) {
        # [console]::beep(500,300)
        $countTime = 0
        while ($process.MainWindowHandle -eq 0) {
            Start-Sleep 0.05
            $countTime += 0.05
            if ($countTime -gt 5) {
                return;
            }
        }
        
        Add-Type -AssemblyName Microsoft.VisualBasic
        [Microsoft.VisualBasic.Interaction]::AppActivate($process.Id)
        Start-Sleep 0.1
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
 
    $process = GetProcess $process_name
    if ($null -eq $process) {
        $process = Start-Process -FilePath $process_path $argies
        Start-Sleep 1
    }
        
    BringProcessToFront $process
}
