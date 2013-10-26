unit JudgeFormU;

interface

uses
  Windows, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, msxmldom, XMLDoc, GIFImg,
  ExtCtrls, SysUtils,Math,TlHelp32, xmldom, XMLIntf,Messages;

type
  TJudgeForm = class(TForm)
    btn1: TButton;
    btn2: TButton;
    lbl6: TLabel;
    lbl4: TLabel;
    pb1: TProgressBar;
    pb2: TProgressBar;
    pb3: TProgressBar;
    lbl1: TLabel;
    lbl2: TLabel;
    lbl3: TLabel;
    lbl5: TLabel;
    redt1: TRichEdit;
    lbl7: TLabel;
    doc: TXMLDocument;
    doc2: TXMLDocument;
    img1: TImage;
    chk1: TCheckBox;
    lbl8: TLabel;
    doc3: TXMLDocument;
    procedure btn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure ThreadTerminate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lbl8Click(Sender: TObject);
    procedure chk1Click(Sender: TObject);
  protected

  private
    { Private declarations }
  public
    { Public declarations }
  end;
var
  JudgeForm: TJudgeForm;
  OnFirstShow:Boolean;
  hJudgeThread:TThread;
var
  //2011��1��3��0:29:53 �����ж�������͸���������Ϣ
  bkPerson:array of string;
  bkCurrent:Integer;
const
  JUDGE_TERMINATE  =   '#'; //������ֹ

implementation
uses JudgeThreadU;

{$R *.dfm}

procedure TJudgeForm.btn1Click(Sender: TObject);
begin
if btn1.Caption='��ͣ' then
begin
btn1.Caption:='����';
hJudgeThread.Suspend;
end else begin
btn1.Caption:='��ͣ';
hJudgeThread.Resume;

end;
end;

procedure TJudgeForm.chk1Click(Sender: TObject);
begin
JudgeFaster:=True;
chk1.Caption:='��������������';
chk1.Width:=100;
chk1.Enabled:=False;
lbl8.Visible:=False;
lbl4.Visible:=False;
lbl6.Top:=45;
TGIFImage(img1.Picture.Graphic).Animate := False;
TGIFImage(img1.Picture.Graphic).AnimationSpeed := 200;
TGIFImage(img1.Picture.Graphic).Animate := True;
end;

procedure TJudgeForm.FormActivate(Sender: TObject);
begin
if OnFirstShow then
begin
 OnFirstShow:=false;
 hJudgeThread.Start;
end;
end;

procedure TJudgeForm.ThreadTerminate(Sender: TObject);
begin
   //ShowMessage('�������������ȷ���˳���');
   try
   doc.Active:=False;
   doc2.Active:=False;
   doc3.Active:=False;
   Application.Terminate;
   except

   end;
end;

procedure SyncToMainForm(DataToSend:string);
var
 WMCOPYDATASTRUCT:TCopyDataStruct;
begin
  WMCOPYDATASTRUCT.cbData:=(Length(DataToSend)+1)*SizeOf(char);
  GetMem(WMCOPYDATASTRUCT.lpData,WMCOPYDATASTRUCT.cbData);
  ZeroMemory(WMCOPYDATASTRUCT.lpData,WMCOPYDATASTRUCT.cbData);
  StrCopy(WMCOPYDATASTRUCT.lpData,PChar(DataToSend));
  SendMessage(CenaMainFormHANDLE,WM_COPYDATA,JudgeForm.Handle,Cardinal(@WMCOPYDATASTRUCT));
  FreeMem(WMCOPYDATASTRUCT.lpData);

end;


procedure TJudgeForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
 k:Integer;
begin

if not hJudgeThread.Finished then
  if MessageBox(Handle, '������δ������ȷ��Ҫȡ�����˳�������', '��ʾ', MB_YESNO + MB_ICONWARNING
    + MB_DEFBUTTON2 + MB_TOPMOST) = IDYES then
  begin
   try
    if not hJudgeThread.Finished then
    begin
      hJudgeThread.Suspend;
    end;
    doc.Active:=False;
    doc2.Active:=False;
    doc3.Active:=False;
    for k:= bkCurrent to Length(bkPerson)-1 do
     SyncToMainForm(JUDGE_TERMINATE+bkPerson[k]);

    Application.Terminate;
    if not hJudgeThread.Finished then
     hJudgeThread.Terminate;

    Application.Terminate;

   except

   end;


  end else
  begin
    Action:=caNone;
  end;
end;

procedure TJudgeForm.FormCreate(Sender: TObject);
var
 ContestPath,XmlFileName,ApplicationName:String;
 CenaMainFormHD:Cardinal;
var
  ProcessAffinity,_SystemAffinity: Cardinal;
  CPUCores:Integer;
var
  ProPhoto:THandle;
  OpenPro:ProcessEntry32;
  BFirst:Boolean;
  InstanceNumner:Integer;
begin
  ContestPath:=Paramstr(1);
  XmlFileName:=Paramstr(2);
  CenaMainFormHD:=FindWindow('CENAEX_FOUNDATION_CLASS',nil);
  if (ContestPath='') OR (XmlFileName='') OR (CenaMainFormHD=0) then
  begin
    MessageBox(Handle, 'Illegal Calling Convention!'+#13#10+'Authorized Calls Only!', 'ERROR', MB_OK + MB_ICONSTOP +
      MB_TOPMOST);
    Halt;
  end;

  JudgeFaster:=False;
  hJudgeThread := TJudgeThread.Create(ContestPath,XmlFileName,CenaMainFormHD);
  hJudgeThread.OnTerminate:=ThreadTerminate;
  hJudgeThread.FreeOnTerminate:=True;
  OnFirstShow:=True;
  TGIFImage(img1.Picture.Graphic).AnimationSpeed := 130;
  TGIFImage(img1.Picture.Graphic).Animate := True;

//==============================================================================
//Set Hard Affinity
//�����Cpu����ģʽ By Martian 2010��12��27��
//==============================================================================

  GetProcessAffinityMask(GetCurrentProcess(),ProcessAffinity,_SystemAffinity);
  CPUCores:=Trunc(Log2(ProcessAffinity+1));
  ProPhoto:=CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
  OpenPro.dwSize:=SizeOf(OpenPro);
  BFirst:=Process32First(ProPhoto,OpenPro);
  InstanceNumner:=0;
  ApplicationName:=UpperCase(Extractfilename(Application.ExeName));
  while BFirst do
  begin
    if UpperCase(OpenPro.szExeFile)=ApplicationName then inc(InstanceNumner);
    BFirst:=Process32Next(ProPhoto,OpenPro);
  end;

  CloseHandle(ProPhoto);
  if InstanceNumner>CPUCores then Application.Terminate; //N����CPU�������N���������
  ProcessAffinity:=1 shl (InstanceNumner-1);
  SetProcessAffinityMask(GetCurrentProcess(),ProcessAffinity);
  lbl7.Hint:='[CPU(����)����'+IntToStr(CPUCores)+'����ǰ������CPU '+IntToStr(InstanceNumner-1)+']';
  lbl7.Caption:=lbl7.Hint;
  JudgeThreadU.InstanceNumner:=IntToStr(InstanceNumner);


end;

procedure TJudgeForm.lbl8Click(Sender: TObject);
begin
if btn1.Caption='��ͣ' then hJudgeThread.Suspend;

MessageBox(Handle, '[��������ģʽ]ΪCena2.0�汾����������ģʽ���������������ѡ�ֳɼ���������ǽ�ѧ�á�' + #13#10 +
  '��������������ⷽʽ����Ҫ����Ϊ��' + #13#10 + 'һ��ȡ���������������ʾ������ȫ��Sleep����' + #13#10 +
  '����һ���������������ʱ�䣬����ǿ�ƽ���������򣬶����ȴ���������ʱ��'+ #13#10 +'PS����������ģʽĿǰ�ڲ��Խ׶Σ�������κ�BUG�뼰ʱ�����Ƿ�����лл��', '��ʾ', MB_OK + MB_ICONQUESTION +
  MB_TOPMOST);

if btn1.Caption='��ͣ' then hJudgeThread.Resume;
end;

end.
