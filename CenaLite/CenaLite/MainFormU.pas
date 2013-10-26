{*******************************************************************************

                CenaLite - Main Library

      File:                 MainFormU.pas
      Created By:           Martian
      Modification Date:    2011-1-17

      Copyright (c) 2010-2011 Project-Cena2

      Project-Cena2 is free software: you can redistribute it and/or modify
      it under the terms of the GNU General Public License as published by
      the Free Software Foundation, either version 3 of the License, or
      (at your option) any later version.

      This program is distributed in the hope that it will be useful,
      but WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
      GNU General Public License for more details.

      You should have received a copy of the GNU General Public License
      along with this program.  If not, see <http://www.gnu.org/licenses/>.

*******************************************************************************}

unit MainFormU;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, ShellAPI, Math, Menus, GIFImg, PerlRegEx,RichEdit,
  OleCtrls, SHDocVw, IdHTTP, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, pngimage,mshtml, ActiveX,ComObj,
  AppEvnts;

type
  TMainForm = class(TForm)
    pgc1: TPageControl;
    ts1: TTabSheet;
    ts2: TTabSheet;
    ts3: TTabSheet;
    ts4: TTabSheet;
    ts5: TTabSheet;
    grp1: TGroupBox;
    lbl1: TLabel;
    img1: TImage;
    status: TStatusBar;
    tmr1: TTimer;
    lbl2: TLabel;
    lbl3: TLabel;
    grp2: TGroupBox;
    lv1: TListView;
    btn1: TButton;
    btn2: TButton;
    btn3: TButton;
    pm1: TPopupMenu;
    N05s1: TMenuItem;
    N10s1: TMenuItem;
    N20s1: TMenuItem;
    N15sC1: TMenuItem;
    redt1: TRichEdit;
    lbl4: TLabel;
    lbl5: TLabel;
    img2: TImage;
    btn5: TButton;
    wb1: TWebBrowser;
    idhtp1: TIdHTTP;
    dlgSave1: TSaveDialog;
    grp3: TGroupBox;
    lbl7: TLabel;
    lbl8: TLabel;
    edt1: TEdit;
    edt2: TEdit;
    btn6: TButton;
    wb2: TWebBrowser;
    aplctnvnts1: TApplicationEvents;
    procedure FormCreate(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure lv1ColumnClick(Sender: TObject; Column: TListColumn);
    procedure btn2Click(Sender: TObject);
    procedure btn3Click(Sender: TObject);
    procedure JudgeMenuClick(Sender: TObject);
    procedure btn5Click(Sender: TObject);
    procedure ThreadTerminate(Sender: TObject);
    procedure pgc1Change(Sender: TObject);
    procedure wb1DocumentComplete(ASender: TObject; const pDisp: IDispatch;
      var URL: OleVariant);
    procedure btn1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btn6Click(Sender: TObject);
    procedure wb2DocumentComplete(ASender: TObject; const pDisp: IDispatch;
      var URL: OleVariant);
    procedure aplctnvnts1Message(var Msg: tagMSG; var Handled: Boolean);
    procedure wb2BeforeNavigate2(ASender: TObject; const pDisp: IDispatch;
      var URL, Flags, TargetFrameName, PostData, Headers: OleVariant;
      var Cancel: WordBool);
    procedure edt2KeyPress(Sender: TObject; var Key: Char);
  private
    procedure WMDropFiles(var Msg: TWMDropFiles; hWnd: HWND);
    { Private declarations }
  public
    { Public declarations }
  end;

type rJudgeConfig = record
  FileType:Byte;
  FilePath:String;
  TimeLimit:Double;
  InputFileName,OutputFileName:string;
  InputFile:array of string;
  OutputFile:array of string;
end;

var
  MainForm: TMainForm;
  GlobalCounter:Byte;
  JudgeConfig:rJudgeConfig;
  m_bSort:Boolean;
  hJudgeThread,hCheckUpdate:TThread;
  HtmlContent,HTMLCompileError:AnsiString;
const
  FILE_C    = 1;
  FILE_CPP = 2;
  FILE_PAS  = 3;

implementation

{$R *.dfm}

uses
 JudgeThreadU,CheckUpdateU;

procedure TMainForm.aplctnvnts1Message(var Msg: tagMSG; var Handled: Boolean);
var
  WMD: TWMDropFiles;
begin
if (Msg.message = WM_RBUTTONDOWN) or (Msg.message = WM_RBUTTONUP) or (Msg.message = WM_RBUTTONDBLCLK)   then
begin
  if (IsChild(wb1.Handle, Msg.hwnd))or(IsChild(wb2.Handle, Msg.hwnd)) then Handled := true;
end else begin
 if Msg.message = WM_DROPFILES then
 begin
    WMD.Msg := Msg.message;
    WMD.Drop := Msg.wParam;

    WMD.Unused := Msg.lParam;
    WMD.Result := 0;
    WMDropFiles(WMD,Msg.hwnd);
    Handled := TRUE;
  end;
end;
end;

procedure TMainForm.btn1Click(Sender: TObject);
begin
pgc1.ActivePageIndex:=4;
pgc1Change(Sender);
end;

procedure TMainForm.btn2Click(Sender: TObject);
begin
lv1.Items.Clear;
btn3.Enabled:=False;
end;

procedure TMainForm.btn3Click(Sender: TObject);
begin
pm1.Popup(Mouse.CursorPos.X,Mouse.CursorPos.Y);
end;


procedure TMainForm.btn5Click(Sender: TObject);
begin

try
  if btn5.Caption='暂停' then
  begin
   hJudgeThread.Suspend;
   TGIFImage(img2.Picture.Graphic).SuspendDraw;
   btn5.Caption:='继续';
  end else
  begin
    TGIFImage(img2.Picture.Graphic).Animate:=False;
    TGIFImage(img2.Picture.Graphic).AnimationSpeed := 130;
    TGIFImage(img2.Picture.Graphic).Animate:=True;
    btn5.Caption:='暂停';
    hJudgeThread.Resume;
  end;

except

end;

end;

procedure TMainForm.btn6Click(Sender: TObject);
begin
if (edt1.Text='')or(edt2.Text='') then
begin
 MessageBoxW(0, '请输入输入、输出文件名！', '错误', MB_OK + MB_ICONSTOP + MB_TOPMOST);
 Exit;
end;

ts2.TabVisible:=True;
ts3.TabVisible:=False;
ts4.TabVisible:=False;
JudgeConfig.InputFileName:=edt1.Text;
JudgeConfig.OutputFileName:=edt2.Text;
pgc1.ActivePageIndex:=1;
status.Panels.Items[0].Text:='提示：输入文件扩展名必须为.in或.in*，输出文件扩展名必须为.an*或.out*';
grp3.Visible:=False;
end;

procedure TMainForm.edt2KeyPress(Sender: TObject; var Key: Char);
begin
if Key=#13 then
  btn6Click(Sender);
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
if Assigned(hJudgeThread) then
  if not hJudgeThread.Finished then hJudgeThread.Terminate;
if Assigned(hCheckUpdate) then
  if not hCheckUpdate.Finished then hCheckUpdate.Terminate;
Application.Terminate;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
DragAcceptFiles(grp1.Handle, True);
DragAcceptFiles(lv1.Handle, True);
hCheckUpdate:=TUpdateThread.Create;

end;

function GetNumbersFromString(s:string):Word;
var
 i:Word;
 temp,ans:string;
begin
 temp:=s;
 for I := 1 to Length(temp) - 1 do
 begin
   if (temp[I] in ['0'..'9'])then
    ans:=ans+temp[I];
 end;
 Result:=(StrToInt(ans));
end;

function GetNumbersFromStringS(s:string):String;
var
 i:Word;
 Ans:string;
begin
 for i := 1 to Length(s) do
 begin
   if (s[i] in ['0'..'9'])then
    ans:=ans+s[i];
 end;
 Result:=ans;
end;

function CustomSortProc(Item1, Item2: TListItem; ParamSort: integer): integer; stdcall;
var txt1,txt2 : string;
begin
  if ParamSort <> 0 then begin
    try
      txt1 := Item1.SubItems.Strings[ParamSort-1];
      txt2 := Item2.SubItems.Strings[ParamSort-1];
    if m_bSort then begin
      Result := CompareValue(GetNumbersFromString(txt1),GetNumbersFromString(txt2));
    end else begin
      Result := -CompareValue(GetNumbersFromString(txt1),GetNumbersFromString(txt2));
    end;
    except
    end;

  end else begin
    if m_bSort then begin
      Result := CompareValue(StrToInt(Item1.Caption),StrToInt(Item2.Caption));
    end else begin
      Result := -CompareValue(StrToInt(Item1.Caption),StrToInt(Item2.Caption));
  end;
  end;
end;

procedure TMainForm.lv1ColumnClick(Sender: TObject; Column: TListColumn);
var
 I:Integer;
begin
  lv1.CustomSort(@CustomSortProc, Column.Index);
  m_bSort:=not m_bSort;
  for i := 0 to lv1.Items.Count - 1 do
    lv1.Items[i].Caption:=IntToStr(i+1);
end;

procedure TMainForm.pgc1Change(Sender: TObject);
begin

if pgc1.ActivePageIndex=4 then
 if not Assigned(wb1.Document) then wb1.Navigate('http://api.cena2.org/CenaLiteHelp.htm');

end;

function GetInputFileName(SourceFile:string):string;
//2011年1月30日13:55:11 增加常量支持
const
  RegEx:array[1..5] of string=('fopen\s*\(\s*\"(.*?)\"\s*,\s*\"r\"\s*\);',
                                'freopen\s*\(\s*\"(.*?)\"\s*,\s*\"r\"\s*,(.*?)\);',
                                'ifstream.*?\(\"(.*?)\"\);',
                                'assign\s*\(\s*input\s*,\s*''(.*?)''\)\s*;\s*',
                                'assign\s*\(\s*input\s*,\s*(.*?)\)\s*;\s*');
                    //我本来想用?<data>这样的来进行分组，不过这个正则库貌似不支持
                    //还是.net给力啊~~~
var
  Reg: TPerlRegEx;
  tFile:TFileStream;
  I:Integer;
  FileLength:Int64;
  Filebuffer:PAnsiChar;
  FileContent:string;
begin

  tFile:=TFileStream.Create(SourceFile,fmOpenRead);
  try
    tFile.Position:=0;
    FileLength:=tFile.Size;
    Getmem(Filebuffer,FileLength*SizeOf(AnsiChar));
    tFile.ReadBuffer(Filebuffer[0],FileLength);
  finally
    tFile.Free;
    FileContent:=String(Filebuffer);
    FreeMem(Filebuffer);
  end;

  Reg:=TPerlRegEx.Create();
  Reg.Options := [preCaseLess];
  Result:='';
  try
    Reg.Subject:=FileContent;
    for I := 1 to 5 do
    begin
      Reg.RegEx:=RegEx[i];
      if not Reg.Match then Continue;
      //if I=3 then Result:=Reg.Groups[2]
      if I=5 then
      begin
         //获得常量
         Reg.RegEx:='const[\s\S]*'+ Reg.Groups[1] +'\s*=\s*''(.*?)''\s*;';
         if Reg.Match then
         begin
          Result:=Reg.Groups[1];
         end;


      end else Result:=Reg.Groups[1];
      Break;
    end;
  finally
    Reg.Free;
  end;
end;
function GetOutputFileName(SourceFile:string):string;
const
  RegEx:array[1..5] of string=('fopen\s*\(\s*\"(.*?)\"\s*,\s*\"w\"\s*\);',
                                'freopen\s*\(\s*\"(.*?)\"\s*,\s*\"w\"\s*,(.*?)\);',
                                'ofstream.*?\(\"(.*?)\"\);',
                                'assign\s*\(\s*output\s*,\s*''(.*?)''\s*\)\s*;',
                                'assign\s*\(\s*output\s*,\s*(.*?)\s*\)\s*;');
var
  Reg: TPerlRegEx;
  tFile:TFileStream;
  I:Integer;
  FileLength:Int64;
  Filebuffer:PAnsiChar;
  FileContent:string;
begin

  tFile:=TFileStream.Create(SourceFile,fmOpenRead);
  try
    tFile.Position:=0;
    FileLength:=tFile.Size;
    Getmem(Filebuffer,FileLength*SizeOf(AnsiChar));
    tFile.ReadBuffer(Filebuffer[0],FileLength);
  finally
    tFile.Free;
    FileContent:=String(Filebuffer);
    FreeMem(Filebuffer);
  end;

  Reg:=TPerlRegEx.Create();
  Reg.Options := [preCaseLess];
  try
    Reg.Subject:=FileContent;
    for I := 1 to 5 do
    begin
      Reg.RegEx:=RegEx[i];
      if not Reg.Match then Continue;
      if I=5 then
      begin
        Reg.RegEx:='const[\s\S]*'+ Reg.Groups[1] +'\s*=\s*''(.*?)''\s*;';
        if Reg.Match then
        begin
         Result:=Reg.Groups[1];
        end;
      end else Result:=Reg.Groups[1];
      Break;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TMainForm.JudgeMenuClick(Sender: TObject);
var
 I:Integer;
begin
JudgeConfig.TimeLimit:= StrToFloat(TMenuItem(Sender).Hint);
OutputDebugString(PChar(FloatToStr(JudgeConfig.TimeLimit)));
TGIFImage(img2.Picture.Graphic).AnimationSpeed := 130;
TGIFImage(img2.Picture.Graphic).Animate := True;
lbl5.Caption:='正在评测 '+ExtractFileName(JudgeConfig.FilePath);

//Listview 内容数组化
SetLength(JudgeConfig.InputFile,lv1.Items.Count);
SetLength(JudgeConfig.OutputFile,lv1.Items.Count);

for I := 0 to lv1.Items.Count - 1 do
begin
  JudgeConfig.InputFile[i]:=lv1.Items[i].SubItems[1];
  JudgeConfig.OutputFile[i]:=lv1.Items[i].SubItems[3];
end;

//通过正则表达匹配源代码 获得输入输出文件名
//By Martian 2011年1月16日15:46:53
{  2011年1月28日19:40:45 改变逻辑 取消这部分代码
JudgeConfig.InputFileName:=GetInputFileName(JudgeConfig.FilePath);
JudgeConfig.OutputFileName:=GetOutputFileName(JudgeConfig.FilePath);

if (JudgeConfig.InputFileName='')or(JudgeConfig.OutputFileName='') then
begin
  MessageBox(Handle, '程序无法通过正则表达式分析源代码以获得输入输出文件名！' + #13#10#13#10 +
    '请确保您的程序中至少含有以下内容中的两条：' + #13#10#13#10 + 'assign(input,''输入文件名'');' +
    #13#10 + 'fopen("输入文件名","r");' + #13#10 + 'freopen("输入文件名","r",######);' +
    #13#10 + 'ifstream ######("输入文件名");' + #13#10#13#10 +
    'assign(output,''输出文件名'');' + #13#10 + 'fopen("输出文件名","w");' + #13#10 +
    'freopen("输出文件名","w",######);' + #13#10 +
    'ofstream ######("输出文件名");' + #13#10#13#10 +
    '更多帮助请查阅：http://www.cena2.org', '错误', MB_OK + MB_ICONSTOP + MB_TOPMOST);
  pgc1.ActivePageIndex:=0;
  ts1.TabVisible:=True;
  ts2.TabVisible:=False;
  ts3.TabVisible:=False;
  ts4.TabVisible:=False;
  Exit;
end;       }

pgc1.ActivePageIndex:=2;
ts1.TabVisible:=False;
ts2.TabVisible:=False;
ts3.TabVisible:=True;
ts4.TabVisible:=False;
HTMLCompileError:='';
HtmlContent:='<html><head><meta http-equiv="Content-Type" content="text/html; charset=gb2312" /><title>评测结果</title></head>';
HtmlContent:=HtmlContent+'<script type="text/javascript">function doSaveAs()' + #123 + 'if (document.execCommand)' + #123 + 'document.execCommand("SaveAs");' + #125 + 'else' + #123 + 'alert(''Feature available only in Internet Exlorer 4.0 and later.'');' + #125 + #125 + '</script>';
HtmlContent:=HtmlContent+'<style type="text/css">';
HtmlContent:=HtmlContent+'body{font: normal 12px auto "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif; color: #4f6b72; background: #E6EAE9; overflow-x:hidden;}';
HtmlContent:=HtmlContent+'a{color: #4f6b72/*#c75f3e*/;text-decoration:none;}#mytable{width: 505px; padding: 0; margin: 0;}caption{padding: 0 0 5px 0; width: 505px; font: 12px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif; text-align: right;}';
HtmlContent:=HtmlContent+'th{font: bold 12px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif; color: #4f6b72; border-right: 1px solid #C1DAD7; border-bottom: 1px solid #C1DAD7; border-top: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; ';
HtmlContent:=HtmlContent+'text-align: left; padding: 6px 6px 6px 12px; background: #CAE8EA;}td{border-right: 1px solid #C1DAD7; border-bottom: 1px solid #C1DAD7; background: #fff; font-size:12px; padding: 6px 6px 6px 12px; color: #4f6b72;}td.alt{background: #F5FAFA;';
HtmlContent:=HtmlContent+' color: #797268;}th.spec{border-left: 1px solid #C1DAD7; border-top: 0; background: #fff; font: 12px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif, "新宋体";}th.specalt{border-left: 1px solid #C1DAD7; border-top: 0; background: #f5fafa;';
HtmlContent:=HtmlContent+' font: 12px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif; color: #797268;}span.ac{color:green;} span.wa{color:red;} span.ot{color:orange;} span.re{color:#930093;} ';
HtmlContent:=HtmlContent+'.buttons a, .buttons button{display:block;float:left;margin:0 7px 0 0;background-color:#f5f5f5;border:1px solid #dedede;border-top:1px solid #eee;border-left:1px solid #eee;font-family:"Lucida Grande", Tahoma, Arial, Verdana, sans-serif;';
HtmlContent:=HtmlContent+'font-size:12px;line-height:130%;text-decoration:none;font-weight:bold;color:#565656;cursor:pointer;padding:5px 10px 6px 7px;}';
HtmlContent:=HtmlContent+'button.regular, .buttons a.regular{color:#336699;}';
HtmlContent:=HtmlContent+'.buttons a.regular:hover, button.regular:hover{background-color:#dff4ff;border:1px solid #c2e1ef;color:#336699;}';
HtmlContent:=HtmlContent+'.buttons a.regular:active{background-color:#6299c5;border:1px solid #6299c5;color:#fff;}';
HtmlContent:=HtmlContent+'</style><body><table id="mytable" cellspacing="0" align="center">';
HtmlContent:=HtmlContent+'<caption>CenaLite! - '+ DateTimeToStr(Now) +' '+ ExtractFileName(JudgeConfig.FilePath) +' 评测结果</caption>';
HtmlContent:=HtmlContent+'<tr><th scope="col" abbr="Configurations">评测结果</th><th scope="col" abbr="result">测试点</th><th scope="col" abbr="time">有效时间</th><th scope="col" br="memory">内存占用</th></tr>';
hJudgeThread := TJudgeThread.Create;
hJudgeThread.OnTerminate:=ThreadTerminate;
hJudgeThread.FreeOnTerminate:=True;
hJudgeThread.Start;


end;

procedure WB_LoadHTML(WebBrowser: TWebBrowser; HTMLCode: string);
var
  sl: TStringList;
  ms: TMemoryStream;
begin
  if not Assigned(WebBrowser.Document) then WebBrowser.Navigate('about:blank');
  //WebBrowser.Refresh;
  if Assigned(WebBrowser.Document) then
  begin
    sl :=TStringList.Create;
    try
      ms :=TMemoryStream.Create;
      try
        sl.Text :=HTMLCode;
        sl.SaveToStream(ms);
        ms.Seek(0, 0);
        (WebBrowser.Document as IPersistStreamInit).Load(TStreamAdapter.Create(ms));
      finally
        ms.Free;
      end;
    finally
      sl.Free;
    end;
  end;
end;

procedure TMainForm.ThreadTerminate(Sender: TObject);
   //ms: TMemoryStream;
begin
   //ms := TMemoryStream.Create;
   try
    //redt1.Lines.SaveToStream(ms);

    //ms.Seek(0,soFromBeginning);
    //redt2.Lines.LoadFromStream(ms);
    ts1.TabVisible :=True;
    ts2.TabVisible:=False;
    ts3.TabVisible:=False;
    ts4.TabVisible:=True;
    pgc1.ActivePageIndex:=3;
    {wb1.Navigate('about:blank');
    HTMLDocument := wb2.Document as IHTMLDocument2;
    v := VarArrayCreate([0, 0], varVariant);
    v[0] := HtmlContent;
    HTMLDocument.Write(PSafeArray(TVarData(v).VArray));
    HTMLDocument.Close; }
    if HTMLCompileError='' then
    begin
      WB_LoadHTML(wb2,HtmlContent+'</table><br \><div class="buttons"><a href="javascript:void(0);" class="regular" onclick="doSaveAs()">保存本页</a><a href="#judge" class="regular">重新评测当前程序</a></div></body></html>');
    end else
    begin
     HtmlContent:=HtmlContent + '<tr><th scope="row" class="spec">评测失败</th><td>-</td><td>-</td><td>-</td></tr></table>';
     WB_LoadHTML(wb2,HtmlContent + '<p style="margin:10px">' + HTMLCompileError + '</p><br \><div class="buttons"><a href="javascript:void(0);" class="regular" onclick="doSaveAs()">保存本页</a><a href="#judge" class="regular">重新评测当前程序</a></div></body></html>');
    end;

   finally
    //ms.Free;
   end;
end;

procedure TMainForm.tmr1Timer(Sender: TObject);
begin
if GlobalCounter>7 then
begin
  tmr1.Enabled:=False;
  lbl1.Caption:='请将待测程序拖拽到此处';
end;
if (GlobalCounter mod 2)=1 then
  lbl1.Font.Color:=clRed
else
  lbl1.Font.Color:=clBlack;

GlobalCounter:=GlobalCounter+1;

end;

procedure TMainForm.wb1DocumentComplete(ASender: TObject;
  const pDisp: IDispatch; var URL: OleVariant);
begin
    wb1.OleObject.Document.Body.Scroll := 'auto';
    wb1.OleObject.Document.Body.style.border := 'none';
end;

procedure TMainForm.wb2BeforeNavigate2(ASender: TObject; const pDisp: IDispatch;
  var URL, Flags, TargetFrameName, PostData, Headers: OleVariant;
  var Cancel: WordBool);
begin
if Pos('#judge',URL)>0 then // 重新评测
begin
 pm1.Popup(Mouse.CursorPos.X,Mouse.CursorPos.Y);
end;
end;

procedure TMainForm.wb2DocumentComplete(ASender: TObject;
  const pDisp: IDispatch; var URL: OleVariant);
begin
    wb2.OleObject.Document.Body.Scroll := 'auto';
    wb2.OleObject.Document.Body.style.border := 'none';
end;

function LCS(s1,s2:WideString):integer;
var
  f:array[0..1] of array of integer;
  i,j:integer;
begin
  FillChar(f,sizeof(f),0);
  SetLength(f[0],length(s2)+1);
  SetLength(f[1],length(s2)+1);
{
 f[i-1,j-1]+1, if s1[i]=s2[j];
 f[i,j]=max(f[i-1,j],f[i,j-1]), else.
}
  for i:=1 to Length(s1) do
    for j:=1 to Length(s2) do
      if s1[i]=s2[j] then
        f[i and 1,j]:=f[1-i and 1,j-1]+1
      else
        f[i and 1,j]:=max(f[1-i and 1,j],f[i and 1,j-1]);

  Result:=f[Length(s1) and 1,Length(s2)];
  SetLength(f[0],0);
  SetLength(f[1],0);
end;

function IsInput(filename:string):Byte;
{智能判断是输入文件还是输出文件 返回值 1 输入文件 2 输出文件 3 未知}
{
 2011年1月28日13:04:32
 判断标准：扩展名 优先于 文件名
}
var
 s,s1,s2:String;
 i:Byte;
begin
 s:=UpperCase(filename);
 s1:=ExtractFileName(s);
 s2:=ExtractFileExt(s);  //获得文件名、文件扩展名
 if pos('IN',s2)>0 then
  Exit(1);
 if Pos('OU',s2)>0 then
  Exit(2);
 if Pos('AN',s2)>0 then
  Exit(2);
 if s2='INI' then Exit(3);
 

  if Pos('INPUT',s1)>0 then Exit(1);
  if Pos('OUTPUT',s2)>0 then Exit(2);

  if Pos('INPU',s1)>0 then Exit(1);
  if Pos('OUTPU',s2)>0 then Exit(2);

  if Pos('INPT',s1)>0 then Exit(1);
  if Pos('OUP',s2)>0 then Exit(2);

  if Pos('INP',s1)>0 then Exit(1);
  if Pos('OUT',s2)>0 then Exit(2);

  if Pos('IN',s1)>0 then Exit(1);
  if Pos('OU',s2)>0 then Exit(2);

 Exit(3);

end;


procedure TMainForm.WMDropFiles(var Msg: TWMDropFiles; hWnd: HWND);
var
  I,J,FileCount,Temp: Integer;
  p: array[0..1023] of Char;
  tItem:TListItem;

  InFileName:string;
  CompareA,CompareB:string;
  OutFileQueue:array of string;
  QueueTail:Integer;
  MaxValue:array[1..2] of Integer;

label
  DropSourceFile, DropData;
begin
  FileCount := DragQueryFile(Msg.Drop, $FFFFFFFF, nil, 0);  //查询文件总数
  SetLength(OutFileQueue,0);  //清空队列
  if hWnd=grp1.Handle then
    goto DropSourceFile
  else
  if hWnd=lv1.Handle then
    goto DropData
  else
    exit;


DropSourceFile:

  if FileCount<>1 then
  begin
    lbl1.Caption:='仅支持单次评测一个文件！';
    GlobalCounter := 1;
    tmr1.Enabled:=true;
    Exit;
  end;
  DragQueryFile(Msg.Drop, 0, p, SizeOf(p));

  if UpperCase(ExtractFileExt(p))='.PAS' then
    JudgeConfig.FileType:=FILE_PAS
    else
  if UpperCase(ExtractFileExt(p))='.C' then
    JudgeConfig.FileType:=FILE_C
    else
  if UpperCase(ExtractFileExt(p))='.CPP' then
    JudgeConfig.FileType:=FILE_CPP
  else
  begin
    lbl1.Caption:='文件格式不正确！仅支持c、cpp、pas文件';
    GlobalCounter:= 1;
    tmr1.Enabled:=true;
    Exit;
  end;
  {if (GetInputFileName(p)='') or (GetOutputFileName(p)='') then
  begin
   MessageBox(Handle, '程序无法通过正则表达式分析源代码以获得输入输出文件名！' + #13#10#13#10 +
    '请确保您的程序中至少含有以下内容中的两条：' + #13#10#13#10 + 'assign(input,''输入文件名'');' +
    #13#10 + 'fopen("输入文件名","r");' + #13#10 + 'freopen("输入文件名","r",######);' +
    #13#10 + 'ifstream ######("输入文件名");' + #13#10#13#10 +
    'assign(output,''输出文件名'');' + #13#10 + 'fopen("输出文件名","w");' + #13#10 +
    'freopen("输出文件名","w",######);' + #13#10 +
    'ofstream ######("输出文件名");' + #13#10#13#10 +
    '更多帮助请查阅：http://www.cena2.org', '错误', MB_OK + MB_ICONSTOP + MB_TOPMOST);
    exit;

  end;}

  lbl2.Caption:='文件路径：'+p;
  JudgeConfig.FilePath := p;
  case JudgeConfig.FileType of
  FILE_C:lbl3.Caption:='文件类型：C (.c)';
  FILE_CPP:lbl3.Caption:='文件类型：C/C++ (.cpp)';
  FILE_PAS:lbl3.Caption:='文件类型：Pascal (.pas)';
  end;

  JudgeConfig.InputFileName:=GetInputFileName(p);
  JudgeConfig.OutputFileName:=GetOutputFileName(p);
  edt1.Text:=JudgeConfig.InputFileName;
  edt2.Text:=JudgeConfig.OutputFileName;

  lv1.Items.Clear;
  btn3.Enabled:=False;

  if (edt1.Text='')or(edt2.Text='') then
  begin
    grp3.Visible:=True;
    Exit;
  end;

  ts2.TabVisible:=True;
  ts3.TabVisible:=False;
  ts4.TabVisible:=False;
  pgc1.ActivePageIndex := 1;
  status.Panels.Items[0].Text := '提示：输入文件扩展名必须为.in或.in*，输出文件扩展名必须为.an*或.ou*';
  Exit;

DropData:
  lv1.Items.BeginUpdate;
  SetLength(OutFileQueue,0);
  for I := 0 to FileCount - 1 do
  begin
    DragQueryFile(Msg.Drop, i, p, SizeOf(p));

    //先将输入文件.in加入listview，然后将.out文件加入队列，然后进行匹配
    if {Pos('.IN',UpperCase(ExtractFileExt(p)))>0} IsInput(p)=1 then

    begin
      tItem:=lv1.Items.Add;
      tItem.Caption:=IntToStr(lv1.Items.Count);
      tItem.SubItems.Add(ExtractFileName(p));
      TItem.SubItems.Add(p);
    end else
    begin
     if {(Pos('.OU',UpperCase(ExtractFileExt(p)))>0)or(Pos('.AN',UpperCase(ExtractFileExt(p)))>0)}IsInput(p)=2 then
     begin
      QueueTail:=Length(OutFileQueue);
      SetLength(OutFileQueue,QueueTail+1);
      OutFileQueue[QueueTail]:=p;
     end;
    end;
  end;

  for I := 0 to lv1.Items.Count - 1 do
  begin
    InFileName:=lv1.Items[i].SubItems[0];
    MaxValue[1]:=-MaxInt;
    for J := 0 to Length(OutFileQueue) - 1 do
    begin

     if OutFileQueue[j]='' then Continue;
    

    //利用LCS算法匹配字符串 同时增加字符串长度这一元素进行比较 防止出现a1.in匹配a10.out这样的情况
    {
      之前的不合理的算法：
      //Temp:=LCS(InFileName,OutFileQueue[j])-Abs(Length(InFileName)-Length(OutFileQueue[j]));
      //OutputDebugString(PChar(IntToStr(Temp)));
    }
     CompareA:=GetNumbersFromStringS(InFileName);
     //ShowMessage(CompareA + ' A ' + InFileName);
     CompareB:=GetNumbersFromStringS(ExtractFileName(OutFileQueue[j]));
     //ShowMessage(CompareB+ ' B ' + OutFileQueue[j]);
     Temp:=LCS(CompareA,CompareB)-Abs(Length(CompareA)-Length(CompareB));
      if Temp>MaxValue[1] then
      begin
        MaxValue[1]:=Temp;
        MaxValue[2]:=J;
      end;
    end;
    if MaxValue[1]>-MaxInt then
    begin
     lv1.Items[i].SubItems.Add(ExtractFileName(OutFileQueue[MaxValue[2]]));
     lv1.Items[i].SubItems.Add(OutFileQueue[MaxValue[2]]);
     OutFileQueue[MaxValue[2]]:='';
    end;

  end;
  lv1.Items.EndUpdate;
  m_bSort:=true;
  lv1ColumnClick(nil,lv1.Columns[1]);
  btn3.Enabled:=True;
end;

end.
