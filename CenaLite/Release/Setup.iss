#define MyAppName "CenaLite"
#define MyAppVerName "CenaLite - 0.1"
#define MyAppPublisher "Project-Cena2"
#define MyAppURL "http://www.cena2.org"
#define MyAppExeName "CenaLite.exe"

[Setup]
; ע: AppId��ֵΪ������ʶ��Ӧ�ó���
; ��ҪΪ������װ����ʹ����ͬ��AppIdֵ��
; (�����µ�GUID����� ����|��IDE������GUID��)
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
; ע��: ��Ҫ���κι���ϵͳ�ļ���ʹ�á�Flags: ignoreversion��

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{group}\CenaLite �ٷ���վ"; Filename: "{#MyAppURL}"
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
     if Msgbox('��װ�����⵽CenaLite��ǰ�������С�'   #13#13 '�������ȹر���Ȼ�󵥻����ǡ�������װ���򰴡����˳���', mbConfirmation, MB_YESNO) = idNO then
      begin
        Result :=false; //��װ�����˳�
        is_value :=0;
      end else begin
        Result :=true;  //��װ�������
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
  LabelDate.Caption := 'CenaLite��һ�������ϰʹ�õļ��׵��������'#13#10#13#10'Cena2��Դ��Ŀ����Ҫ��֧������GPLЭ�鿪��Դ���롣'#13#10#13#10'������Ϣ����ʣ� http://www.cena2.org';
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
  URLLabel.Font.Name := '����';
  URLLabel.Font.Height := ScaleY(-13);
  URLLabel.Parent := WizardForm;
  URLLabel.Hint := '����򿪹ٷ���վ Cena2.org';
  URLLabel.ShowHint := True;
end;

function InitializeUninstall(): Boolean;
begin
   is_value:=FindWindowByClassName('TMainForm');
   if is_value<>0 then begin
    MsgBox('ж�س����⵽CenaLite��ǰ�������С�' #13#13 'Ϊ�˸���ȫ������ж�أ�������ر����ٽ���ж�ز�����', mbError, MB_OK);
    Result :=false;
   end else Result :=true;
end;





