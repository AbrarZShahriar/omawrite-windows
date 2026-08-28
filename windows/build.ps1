[CmdletBinding()]
param(
    [string]$Version = "dev",
    [string]$QtRoot = "",
    [string]$InnoSetupRoot = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$toolsDirectory = Join-Path $root ".tools"
$qtDirectory = Join-Path $toolsDirectory "Qt"
$useSuppliedQt = [bool]$QtRoot
if ($useSuppliedQt) {
    $qtInstallRoot = [IO.Path]::GetFullPath($QtRoot)
} else {
    $qtInstallRoot = Join-Path $qtDirectory "6.8.3\msvc2022_64"
}
$qmake = Join-Path $qtInstallRoot "bin\qmake.exe"
$aqt = Join-Path $toolsDirectory "aqt_x64.exe"
$aqtUri = "https://github.com/miurahr/aqtinstall/releases/download/v3.3.0/aqt_x64.exe"
$aqtHash = "4f74d4c95c464d238d7e17ec2d9b7f22a7c333f0f5270a62584e2b47fc765150"
$innoDirectory = if ($InnoSetupRoot) {
    [IO.Path]::GetFullPath($InnoSetupRoot)
} else {
    Join-Path $toolsDirectory "InnoSetup"
}
$innoCompiler = Join-Path $innoDirectory "ISCC.exe"
$innoInstaller = Join-Path $toolsDirectory "innosetup-7.1.0-x64.exe"
$innoUri = "https://github.com/jrsoftware/issrc/releases/download/is-7_1_0/innosetup-7.1.0-x64.exe"
$innoHash = "0362a383ed217d4c4239b5933866dd96d3eb2102737da92f80f6057a4b40df2f"
$buildRoot = Join-Path $root ".build\windows"
$appBuild = Join-Path $buildRoot "app"
$testBuild = Join-Path $buildRoot "tests"
$distDirectory = Join-Path $root "dist"
$safeVersion = [regex]::Replace($Version, '[^A-Za-z0-9._-]', '-')
$packageName = "OmaWrite-Windows-$safeVersion-x64-portable"
$packageDirectory = Join-Path $distDirectory $packageName
$packageZip = Join-Path $distDirectory ($packageName + ".zip")
$setupName = "OmaWrite-Windows-$safeVersion-x64-Setup"
$setupExecutable = Join-Path $distDirectory ($setupName + ".exe")

function Reset-ChildDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExpectedParent
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    $parentPrefix = [IO.Path]::GetFullPath($ExpectedParent).TrimEnd('\') + '\'
    if (-not $fullPath.StartsWith($parentPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to reset a path outside $ExpectedParent"
    }
    if (Test-Path -LiteralPath $fullPath) {
        Remove-Item -LiteralPath $fullPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
}

function Invoke-DeveloperCommand {
    param([Parameter(Mandatory = $true)][string]$Command)

    $line = 'call "' + $script:vsDevCmd +
        '" -arch=x64 -host_arch=x64 && ' + $Command
    & cmd.exe /d /s /c $line
    if ($LASTEXITCODE -ne 0) {
        throw "Native build command failed with code $LASTEXITCODE."
    }
}

New-Item -ItemType Directory -Path $toolsDirectory -Force | Out-Null
if (-not (Test-Path -LiteralPath $qmake)) {
    if ($useSuppliedQt) {
        throw "qmake.exe was not found under the supplied Qt root: $qtInstallRoot"
    }
    if (-not (Test-Path -LiteralPath $aqt)) {
        Invoke-WebRequest -UseBasicParsing -Uri $aqtUri -OutFile $aqt
    }
    $actualAqtHash = (Get-FileHash -LiteralPath $aqt -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualAqtHash -ne $aqtHash) {
        throw "The aqt installer checksum does not match."
    }

    & $aqt install-qt windows desktop 6.8.3 win64_msvc2022_64 `
        --outputdir $qtDirectory
    if ($LASTEXITCODE -ne 0) {
        throw "Qt installation failed with code $LASTEXITCODE."
    }
}

if (-not (Test-Path -LiteralPath $innoCompiler)) {
    if ($InnoSetupRoot) {
        throw "ISCC.exe was not found under the supplied Inno Setup root: $innoDirectory"
    }
    if (-not (Test-Path -LiteralPath $innoInstaller)) {
        Invoke-WebRequest -UseBasicParsing -Uri $innoUri -OutFile $innoInstaller
    }
    $actualInnoHash = (Get-FileHash -LiteralPath $innoInstaller -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualInnoHash -ne $innoHash) {
        throw "The Inno Setup installer checksum does not match."
    }

    $innoArguments = @(
        "/VERYSILENT",
        "/SUPPRESSMSGBOXES",
        "/NORESTART",
        "/SP-",
        "/CURRENTUSER",
        ('/DIR="{0}"' -f $innoDirectory)
    )
    $innoProcess = Start-Process -FilePath $innoInstaller `
        -ArgumentList $innoArguments -Wait -PassThru
    if ($innoProcess.ExitCode -ne 0 -or
        -not (Test-Path -LiteralPath $innoCompiler)) {
        throw "Inno Setup installation failed with code $($innoProcess.ExitCode)."
    }
}

$vsWhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path -LiteralPath $vsWhere)) {
    throw "Visual Studio Build Tools 2022 with the C++ workload is required."
}
$vsInstall = (& $vsWhere -latest -products * `
    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    -property installationPath).Trim()
if (-not $vsInstall) {
    throw "Visual Studio Build Tools 2022 with the C++ workload is required."
}
$script:vsDevCmd = Join-Path $vsInstall "Common7\Tools\VsDevCmd.bat"

Reset-ChildDirectory -Path $appBuild -ExpectedParent $buildRoot
$appCommand = 'cd /d "' + $appBuild + '" && "' + $qmake +
    '" "' + (Join-Path $root "omawrite.pro") + '" && nmake release'
Invoke-DeveloperCommand -Command $appCommand

Reset-ChildDirectory -Path $testBuild -ExpectedParent $buildRoot
$testCommand = 'cd /d "' + $testBuild + '" && "' + $qmake +
    '" "' + (Join-Path $root "tests\tests.pro") + '" && nmake release'
Invoke-DeveloperCommand -Command $testCommand

$oldPath = $env:Path
$oldPluginPath = $env:QT_PLUGIN_PATH
$oldQmlPath = $env:QML2_IMPORT_PATH
$oldPlatform = $env:QT_QPA_PLATFORM
try {
    $env:Path = (Join-Path $qtInstallRoot "bin") + ";" + $env:Path
    $env:QT_PLUGIN_PATH = Join-Path $qtInstallRoot "plugins"
    $env:QML2_IMPORT_PATH = Join-Path $qtInstallRoot "qml"
    $env:QT_QPA_PLATFORM = "offscreen"
    $testExecutable = Join-Path $testBuild "release\tst_omawrite.exe"
    & $testExecutable -txt
    if ($LASTEXITCODE -ne 0) {
        throw "The test suite failed with code $LASTEXITCODE."
    }
} finally {
    $env:Path = $oldPath
    $env:QT_PLUGIN_PATH = $oldPluginPath
    $env:QML2_IMPORT_PATH = $oldQmlPath
    $env:QT_QPA_PLATFORM = $oldPlatform
}

New-Item -ItemType Directory -Path $distDirectory -Force | Out-Null
Reset-ChildDirectory -Path $packageDirectory -ExpectedParent $distDirectory
Copy-Item -LiteralPath (Join-Path $appBuild "release\omawrite.exe") `
    -Destination $packageDirectory
Copy-Item -LiteralPath (Join-Path $root "LICENSE") `
    -Destination (Join-Path $packageDirectory "LICENSE-omawrite.txt")
Copy-Item -LiteralPath (Join-Path $root "fonts\OFL.txt") `
    -Destination (Join-Path $packageDirectory "LICENSE-font.txt")
Copy-Item -LiteralPath (Join-Path $root "THIRD-PARTY-NOTICES.md") `
    -Destination $packageDirectory
Copy-Item -LiteralPath (Join-Path $root "licenses") `
    -Destination $packageDirectory -Recurse
Copy-Item -LiteralPath (Join-Path $root "README.md") `
    -Destination (Join-Path $packageDirectory "README.md")
Copy-Item -LiteralPath (Join-Path $root "install-windows.cmd") `
    -Destination $packageDirectory
Copy-Item -LiteralPath (Join-Path $root "uninstall-windows.cmd") `
    -Destination $packageDirectory
New-Item -ItemType Directory -Path (Join-Path $packageDirectory "windows") | Out-Null
Copy-Item -LiteralPath (Join-Path $root "windows\install.ps1") `
    -Destination (Join-Path $packageDirectory "windows")
Copy-Item -LiteralPath (Join-Path $root "windows\uninstall.ps1") `
    -Destination (Join-Path $packageDirectory "windows")

$deployTool = Join-Path $qtInstallRoot "bin\windeployqt.exe"
$deployCommand = '"' + $deployTool + '" --release --compiler-runtime ' +
    '--no-translations --qmldir "' + (Join-Path $root "src") + '" "' +
    (Join-Path $packageDirectory "omawrite.exe") + '"'
Invoke-DeveloperCommand -Command $deployCommand

if (Test-Path -LiteralPath $packageZip) {
    Remove-Item -LiteralPath $packageZip -Force
}
Compress-Archive -Path $packageDirectory -DestinationPath $packageZip `
    -CompressionLevel Optimal

if (Test-Path -LiteralPath $setupExecutable) {
    Remove-Item -LiteralPath $setupExecutable -Force
}
$oldPackageDirectory = $env:OMAWRITE_PACKAGE_DIR
$oldReleaseVersion = $env:OMAWRITE_RELEASE_VERSION
try {
    $env:OMAWRITE_PACKAGE_DIR = $packageDirectory
    $env:OMAWRITE_RELEASE_VERSION = $Version
    & $innoCompiler `
        "--output-dir=$distDirectory" `
        "--output-filename=$setupName" `
        (Join-Path $root "windows\installer.iss")
    if ($LASTEXITCODE -ne 0 -or
        -not (Test-Path -LiteralPath $setupExecutable)) {
        throw "Windows Setup compilation failed with code $LASTEXITCODE."
    }
} finally {
    $env:OMAWRITE_PACKAGE_DIR = $oldPackageDirectory
    $env:OMAWRITE_RELEASE_VERSION = $oldReleaseVersion
}

Write-Host "Windows tests passed."
Write-Host "Portable package: $packageZip"
Write-Host "Setup executable: $setupExecutable"
