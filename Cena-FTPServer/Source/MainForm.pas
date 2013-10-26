unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IdBaseComponent, IdComponent, IdCustomTCPServer,
  IdTCPServer, IdCmdTCPServer, IdExplicitTLSClientServerBase, IdFTPServer,IdFTPListOutput,IdFTPList,
  IdIPWatch,
  My_SelectDir, IdContext;

type
  TFTPServer = class(TForm)
    edt1: TEdit;
    lbl1: TLabel;
    btn1: TButton;
    lbl2: TLabel;
    edt2: TEdit;
    grp1: TGroupBox;
    rb1: TRadioButton;
    lbl3: TLabel;
    rb2: TRadioButton;
    lbl4: TLabel;
    rb3: TRadioButton;
    lbl5: TLabel;
    rb4: TRadioButton;
    lbl6: TLabel;
    lbl7: TLabel;
    btn2: TButton;
    btn3: TButton;
    lbl8: TLabel;
    idftpsrvr1: TIdFTPServer;
    idpwtch1: TIdIPWatch;
    procedure idftpsrvr1ListDirectory(ASender: TIdFTPServerContext;
      const APath: string; ADirectoryListing: TIdFTPListOutput; const ACmd,
      ASwitches: string);
    procedure btn2Click(Sender: TObject);
    procedure edt2KeyPress(Sender: TObject; var Key: Char);
    procedure idftpsrvr1ChangeDirectory(ASender: TIdFTPServerContext;
      var VDirectory: string);
    procedure idftpsrvr1DeleteFile(ASender: TIdFTPServerContext;
      const APathName: string);
    procedure idftpsrvr1RenameFile(ASender: TIdFTPServerContext;
      const ARenameFromFile, ARenameToFile: string);
    procedure idftpsrvr1StoreFile(ASender: TIdFTPServerContext;
      const AFileName: string; AAppend: Boolean; var VStream: TStream);
    procedure idftpsrvr1RetrieveFile(ASender: TIdFTPServerContext;
      const AFileName: string; var VStream: TStream);
    procedure idftpsrvr1MakeDirectory(ASender: TIdFTPServerContext;
      var VDirectory: string);
    procedure idftpsrvr1RemoveDirectory(ASender: TIdFTPServerContext;
      var VDirectory: string);
    procedure idftpsrvr1UserLogin(ASender: TIdFTPServerContext; const AUsername,
      APassword: string; var AAuthenticated: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btn3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FTPServer: TFTPServer;
  AppDir: String;
implementation

{$R *.dfm}
function ReplaceChars(APath:String):String;
var
 s:string;
begin
  s := StringReplace(APath, '/', '\', [rfReplaceAll]);
  s := StringReplace(s, '\\', '\', [rfReplaceAll]);
  Result := s;
end;

procedure TFTPServer.btn1Click(Sender: TObject);
const
 SELDIRHELP=100;
var
 Dir:string;
begin
  if SelectDir(FTPServer.Handle,'','请选择FTP Server根目录：','',Dir) then
   edt1.Text:=Dir;

end;


procedure TFTPServer.btn2Click(Sender: TObject);
begin
if btn2.Caption='停止服务' then
begin
  edt1.Enabled:=true;
  edt2.Enabled:=true;
  btn1.Enabled:=true;
  lbl8.Caption:='服务已停止。';
  btn2.Caption:='运行服务';
  try
  idftpsrvr1.Active:=false;
  except

  end;
  Exit;

end;

if edt1.Text='' then
begin
  MessageBox(Handle, '请选择FTP服务器根目录', '提示', MB_OK + MB_ICONWARNING);
  Exit;
end;
if edt2.Text='' then
begin
  MessageBox(Handle, '请输入正确的FTP服务器端口', '提示', MB_OK + MB_ICONWARNING);
  Exit;
end;
if not ((rb1.Checked)or(rb2.Checked)or(rb3.Checked)or(rb4.Checked)) then
begin
 MessageBox(Handle, '请至少选择一个模式后再运行FTP服务器。', '提示', MB_OK + MB_ICONWARNING);
 Exit;
end;
AppDir:=edt1.Text;
idftpsrvr1.AllowAnonymousLogin:=True;
idftpsrvr1.DefaultPort:=StrToInt(edt2.Text);
idftpsrvr1.Active:=True;
lbl8.Caption:='FTP Server正在运行中……';
btn2.Caption:='停止服务';
  edt1.Enabled:=false;
  edt2.Enabled:=false;
  btn1.Enabled:=false;
end;

procedure TFTPServer.btn3Click(Sender: TObject);
begin

try
  idftpsrvr1.Active:=false;
finally
  halt;
end;

end;

procedure TFTPServer.edt2KeyPress(Sender: TObject; var Key: Char);
begin
if Not (Key In ['0'..'9',#8]) then Key:=#0;
end;

procedure TFTPServer.FormCreate(Sender: TObject);
begin
lbl7.Caption:=lbl7.Caption+idpwtch1.LocalIP;
end;

procedure TFTPServer.idftpsrvr1ChangeDirectory(ASender: TIdFTPServerContext;
  var VDirectory: string);
begin
ASender.CurrentDir := VDirectory;
end;

procedure TFTPServer.idftpsrvr1DeleteFile(ASender: TIdFTPServerContext;
  const APathName: string);
begin
  if rb4.Checked then
    DeleteFile(ReplaceChars(AppDir+ASender.CurrentDir+'\'+APathname));
end;

function IsValidDir(SearchRec:TSearchRec):Boolean;
begin
{ TODO : 文件类型为[16,31]和48,49,2064,2096的都是文件夹既目录 }
if ( ((SearchRec.Attr>=16)and(SearchRec.Attr<=31))       or
       (SearchRec.Attr=48)    or   (SearchRec.Attr=49)     or
       (SearchRec.Attr=50)    or   (SearchRec.Attr=2064)   or
       (SearchRec.Attr=2066) or   (SearchRec.Attr=2096)   or
       (SearchRec.Attr=2098) or   (SearchRec.Attr=8208)   or
       (SearchRec.Attr=8210) or   (SearchRec.Attr=8240)   or
       (SearchRec.Attr=8242) or   (SearchRec.Attr=10256) or
       (SearchRec.Attr=10258) or   (SearchRec.Attr=10288) or
       (SearchRec.Attr=10290) or   (SearchRec.Attr=16400) or
       (SearchRec.Attr=16402) or   (SearchRec.Attr=16432) or
       (SearchRec.Attr=16434) or   (SearchRec.Attr=24624) or
       (SearchRec.Attr=24626) or   (SearchRec.Attr=1243048) ) and
     ( SearchRec.Name<>'.' ) and (SearchRec.Name<>'..' )
then Result:=True else Result:=False;
end;

procedure TFTPServer.idftpsrvr1ListDirectory(ASender: TIdFTPServerContext;
  const APath: string; ADirectoryListing: TIdFTPListOutput; const ACmd,
  ASwitches: string);
var
 LFTPItem :TIdFTPListItem;
 SR : TSearchRec;
 SRI : Integer;
 FileExt:String;
begin
  ADirectoryListing.DirFormat := doUnix;
  SRI := FindFirst(AppDir + APath + '\*.*', faAnyFile - faHidden - faSysFile, SR);
  While SRI = 0 do
  begin
    FileExt:=UpperCase(ExtractFileExt(SR.Name));
    if rb1.Checked then
    begin
      if not ((FileExt='.PDF')or(FileExt='.DOC')or(FileExt='.DOCX')or(FileExt='.ZIP')or(FileExt='.RAR')) then
      begin
        SRI := FindNext(SR);
        Continue;
      end;
    end;
    if rb2.Checked then
    begin
      if ((FileExt='.PDF')or(FileExt='.DOC')or(FileExt='.DOCX')or(FileExt='.ZIP')or(FileExt='.RAR')or(FileExt='.IN')or(FileExt='.OUT')) then
      begin
        SRI := FindNext(SR);
        Continue;
      end;
    end;
    LFTPItem := ADirectoryListing.Add;
    LFTPItem.FileName := SR.Name;
    LFTPItem.Size := SR.Size;
    LFTPItem.ModifiedDate := FileDateToDateTime(SR.Time);
    if IsValidDir(SR) then
     LFTPItem.ItemType := ditDirectory
    else
     LFTPItem.ItemType := ditFile;
    SRI := FindNext(SR);
  end;
  FindClose(SR);
  SetCurrentDir(AppDir + APath + '\..');
end;

procedure TFTPServer.idftpsrvr1MakeDirectory(ASender: TIdFTPServerContext;
  var VDirectory: string);
begin
 if (rb2.Checked)or(rb4.Checked) then
  if not ForceDirectories(ReplaceChars(AppDir + VDirectory)) then
  begin
    Raise Exception.Create('Unable to create directory');
  end;
end;
procedure DeleteDir(sDirectory: String);
  //删除目录和目录下的所有文件和文件夹
var
    sr:TSearchRec;
    sPath,sFile: String;
begin
    //检查目录名后面是否有   '\'
    if Copy(sDirectory,Length(sDirectory),1)   <>   '\'   then
    sPath:= sDirectory+'\'
    else
    sPath:=sDirectory;
    if FindFirst(sPath+'*.*',faAnyFile,sr) = 0 then
    begin
        repeat
            sFile:=Trim(sr.Name);
            if sFile='.' then Continue;
            if sFile='..' then Continue;
            sFile:=sPath+sr.Name;
            if (sr.Attr and  faDirectory)<>0   then
              DeleteDir(sFile)
            else  if  (sr.Attr and faAnyFile) = sr.Attr   then
              DeleteFile(sFile); //删除文件
        until FindNext(sr) <> 0;
        FindClose(sr);
    end;
    RemoveDir(sPath);
end;
procedure TFTPServer.idftpsrvr1RemoveDirectory(ASender: TIdFTPServerContext;
  var VDirectory: string);
Var
 LFile : String;
begin
  LFile := ReplaceChars(AppDir + VDirectory);
  if rb4.Checked then DeleteDir(LFile);
end;

procedure TFTPServer.idftpsrvr1RenameFile(ASender: TIdFTPServerContext;
  const ARenameFromFile, ARenameToFile: string);
begin
if rb4.Checked then
    RenameFile(ReplaceChars(AppDir+ASender.CurrentDir+'\'+ARenameFromFile),ReplaceChars(AppDir+ASender.CurrentDir+'\'+ARenameToFile));
end;

procedure TFTPServer.idftpsrvr1RetrieveFile(ASender: TIdFTPServerContext;
  const AFileName: string; var VStream: TStream);
var
 FileExt:String;
begin
FileExt:=UpperCase(ExtractFileExt(AFileName));
if (rb1.Checked) then
if ((FileExt='.PDF')or(FileExt='.DOC')or(FileExt='.DOCX')or(FileExt='.ZIP')or(FileExt='.RAR')) then
VStream := TFileStream.Create(ReplaceChars(AppDir+AFilename),fmOpenRead);

if (rb4.Checked)or(rb3.Checked) then
VStream := TFileStream.Create(ReplaceChars(AppDir+AFilename),fmOpenRead);
end;

procedure TFTPServer.idftpsrvr1StoreFile(ASender: TIdFTPServerContext;
  const AFileName: string; AAppend: Boolean; var VStream: TStream);
begin
 if rb2.Checked then
 if FileExists(ReplaceChars(AppDir+AFilename)) then exit
 else
 if not Aappend then VStream := TFileStream.Create(ReplaceChars(AppDir+AFilename),fmCreate);

 if rb4.Checked then
 if not Aappend then
   VStream := TFileStream.Create(ReplaceChars(AppDir+AFilename),fmCreate)
 else
   VStream := TFileStream.Create(ReplaceChars(AppDir+AFilename),fmOpenWrite)
   //VStream := TFileStream.Create(ReplaceChars(AppDir+AFilename),fmOpenWrite)
end;

procedure TFTPServer.idftpsrvr1UserLogin(ASender: TIdFTPServerContext;
  const AUsername, APassword: string; var AAuthenticated: Boolean);
begin
AAuthenticated := True;
end;

end.
