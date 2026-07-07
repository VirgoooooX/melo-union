#define MyAppName "MeloUnion"
#ifndef AppVersion
  #define MyAppVersion "0.1.0"
#else
  #define MyAppVersion AppVersion
#endif
#ifndef OutputBaseFilename
  #define MyOutputBaseFilename "MeloUnion-Windows-Setup"
#else
  #define MyOutputBaseFilename OutputBaseFilename
#endif
#define MyAppPublisher "MeloUnion"
#define MyAppExeName "MeloUnion.exe"

[Setup]
AppId={{7F0FA3C5-18A7-4638-B5C6-38F76F6D97CE}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
; OutputDir is relative to the directory of this script, so ".." resolves to the repository root.
OutputDir=..
OutputBaseFilename={#MyOutputBaseFilename}
SetupIconFile=..\app\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\app\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
