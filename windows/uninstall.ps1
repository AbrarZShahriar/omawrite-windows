[CmdletBinding()]
param(
    [switch]$Detached
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$registeredAppName = "OmaWrite for Windows"
$installDirectory = [IO.Path]::GetFullPath(
    (Join-Path $env:LOCALAPPDATA "Programs\OmaWrite")
)
$expectedDirectory = [IO.Path]::GetFullPath(
    (Join-Path $env:LOCALAPPDATA "Programs\OmaWrite")
)
if ($installDirectory -ne $expectedDirectory) {
    throw "Refusing to remove an unexpected install directory."
}

$installedExecutable = Join-Path $installDirectory "omawrite.exe"
$runningInstalledApp = @(Get-Process -Name "omawrite" -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -eq $installedExecutable
})
if ($runningInstalledApp.Count -gt 0) {
    throw "Close OmaWrite before removing it."
}

$scriptPath = [IO.Path]::GetFullPath($PSCommandPath)
$scriptIsInstalled = $scriptPath.StartsWith(
    $installDirectory + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
)
if ($scriptIsInstalled -and -not $Detached) {
    $temporaryScript = Join-Path ([IO.Path]::GetTempPath()) (
        "omawrite-uninstall-{0}.ps1" -f [Guid]::NewGuid().ToString("N")
    )
    Copy-Item -LiteralPath $scriptPath -Destination $temporaryScript
    $arguments = @(
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", ('"{0}"' -f $temporaryScript),
        "-Detached"
    )
    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments `
        -WindowStyle Hidden
    Write-Host "OmaWrite removal started."
    return
}

if ($Detached) {
    Start-Sleep -Milliseconds 500
}

$registryPaths = @(
    "Registry::HKEY_CURRENT_USER\Software\Classes\OmaWrite.Markdown",
    "Registry::HKEY_CURRENT_USER\Software\Classes\Applications\omawrite.exe",
    "Registry::HKEY_CURRENT_USER\Software\OmaWriteWindows",
    "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\OmaWriteWindows"
)
foreach ($registryPath in $registryPaths) {
    if (Test-Path -LiteralPath $registryPath) {
        Remove-Item -LiteralPath $registryPath -Recurse -Force
    }
}

$valuePaths = @(
    "Registry::HKEY_CURRENT_USER\Software\Classes\.md\OpenWithProgids",
    "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.md\OpenWithProgids"
)
foreach ($valuePath in $valuePaths) {
    if (Test-Path -LiteralPath $valuePath) {
        Remove-ItemProperty -LiteralPath $valuePath -Name "OmaWrite.Markdown" `
            -ErrorAction SilentlyContinue
    }
}

$registeredApps = "Registry::HKEY_CURRENT_USER\Software\RegisteredApplications"
if (Test-Path -LiteralPath $registeredApps) {
    Remove-ItemProperty -LiteralPath $registeredApps -Name $registeredAppName `
        -ErrorAction SilentlyContinue
}

$shortcutPath = Join-Path $env:APPDATA `
    "Microsoft\Windows\Start Menu\Programs\OmaWrite for Windows.lnk"
if (Test-Path -LiteralPath $shortcutPath) {
    Remove-Item -LiteralPath $shortcutPath -Force
}

if (-not ("OmaWriteUninstallShellNotify" -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class OmaWriteUninstallShellNotify {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(
        uint eventId, uint flags, IntPtr item1, IntPtr item2);
}
'@
}
[OmaWriteUninstallShellNotify]::SHChangeNotify(
    0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)

if (Test-Path -LiteralPath $installDirectory) {
    Remove-Item -LiteralPath $installDirectory -Recurse -Force
}

Write-Host "OmaWrite was removed."

if ($Detached -and (Test-Path -LiteralPath $scriptPath)) {
    Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
}
