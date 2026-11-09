#define MyAppName "NoveLib"
#define MyAppPublisher "おかりん研究室"
#define MyAppExeName "NoveLib.exe"
#ifndef MyAppVersion
  #define MyAppVersion "0.46.1"
#endif
#ifndef BuildOutput
  #define BuildOutput "..\app\build\windows\x64\runner\Release"
#endif
#ifndef ReleaseOutput
  #define ReleaseOutput "..\..\releases"
#endif

[Setup]
AppId={{8E2CC3D8-3A6A-4EC1-9C8E-84A2AD8B0B6D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#ReleaseOutput}
OutputBaseFilename=novelib-v{#MyAppVersion}-preview-setup
SetupIconFile=..\app\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
VersionInfoVersion={#MyAppVersion}.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Windows installer
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

[Languages]
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"

[Tasks]
Name: "desktopicon"; Description: "デスクトップにショートカットを作成"; GroupDescription: "追加アイコン:"; Flags: unchecked

[Files]
Source: "{#BuildOutput}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{#MyAppName} をアンインストール"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{#MyAppName} を起動"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeUninstall(): Boolean;
begin
  Result := True;
  if DirExists(ExpandConstant('{userappdata}\NoveLib Project\NoveLib')) then
    MsgBox(
      '作品・評価・プレイ履歴などのユーザーデータはアンインストール後も保持されます。' + #13#10 +
      '削除が必要な場合は、NoveLibの設定画面からバックアップを作成したうえで手動で削除してください。',
      mbInformation,
      MB_OK
    );
end;
