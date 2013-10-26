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
  //2011年1月3日0:29:53 用于中断任务后发送给主窗口消息
  bkPerson:array of string;
  bkCurrent:Integer;
const
  JUDGE_TERMINATE  =   '#'; //评测终止

implementation
uses JudgeThreadU;

{$R *.dfm}

procedure TJudgeForm.btn1Click(Sender: TObject);
begin
if btn1.Caption='暂停' then
begin
btn1.Caption:='继续';
hJudgeThread.Suspend;
end else begin
btn1.Caption:='暂停';
hJudgeThread.Resume;

end;
end;

procedure TJudgeForm.chk1Click(Sender: TObject);
begin
JudgeFaster:=True;
chk1.Caption:='已启动快速评测';
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
   //ShowMessage('评测结束。单击确定退出。');
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
  if MessageBox(Handle, '评测尚未结束，确定要取消并退出评测吗？', '提示', MB_YESNO + MB_ICONWARNING
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
//多核心Cpu评测模式 By Martian 2010年12月27日
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
  if InstanceNumner>CPUCores then Application.Terminate; //N核心CPU最多运行N个评测进程
  ProcessAffinity:=1 shl (InstanceNumner-1);
  SetProcessAffinityMask(GetCurrentProcess(),ProcessAffinity);
  lbl7.Hint:='[CPU(核心)数：'+IntToStr(CPUCores)+'，当前运行在CPU '+IntToStr(InstanceNumner-1)+']';
  lbl7.Caption:=lbl7.Hint;
  JudgeThreadU.InstanceNumner:=IntToStr(InstanceNumner);


end;

procedure TJudgeForm.lbl8Click(Sender: TObject);
begin
if btn1.Caption='暂停' then hJudgeThread.Suspend;

MessageBox(Handle, '[快速评测模式]为Cena2.0版本新增的评测模式，适用于评测大量选手成绩或比赛而非教学用。' + #13#10 +
  '相对于正常的评测方式，主要区别为：' + #13#10 + '一、取消部分输出文字提示、禁用全部Sleep代码' + #13#10 +
  '二、一旦超过评测点限制时间，立刻强制结束待测程序，而不等待两倍评测时间'+ #13#10 +'PS：快速评测模式目前在测试阶段，如果有任何BUG请及时向我们反馈。谢谢！', '提示', MB_OK + MB_ICONQUESTION +
  MB_TOPMOST);

if btn1.Caption='暂停' then hJudgeThread.Resume;
end;

end.
