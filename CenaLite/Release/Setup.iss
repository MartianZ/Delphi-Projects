#define MyAppName "CenaLite"
#define MyAppVerName "CenaLite - 0.1"
#define MyAppPublisher "Project-Cena2"
#define MyAppURL "http://www.cena2.org"
#define MyAppExeName "CenaLite.exe"

[Setup]
; 注: AppId的值为单独标识该应用程序。
; 不要为其他安装程序使用相同的AppId值。
; (生成新的GUID，点击 工具|在IDE中生成GUID。)
AppId={{C7DF1AE5-A3CE-4E3C-BC96-A0CC91F263A2}
AppName={#MyAppName}
AppVerName={#MyAppVerName}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\\Cena2\CenaLite
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=E:\CenaLite\SetupRelease
OutputBaseFilename=CenaLite - Setup
WizardImageFile=E:\CenaLite\CenaLite\ArtWork\temp4.bmp
WizardSmallImageFile=compiler:WizModernSmallImage-IS.bmp
SetupIconFile=E:\CenaLite\CenaLite\ArtWork\cl.ico
Compression=lzma/ultra64
SolidCompression=yes

[Languages]
Name: "chinesesimp"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}";
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "E:\CenaLite\Release\CenaLite.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "E:\CenaLite\Release\Compilers\*"; DestDir: "{app}\Compilers"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "E:\CenaLite\Release\Modules\*"; DestDir: "{app}\Modules"; Flags: ignoreversion recursesubdirs createallsubdirs
; 注意: 不要在任何共享系统文件上使用“Flags: ignoreversion”

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{group}\CenaLite 官方网站"; Filename: "{#MyAppURL}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; WorkingDir: "{app}";
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon; WorkingDir: "{app}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

[Code]
var
   is_value: integer;
function InitializeSetup(): Boolean;
begin
   Result :=true;
   is_value:=FindWindowByClassName('TMainForm');
  while is_value<>0 do
  begin
     if Msgbox('安装程序检测到CenaLite当前正在运行。'   #13#13 '您必须先关闭它然后单击“是”继续安装，或按“否”退出！', mbConfirmation, MB_YESNO) = idNO then
      begin
        Result :=false; //安装程序退出
        is_value :=0;
      end else begin
        Result :=true;  //安装程序继续
        is_value:=FindWindowByClassName('TMainForm');
      end;
  end;
end;
procedure URLLabelOnClick(Sender: TObject);
var
ErrorCode: Integer;
begin
ShellExec('open', 'http://www.cena2.org', '', '', SW_SHOW, ewNoWait, ErrorCode)
end;



procedure InitializeWizard();
var
  LabelDate: Tlabel;
  URLLabel: TNewStaticText;
begin
  WizardForm.WelcomeLabel2.Autosize := true;
  LabelDate := TLabel.Create(WizardForm);
  LabelDate.Autosize := true;
  LabelDate.Caption := 'CenaLite是一款供个人练习使用的简易的评测软件'#13#10#13#10'Cena2开源项目的重要分支，基于GPL协议开放源代码。'#13#10#13#10'更多信息请访问： http://www.cena2.org';
  LabelDate.Parent := WizardForm.WelcomePage;
  LabelDate.Left := WizardForm.WelcomeLabel2.Left;
  LabelDate.Top := WizardForm.WelcomeLabel2.Top +WizardForm.WelcomeLabel2.Height +80;

  URLLabel := TNewStaticText.Create(WizardForm);
  URLLabel.Top := WizardForm.CancelButton.Top + WizardForm.CancelButton.Height - URLLabel.Height - 2;
  URLLabel.Left := 20;
  URLLabel.Caption := 'http://www.cena2.org';
  URLLabel.Font.Style := [fsUnderline];
  URLLabel.Font.Color := clBlue;
  URLLabel.Cursor := crHand;
  URLLabel.OnClick := @URLLabelOnClick;
  URLLabel.Font.Name := '宋体';
  URLLabel.Font.Height := ScaleY(-13);
  URLLabel.Parent := WizardForm;
  URLLabel.Hint := '点击打开官方网站 Cena2.org';
  URLLabel.ShowHint := True;
end;

function InitializeUninstall(): Boolean;
begin
   is_value:=FindWindowByClassName('TMainForm');
   if is_value<>0 then begin
    MsgBox('卸载程序检测到CenaLite当前正在运行。' #13#13 '为了更安全完整的卸载，您必须关闭它再进行卸载操作！', mbError, MB_OK);
    Result :=false;
   end else Result :=true;
end;





