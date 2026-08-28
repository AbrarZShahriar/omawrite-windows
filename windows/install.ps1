[CmdletBinding()]
param(
    [string]$PackagePath = "",
    [switch]$SkipDefaultAppsPage,
    [switch]$NoLaunch
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repository = "AbrarZShahriar/omawrite-windows"
$registeredAppName = "OmaWrite for Windows"
$progId = "OmaWrite.Markdown"
$installDirectory = [IO.Path]::GetFullPath(
    (Join-Path $env:LOCALAPPDATA "Programs\OmaWrite")
)
$installParent = [IO.Path]::GetFullPath((Split-Path $installDirectory -Parent))
$stagingDirectory = $installDirectory + ".installing"
$temporaryDirectory = ""

function Assert-ManagedPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [IO.Path]::GetFullPath($Path)
    $parentPrefix = $installParent.TrimEnd('\') + '\'
    if (-not $fullPath.StartsWith($parentPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to manage a path outside $installParent"
    }
}

function Find-PackageRoot {
    param([Parameter(Mandatory = $true)][string]$Root)

    $executables = @(Get-ChildItem -LiteralPath $Root -Filter "omawrite.exe" -File -Recurse)
    if ($executables.Count -ne 1) {
        throw "Expected one omawrite.exe in the package, found $($executables.Count)."
    }

    return $executables[0].Directory.FullName
}

function Get-LatestPackage {
    $headers = @{ "User-Agent" = "OmaWrite-Windows-Installer" }
    $release = Invoke-RestMethod `
        -Headers $headers `
        -Uri "https://api.github.com/repos/$repository/releases/latest"

    $zipAsset = @($release.assets | Where-Object {
        $_.name -match '^OmaWrite-Windows-.*-x64\.zip$'
    }) | Select-Object -First 1
    if ($null -eq $zipAsset) {
        throw "The latest release does not contain a Windows x64 package."
    }

    $hashAssetName = $zipAsset.name + ".sha256"
    $hashAsset = @($release.assets | Where-Object {
        $_.name -eq $hashAssetName
    }) | Select-Object -First 1
    if ($null -eq $hashAsset) {
        throw "The latest release does not contain $hashAssetName."
    }

    $script:temporaryDirectory = Join-Path `
        ([IO.Path]::GetTempPath()) `
        ("omawrite-windows-" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $script:temporaryDirectory | Out-Null

    $zipPath = Join-Path $script:temporaryDirectory $zipAsset.name
    $hashPath = Join-Path $script:temporaryDirectory $hashAsset.name
    Invoke-WebRequest -UseBasicParsing -Headers $headers `
        -Uri $zipAsset.browser_download_url -OutFile $zipPath
    Invoke-WebRequest -UseBasicParsing -Headers $headers `
        -Uri $hashAsset.browser_download_url -OutFile $hashPath

    $expectedHash = ((Get-Content -Raw -LiteralPath $hashPath).Trim() -split '\s+')[0]
    $actualHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
    if ($actualHash -ne $expectedHash) {
        throw "The release checksum does not match."
    }

    $expandedPath = Join-Path $script:temporaryDirectory "package"
    Expand-Archive -LiteralPath $zipPath -DestinationPath $expandedPath
    return Find-PackageRoot -Root $expandedPath
}

function Resolve-PackageRoot {
    $sourceRoot = Split-Path $PSScriptRoot -Parent
    if ($PackagePath) {
        $resolvedPackage = (Resolve-Path -LiteralPath $PackagePath).Path
        if ((Get-Item -LiteralPath $resolvedPackage).PSIsContainer) {
            return Find-PackageRoot -Root $resolvedPackage
        }

        $script:temporaryDirectory = Join-Path `
            ([IO.Path]::GetTempPath()) `
            ("omawrite-windows-local-" + [Guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $script:temporaryDirectory | Out-Null
        Expand-Archive -LiteralPath $resolvedPackage -DestinationPath $script:temporaryDirectory
        return Find-PackageRoot -Root $script:temporaryDirectory
    }

    if (Test-Path -LiteralPath (Join-Path $sourceRoot "omawrite.exe")) {
        return $sourceRoot
    }

    return Get-LatestPackage
}

function Set-DefaultAppRegistration {
    param([Parameter(Mandatory = $true)][string]$Executable)

    $classes = "Registry::HKEY_CURRENT_USER\Software\Classes"
    $progIdPath = Join-Path $classes $progId
    New-Item -Path (Join-Path $progIdPath "shell\open\command") -Force | Out-Null
    Set-Item -LiteralPath $progIdPath -Value "Markdown Document"
    New-Item -Path (Join-Path $progIdPath "DefaultIcon") -Force | Out-Null
    Set-Item -LiteralPath (Join-Path $progIdPath "DefaultIcon") `
        -Value ('"' + $Executable + '",0')
    Set-Item -LiteralPath (Join-Path $progIdPath "shell\open\command") `
        -Value ('"' + $Executable + '" "%1"')

    $applicationPath = Join-Path $classes "Applications\omawrite.exe"
    New-Item -Path (Join-Path $applicationPath "SupportedTypes") -Force | Out-Null
    New-Item -Path (Join-Path $applicationPath "shell\open\command") -Force | Out-Null
    New-ItemProperty -LiteralPath $applicationPath -Name "FriendlyAppName" `
        -Value $registeredAppName -PropertyType String -Force | Out-Null
    New-ItemProperty -LiteralPath (Join-Path $applicationPath "SupportedTypes") `
        -Name ".md" -Value "" -PropertyType String -Force | Out-Null
    Set-Item -LiteralPath (Join-Path $applicationPath "shell\open\command") `
        -Value ('"' + $Executable + '" "%1"')

    $classOpenWith = Join-Path $classes ".md\OpenWithProgids"
    New-Item -Path $classOpenWith -Force | Out-Null
    New-ItemProperty -LiteralPath $classOpenWith -Name $progId `
        -Value "" -PropertyType String -Force | Out-Null

    $capabilitiesPath = "Registry::HKEY_CURRENT_USER\Software\OmaWriteWindows\Capabilities"
    New-Item -Path (Join-Path $capabilitiesPath "FileAssociations") -Force | Out-Null
    New-ItemProperty -LiteralPath $capabilitiesPath -Name "ApplicationName" `
        -Value $registeredAppName -PropertyType String -Force | Out-Null
    New-ItemProperty -LiteralPath $capabilitiesPath -Name "ApplicationDescription" `
        -Value "A focused native Markdown writing app." -PropertyType String -Force | Out-Null
    New-ItemProperty -LiteralPath (Join-Path $capabilitiesPath "FileAssociations") `
        -Name ".md" -Value $progId -PropertyType String -Force | Out-Null

    $registeredApps = "Registry::HKEY_CURRENT_USER\Software\RegisteredApplications"
    New-Item -Path $registeredApps -Force | Out-Null
    New-ItemProperty -LiteralPath $registeredApps -Name $registeredAppName `
        -Value "Software\OmaWriteWindows\Capabilities" -PropertyType String -Force | Out-Null

    $explorerExtension = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.md"
    $explorerProgIds = Join-Path $explorerExtension "OpenWithProgids"
    New-Item -Path $explorerProgIds -Force | Out-Null
    New-ItemProperty -LiteralPath $explorerProgIds -Name $progId `
        -Value "" -PropertyType String -Force | Out-Null
}

function Set-InstalledAppRegistration {
    param([Parameter(Mandatory = $true)][string]$Executable)

    $startMenuDirectory = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
    $shortcutPath = Join-Path $startMenuDirectory "OmaWrite for Windows.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $Executable
    $shortcut.WorkingDirectory = $installDirectory
    $shortcut.Description = "OmaWrite Markdown editor"
    $shortcut.IconLocation = $Executable + ",0"
    $shortcut.Save()

    $uninstallPath = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\OmaWriteWindows"
    New-Item -Path $uninstallPath -Force | Out-Null
    New-ItemProperty -LiteralPath $uninstallPath -Name "DisplayName" `
        -Value $registeredAppName -PropertyType String -Force | Out-Null
    New-ItemProperty -LiteralPath $uninstallPath -Name "DisplayIcon" `
        -Value $Executable -PropertyType String -Force | Out-Null
    New-ItemProperty -LiteralPath $uninstallPath -Name "Publisher" `
        -Value "OmaWrite contributors" -PropertyType String -Force | Out-Null
    New-ItemProperty -LiteralPath $uninstallPath -Name "InstallLocation" `
        -Value $installDirectory -PropertyType String -Force | Out-Null
    New-ItemProperty -LiteralPath $uninstallPath -Name "UninstallString" `
        -Value ('"' + (Join-Path $installDirectory "uninstall-windows.cmd") + '"') `
        -PropertyType String -Force | Out-Null
    New-ItemProperty -LiteralPath $uninstallPath -Name "NoModify" `
        -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -LiteralPath $uninstallPath -Name "NoRepair" `
        -Value 1 -PropertyType DWord -Force | Out-Null
}

try {
    Assert-ManagedPath -Path $installDirectory
    Assert-ManagedPath -Path $stagingDirectory
    $packageRoot = Resolve-PackageRoot

    $installedExecutable = Join-Path $installDirectory "omawrite.exe"
    $runningInstalledApp = @(Get-Process -Name "omawrite" -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -eq $installedExecutable
    })
    if ($runningInstalledApp.Count -gt 0) {
        throw "Close OmaWrite before installing or updating it."
    }

    if (Test-Path -LiteralPath $stagingDirectory) {
        Remove-Item -LiteralPath $stagingDirectory -Recurse -Force
    }
    New-Item -ItemType Directory -Path $stagingDirectory | Out-Null
    Copy-Item -Path (Join-Path $packageRoot "*") `
        -Destination $stagingDirectory -Recurse -Force

    if (Test-Path -LiteralPath $installDirectory) {
        Remove-Item -LiteralPath $installDirectory -Recurse -Force
    }
    Move-Item -LiteralPath $stagingDirectory -Destination $installDirectory

    $executable = Join-Path $installDirectory "omawrite.exe"
    if (-not (Test-Path -LiteralPath $executable)) {
        throw "The installed executable is missing."
    }

    $runtimePath = Join-Path $env:SystemRoot "System32\vcruntime140_1.dll"
    $runtimeInstaller = Join-Path $installDirectory "vc_redist.x64.exe"
    if (-not (Test-Path -LiteralPath $runtimePath) -and
        (Test-Path -LiteralPath $runtimeInstaller)) {
        Write-Host "Installing the required Microsoft Visual C++ runtime..."
        $runtimeProcess = Start-Process -FilePath $runtimeInstaller `
            -ArgumentList "/install", "/passive", "/norestart" -Wait -PassThru
        if ($runtimeProcess.ExitCode -notin @(0, 1638, 3010)) {
            throw "Visual C++ runtime installation failed with code $($runtimeProcess.ExitCode)."
        }
    }

    Set-DefaultAppRegistration -Executable $executable
    Set-InstalledAppRegistration -Executable $executable

    if (-not ("OmaWriteShellNotify" -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class OmaWriteShellNotify {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(
        uint eventId, uint flags, IntPtr item1, IntPtr item2);
}
'@
    }
    [OmaWriteShellNotify]::SHChangeNotify(
        0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)

    if (-not $NoLaunch) {
        Start-Process -FilePath $executable
    }
    if (-not $SkipDefaultAppsPage) {
        $escapedName = [Uri]::EscapeDataString($registeredAppName)
        Start-Process "ms-settings:defaultapps?registeredAppUser=$escapedName"
    }

    Write-Host "OmaWrite is installed at $installDirectory"
} finally {
    if ($temporaryDirectory -and (Test-Path -LiteralPath $temporaryDirectory)) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}
