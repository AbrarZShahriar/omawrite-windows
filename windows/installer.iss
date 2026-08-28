#define PackageDir GetEnv("OMAWRITE_PACKAGE_DIR")
#define ReleaseVersion GetEnv("OMAWRITE_RELEASE_VERSION")

#if PackageDir == ""
  #error OMAWRITE_PACKAGE_DIR is not set
#endif

#if ReleaseVersion == ""
  #error OMAWRITE_RELEASE_VERSION is not set
#endif

[Setup]
AppId={{AE6883F4-1FC1-44FE-BE70-362A97A57B86}
AppName=OmaWrite for Windows
AppVersion={#ReleaseVersion}
AppVerName=OmaWrite for Windows {#ReleaseVersion}
AppPublisher=OmaWrite contributors
AppPublisherURL=https://github.com/AbrarZShahriar/omawrite-windows
AppSupportURL=https://github.com/AbrarZShahriar/omawrite-windows/issues
AppUpdatesURL=https://github.com/AbrarZShahriar/omawrite-windows/releases/latest
DefaultDirName={localappdata}\Programs\OmaWrite
DefaultGroupName=OmaWrite for Windows
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
SetupArchitecture=x64
ChangesAssociations=yes
CloseApplications=yes
RestartApplications=no
WizardStyle=modern
Compression=lzma2/ultra64
SolidCompression=yes
SetupIconFile=..\pkgbuild\omawrite.ico
UninstallDisplayIcon={app}\omawrite.exe
LicenseFile=..\LICENSE
OutputBaseFilename=OmaWrite-Windows-Setup-x64
VersionInfoVersion=0.5.0.1
VersionInfoDescription=OmaWrite for Windows Setup
VersionInfoCompany=OmaWrite contributors
VersionInfoCopyright=Copyright (c) OmaWrite contributors

[Files]
Source: "{#PackageDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\OmaWrite for Windows"; Filename: "{app}\omawrite.exe"; WorkingDir: "{app}"

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\OmaWriteWindows"; Flags: deletekey
Root: HKCU; Subkey: "Software\Classes\OmaWrite.Markdown"; ValueType: string; ValueName: ""; ValueData: "Markdown Document"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\OmaWrite.Markdown\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\omawrite.exe,0"
Root: HKCU; Subkey: "Software\Classes\OmaWrite.Markdown\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\omawrite.exe"" ""%1"""
Root: HKCU; Subkey: "Software\Classes\Applications\omawrite.exe"; ValueType: string; ValueName: "FriendlyAppName"; ValueData: "OmaWrite for Windows"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\Applications\omawrite.exe\SupportedTypes"; ValueType: string; ValueName: ".md"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\Applications\omawrite.exe\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\omawrite.exe"" ""%1"""
Root: HKCU; Subkey: "Software\Classes\.md\OpenWithProgids"; ValueType: string; ValueName: "OmaWrite.Markdown"; ValueData: ""; Flags: uninsdeletevalue uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\OmaWriteWindows\Capabilities"; ValueType: string; ValueName: "ApplicationName"; ValueData: "OmaWrite for Windows"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\OmaWriteWindows\Capabilities"; ValueType: string; ValueName: "ApplicationDescription"; ValueData: "A focused native Markdown writing app."
Root: HKCU; Subkey: "Software\OmaWriteWindows\Capabilities\FileAssociations"; ValueType: string; ValueName: ".md"; ValueData: "OmaWrite.Markdown"
Root: HKCU; Subkey: "Software\RegisteredApplications"; ValueType: string; ValueName: "OmaWrite for Windows"; ValueData: "Software\OmaWriteWindows\Capabilities"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.md\OpenWithProgids"; ValueType: string; ValueName: "OmaWrite.Markdown"; ValueData: ""; Flags: uninsdeletevalue uninsdeletekeyifempty

[Run]
Filename: "{app}\vc_redist.x64.exe"; Parameters: "/install /passive /norestart"; StatusMsg: "Installing the Microsoft Visual C++ runtime..."; Check: VCRuntimeNeeded; Flags: waituntilterminated
Filename: "{app}\omawrite.exe"; Description: "Launch OmaWrite"; Flags: nowait postinstall skipifsilent
Filename: "ms-settings:defaultapps?registeredAppUser=OmaWrite%20for%20Windows"; Description: "Choose OmaWrite for Markdown files"; Flags: shellexec nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
function VCRuntimeNeeded: Boolean;
begin
  Result := not FileExists(ExpandConstant('{sys}\vcruntime140_1.dll'));
end;
