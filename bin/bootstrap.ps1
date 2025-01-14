#
#
Set-StrictMode -Off
$LogFilePath = "$HOME\bootstrap_log.txt"

function Test-CommandAvailable {
    param (
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $Command
    )
    return [Boolean](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Create-ShortCut {
    param (
        [Parameter(Mandatory = $True, Position = 0)]
        [string] $SourceExe,
        [Parameter(Mandatory = $True, Position = 1)]
        [string] $ShortcutName
    )

    $DestinationPath = "$HOME\Desktop\$ShortcutName.lnk"
    if (Test-Path -Path $DestinationPath) {
        return
    }
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($DestinationPath)
    $Shortcut.TargetPath = $SourceExe
    $Shortcut.Save()
}

function Admin-ShortCut {
      param (
        [Parameter(Mandatory = $True, Position = 0)]
        [string] $ShortcutName
    )

      $DestinationPath = "$HOME\Desktop\$ShortcutName.lnk"
      $bytes = [System.IO.File]::ReadAllBytes($DestinationPath)
      $bytes[0x15] = $bytes[0x15] -bor 0x20
      [System.IO.File]::WriteAllBytes($DestinationPath, $bytes)
}

function PowerShell-Path {
    if (Test-Path -Path "C:\Program Files\PowerShell\7\pwsh.exe")
    {
        $path = "C:\Program Files\PowerShell\7\pwsh.exe"
    } else {
        $path = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    }
    return $path
}

if (!(Test-CommandAvailable('scoop')))
{
    echo "Installing Scoop package manager"
    iex "& {$( irm get.scoop.sh )} -RunAsAdmin"
} else {
    echo "Scoop package manager already installed"
}

echo "Installing base software packages"

Invoke-Command {
    scoop install git openssl cmake make jq curl tar gzip netcat -g
    scoop bucket add versions
    scoop install python312 -g
    scoop bucket add java
    scoop install maven microsoft11-jdk -g
} *>&1 | Out-File -FilePath $LogFilePath -NoClobber -Append

echo "Creating shortcuts"
$PowerShellPath = PowerShell-Path
Create-ShortCut $PowerShellPath "PowerShell"
Create-ShortCut $PowerShellPath "AdminShell"
Admin-ShortCut "AdminShell"

echo "Done."
