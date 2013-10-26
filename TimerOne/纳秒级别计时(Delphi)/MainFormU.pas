unit MainFormU;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TMainForm = class(TForm)
    btn1: TButton;
    btn2: TButton;
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  starttime, endtime : Int64;
  m_startcycle,m_overhead: Int64;

implementation

{$R *.dfm}
procedure HiPerfTimer();
var frag:Int64;
  sztitle:string;
  szCaption:string;
begin
  starttime:=0;
  endtime:=0;
  if not (QueryPerformanceFrequency(frag)) then
  begin
    sztitle:='��ʾ';
    szCaption:='CPU��������ԭ��֧�ָ����ܼ�����...';
    asm
    PUSH MB_OK+MB_ICONSTOP
    PUSH sztitle
    PUSH szCaption
    PUSH 0
    CALL MessageBox
    end;
  end;
end;
procedure APITest();
var
 consequence:Int64;
 r:double;

begin
     QueryPerformanceFrequency(consequence);
     QueryPerformanceCounter(starttime);
     Sleep(1000);
     QueryPerformanceCounter(endtime);
     r:=(endtime-starttime)/consequence;
     ShowMessage(floattostr(r));
end;

procedure TMainForm.btn1Click(Sender: TObject);
begin
HiPerfTimer;
APITest;
end;

{ �����ǻ��ģʽ���� }
function GetCycleCount():Int64;
begin
asm
  db 0fh
  db 31h
end;
end;

function Stop():Int64;
begin
   result:=GetCycleCount()-m_startcycle-m_overhead;
end;

procedure Start();
begin
  m_startcycle:=GetCycleCount();
end;

procedure TMainForm.btn2Click(Sender: TObject);
var
  cpuspeed10,time1:Int64;
  r:double;
  sztitle:string;
  szCaption:string;
begin

  sztitle:='��ʾ';
  szCaption:='���ڶ����CPU��Ƶ�Լ�ʱ�����ڵ�һЩԭ�������������׼ȷ��������Ҳû�������������ô������ܵõ��롭��';
  asm
  PUSH MB_OK+MB_ICONINformATION
  PUSH sztitle
  PUSH szCaption
  PUSH 0
  CALL MessageBox
  end;

  Start();
  Sleep(1000);
  cpuspeed10:=Round((Stop()/100000));
  Start();
  Sleep(1000);
  time1:=Stop();
  r:=time1*10000/cpuspeed10;
  ShowMessage(floattostr(r));
end;

end.
