{*******************************************************************************

                CenaLite - Judge Library

      File:                 JudgeThreadU.pas
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
unit JudgeThreadU;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Dialogs, StdCtrls, ComCtrls;

type
  TJudgeThread = class(TThread)
  private
    procedure Sync(Method: TThreadMethod);
  protected
    procedure JudgeMainThread; stdcall;
    procedure Execute; override;
    procedure AddText;
    procedure AddHTML;
    procedure AddCEHTML;
	  procedure SyncHTML(Detail,SpanClass:String;Time:double;Memory:integer;Information:string);
    procedure SyncCEHTML(Detail:string);

  public
    constructor Create;
  end;
type
 rAddText=record
     Content:String;
     FirstIndent:Integer;
     SelAttributesStyle:TFontStyles;
     SelAttributesColor:TColor;
  end;
 rTimerReturnResult=record
    Status:Integer;
    Time:Double;
    Information:Cardinal;
    Memory:Integer;
  end;
  rHTML=record
    ID:Integer; //评测点ID
    Detail:string;
    SpanClass:string; //ac 通过 wa 错误的答案  ot 超过时间限制 re 运行时错误或崩溃
    Time:String;
    Memory:String;
    Information:string; //详细信息 用于错误的答案
  end;


const
  COMP_SUCCEED                    =  0  ;
  COMP_PIPEERROR                  =  1  ;
  COMP_CREATEPROCESSERROR         =  2  ;
  ST_UNKNOWN                      =  0  ;  // 未知
  ST_OK                           =  1  ;  // 正常
  ST_CANNOT_EXECUTE               =  2  ;  // 无法运行
  ST_TIME_LIMIT_EXCEEDED          =  3  ;  // 超时
  ST_MEMORY_LIMIT_EXCEEDED        =  4  ;  // 超内存
  ST_RUNTIME_ERROR                =  5  ;  // 运行时错误
  ST_CRASH                        =  6  ;  // 崩溃

  ST_CORRECT                      =  7  ;  // 正确
  ST_WRONG_ANSWER                 =  8  ;  // 错误的答案
  ST_PART_CORRECT                 =  9  ;  // 得部分分
  ST_PROGRAM_NO_OUTPUT            =  10 ;  // 程序无输出
  ST_NO_STANDARD_INPUT            =  12 ;  // 无标准输入
  ST_NO_STANDARD_OUTPUT           =  13 ;  // 无标准输出


var
  AddTextContent:rAddText;
  AddHTMLContent:rHTML;
  AddHTMLContentCE:string;
implementation


uses
  MainFormU,CompareU;

function iCompile(lpFileName:AnsiString;lpCompileCommand:AnsiString;lpCompileInfo:Pointer):Integer; stdcall;
external 'Modules\Compile.dll';
function DoIt(Cmd:AnsiString;TimeLimit:Cardinal;MemoryLimit:Integer;JudgeFasterA:Boolean):Pointer;stdcall;
external 'Modules\Timer.dll';
FUNCTION EXCEPTIONCODE(EC:CARDINAL):string;
BEGIN
  CASE EC OF
   STATUS_ACCESS_VIOLATION:RESULT:='ACCESS_VIOLATION';
   STATUS_IN_PAGE_ERROR:RESULT:='IN_PAGE_ERROR';
   STATUS_INVALID_HANDLE:RESULT:='INVALID_HANDLE';
   STATUS_NO_MEMORY:RESULT:='NO_MEMORY';
   STATUS_ILLEGAL_INSTRUCTION:RESULT:='ILLEGAL_INSTRUCTION';
   STATUS_NONCONTINUABLE_EXCEPTION:RESULT:='NONCONTINUABLE_EXCEPTION';
   STATUS_INVALID_DISPOSITION:RESULT:='INVALID_DISPOSITION';
   STATUS_ARRAY_BOUNDS_EXCEEDED:RESULT:='ARRAY_BOUNDS_EXCEEDED';
   STATUS_FLOAT_DENORMAL_OPERAND:RESULT:='FLOAT_DENORMAL_OPERAND';
   STATUS_FLOAT_DIVIDE_BY_ZERO:RESULT:='FLOAT_DIVIDE_BY_ZERO';
   STATUS_FLOAT_INEXACT_RESULT:RESULT:='FLOAT_INEXACT_RESULT';
   STATUS_FLOAT_INVALID_OPERATION:RESULT:='INVALID_OPERATION_OR_DIVIDE_BY_ZERO';
   STATUS_FLOAT_OVERFLOW:RESULT:='FLOAT_OVERFLOW';
   STATUS_FLOAT_STACK_CHECK:RESULT:='FLOAT_STACK_CHECK';
   STATUS_FLOAT_UNDERFLOW:RESULT:='FLOAT_UNDERFLOW';
   STATUS_INTEGER_DIVIDE_BY_ZERO:RESULT:='INTEGER_DIVIDE_BY_ZERO';
   STATUS_INTEGER_OVERFLOW:RESULT:='INTEGER_OVERFLOW';
   STATUS_PRIVILEGED_INSTRUCTION:RESULT:='PRIVILEGED_INSTRUCTION';
   STATUS_STACK_OVERFLOW:RESULT:='STACK_OVERFLOW';
   STATUS_CONTROL_C_EXIT:RESULT:='CONTROL_C_EXIT';
   MAXIMUM_WAIT_OBJECTS:RESULT:='WAIT_OBJECTS';
   ELSE BEGIN
     RESULT:= INTTOSTR(EC);
   END;
  END;
END;


procedure DeleteFilesExceptEXE(sDirectory:String);
//删除目录和目录下的所有文件 除EXE
var
 sr:TSearchRec;
 sPath,sFile:String;
begin
 if Copy(sDirectory,Length(sDirectory),1)<>'\'then
 sPath:=sDirectory+'\'
 else
 sPath:=sDirectory;
 if FindFirst(sPath+ '*.*',faAnyFile, sr) = 0 then
 begin
   repeat
    sFile:=Trim(sr.Name);
    if sFile= '.' then Continue;
    if sFile= '..' then Continue;
    if UpperCase(ExtractFileExt(sFile))= '.EXE' then Continue;
    sFile:=sPath+sr.Name;
    if (sr.Attr and faDirectory) = 0 then
    if (sr.Attr and faAnyFile) = sr.Attr then
    DeleteFile(sFile);         //删除文件
   until FindNext(sr) <> 0;
   FindClose(sr);
 end;
end;
procedure DeleteDir(sDirectory:String);
//删除目录和目录下的所有文件同时删除文件夹
var
 sr:TSearchRec;
 sPath,sFile:String;
begin
 if Copy(sDirectory,Length(sDirectory),1)<>'\'then
 sPath:=sDirectory+'\'
 else
 sPath:=sDirectory;
 if FindFirst(sPath+ '*.*',faAnyFile, sr) = 0 then
 begin
   repeat
    sFile:=Trim(sr.Name);
    if sFile= '.' then Continue;
    if sFile= '..' then Continue;
    sFile:=sPath+sr.Name;
    if (sr.Attr and faDirectory) <> 0 then
    DeleteDir(sFile) //递归
    else if (sr.Attr and faAnyFile) = sr.Attr then
    DeleteFile(sFile);       //删除文件
   until FindNext(sr) <> 0;
   FindClose(sr);
 end;
 RemoveDir(sPath);
end;
function GetRandomString:string;
var
 ans:String;
 i:integer;
begin
  //生成一个含有大写、数字组合的不定长度字符串
  for i := 0 to Random(5)+3 do
  case i mod 2 of
    1:ans:=ans+Chr(Random(26)+65);
    0:ans:=ans+Chr(Random(10)+48);
  end;
  Result:=ans;
 end;

procedure TJudgeThread.SyncHTML(Detail,SpanClass:string;Time:double;Memory:integer;Information:string);
//向MainFormU的全局变量安全写入HTML值
{
  rHTML=record
    ID:Integer; //评测点ID
    Detail:string;
    SpanClass:string; //ac 通过 wa 错误的答案  ot 超过时间限制 re 运行时错误或崩溃
    Time:String;
    Memory:String;
    Information:string; //详细信息 用于错误的答案
  end;
}begin
  AddHTMLContent.Detail:=Detail;
  AddHTMLContent.SpanClass:=SpanClass;
  //AddHTMLContent.Time:=FormatFloat('0.0000',Time)+'s';
  AddHTMLContent.Time:=FloatToStr(Time)+'ms';
  AddHTMLContent.Memory:=IntToStr(Memory)+'KB';
  AddHTMLContent.Information:=Information;
  Sync(AddHTML);
end;

procedure TJudgeThread.SyncCEHTML(Detail:string);
//向MainFormU的全局变量安全写入编译失败的信息
begin
  AddHTMLContentCE:=StringReplace(Detail,#13,'<br \>',[rfReplaceAll]);
  Sync(AddCEHTML);
end;


procedure TJudgeThread.JudgeMainThread; stdcall;
//2011年2月1日0:14:38 火车上完善该函数 这个函数写得我好浮躁的。
var
 SourceFile{试题文件},NewSourceFile{试题文件新位置}:string;
 RunTimePath{运行时目录},TempDirPath{临时文件夹目录},RandomString{随机字符串}:string;
 CompilerPath{编译器位置},CompilerFileName{待编译文件}:string;
 InputFile,OutputFile:string;

 I,iCompileResult:Integer;
 lpCompileInfo{编译信息}:PAnsiChar;
  CompareResult: Integer;
  Report: WideString;
var
 //计时部分
 pTimerResult:Pointer;
 TimerResult:rTimerReturnResult;
begin
 SourceFile:=JudgeConfig.FilePath;
 RunTimePath:=ExtractFilePath(ParamStr(0)); //以\结尾

 TempDirPath:=RunTimePath+'WorkDir\';
 DeleteDir(TempDirPath);
 CreateDir(TempDirPath); //清空临时文件夹

 RandomString:=GetRandomString;
 NewSourceFile:=TempDirPath+RandomString+ExtractFileExt(SourceFile);

 CompilerPath:=RunTimePath;


 if FileExists(SourceFile) then
  CopyFile(PChar(SourceFile),PChar(NewSourceFile),True);

  CompilerFileName:='\WorkDir\'+RandomString;
  case JudgeConfig.FileType of //配置编译命令
    FILE_C:
    begin
      CompilerPath:='"'+RunTimePath+'\Compilers\bin\gcc.exe" %s.c -o %s.exe';
    end;
    FILE_CPP:
    begin
      CompilerPath:='"'+RunTimePath+'\Compilers\bin\g++.exe" %s.cpp -o %s.exe';
    end;
    FILE_PAS:
    begin
      CompilerPath:='"'+RunTimePath+'\Compilers\bin\ppc386.exe" -Sg %s.pas';
    end;
  end;
  Getmem(lpCompileInfo,65535*SizeOf(AnsiChar));

  iCompileResult:=iCompile(CompilerFileName,CompilerPath,@lpCompileInfo);
  with AddTextContent do
  begin
    FirstIndent:=10;
    SelAttributesStyle:=[];
    SelAttributesColor:=clBlack;
  end;
  case iCompileResult of
    COMP_PIPEERROR:
    begin
        with AddTextContent do
        begin
          Content:='无法编译程序，Compile_PipeError，无法创建匿名管道';
          SyncCEHTML(Content);
          Sync(AddText);
        end;

        Exit;
    end;
    COMP_CREATEPROCESSERROR:
    begin
        with AddTextContent do
        begin
          Content:='无法编译程序，Compile_CreateProcessError，无法调用编译器';
          SyncCEHTML(Content);
          Sync(AddText);
        end;
        Exit;
    end;
    COMP_SUCCEED: //成功调用编译器
    begin
        if FileExists(TempDirPath+RandomString+'.exe') then
        begin
         //编译成功
        end else begin
         //编译失败
          with AddTextContent do
          begin
            Content:='无法编译程序'+#13#10+lpCompileInfo;
            SyncCEHTML(Content);
            Sync(AddText);
          end;
          Exit;
        end;
    end;
  end;

  InputFile:=TempDirPath+JudgeConfig.InputFileName;
  OutputFile:=TempDirPath+JudgeConfig.OutputFileName;

  for I := 0 to Length(JudgeConfig.InputFile)-1 do  //!!!开始遍历每一个评测点
  begin
    AddHTMLContent.ID:=I + 1;
    DeleteFilesExceptEXE(TempDirPath);  //删除除EXE之外的任何文件
    CopyFile(PChar(JudgeConfig.InputFile[i]),PChar(InputFile),False);

    pTimerResult:=DoIt(TempDirPath+RandomString+'.exe',Trunc(JudgeConfig.TimeLimit*1000),10240000,True);
    CopyMemory(@TimerResult,pTimerResult,SizeOf(TimerResult));
    with TimerResult do
    begin
      case Status of
        ST_UNKNOWN:
        begin
          with AddTextContent do
          begin
            Content:='测试点'+IntToStr(I+1)+#9+'未知的错误！';
            SelAttributesColor:=clRed;
            Sync(AddText);
            SyncHTML('未知的错误','re',0,0,'');
          end;
        end;
        ST_OK:
        begin
          with AddTextContent do
          begin

            CompareResult:=Compare(PWideChar(OutputFile),PWideChar(JudgeConfig.OutputFile[i]),Report);

            case CompareResult of
            ST_CORRECT:
             begin
              Content:='测试点'+IntToStr(I+1)+#9+'正确 ('+{FormatFloat('0.000',Time)} FloatToStr(Time)+'ms，'+IntToStr(Memory)+'KB)';
              SelAttributesColor:=clGreen;
			        SyncHTML('正确','ac',Time,Memory,'');
             end;
            ST_WRONG_ANSWER:
             begin
              Content:='测试点'+IntToStr(I+1)+#9+'错误的答案';
              SelAttributesColor:=clRed;
			        SyncHTML('错误的答案','wa',Time,Memory,Report);
             end;
            ST_PROGRAM_NO_OUTPUT:
             begin
              if Information<>0 then
              begin
               //发生被编译器处理的运行时错误
                Content:='测试点'+IntToStr(I+1)+#9+'运行时错误 (ExitCode：'+IntToStr(Information)+')';
                SelAttributesColor:=$ff0097;
                SyncHTML('运行时错误 (ExitCode：' +IntToStr(Information)+')','re',0,0,'');
              end else begin
                Content:='测试点'+IntToStr(I+1)+#9+'程序无输出';
                SelAttributesColor:=clBlack;
				        SyncHTML('程序无输出','',0,0,'');
              end;
             end;
            ST_NO_STANDARD_OUTPUT:
             begin
              Content:='测试点'+IntToStr(I+1)+#9+'无标准输出';
              SelAttributesColor:=clBlack;
			        SyncHTML('无标准输出','',0,0,'');
             end;
            end;
            Sync(AddText);
          end;
        end;
        ST_CANNOT_EXECUTE:
        begin
          with AddTextContent do
          begin
            Content:='测试点'+IntToStr(I+1)+#9+'无法运行程序';
            SelAttributesColor:=clBlack;
            SyncHTML('无法运行程序','',0,0,'');
          end;
          Sync(AddText);
        end;
        ST_MEMORY_LIMIT_EXCEEDED:;
        ST_TIME_LIMIT_EXCEEDED:
        begin
          with AddTextContent do
          begin
            if Time<=0 then
              Content:='测试点'+IntToStr(I+1)+#9+'超过时间限制'
            else
              Content:='测试点'+IntToStr(I+1)+#9+'超过时间限制 ('+{FormatFloat('0.000',Time)}FloatToStr(Time)+'ms)';
            SyncHTML('超过时间限制','ot',0,0,'');
            SelAttributesColor:=$001188FF;
          end;
          Sync(AddText);
        end;
        ST_RUNTIME_ERROR:
        begin
          with AddTextContent do
          begin
            Content:='测试点'+IntToStr(I+1)+#9+'运行时错误 (ExitCode：'+IntToStr(Information)+')';
            SelAttributesColor:=$ff0097;
			      SyncHTML('运行时错误 '+IntToStr(Information),'re',0,0,'');
          end;
          Sync(AddText);
        end;
        ST_CRASH:
        begin
          with AddTextContent do
          begin
            Content:='测试点'+IntToStr(I+1)+#9+'运行时崩溃 ('+EXCEPTIONCODE(Information)+')';
            SelAttributesColor:=clPurple;
			      SyncHTML('运行时崩溃 '+EXCEPTIONCODE(Information),'re',0,0,'');
          end;
          Sync(AddText);
        end;
      end;
    end;

  end;

  FreeMem(lpCompileInfo);
end;

procedure TJudgeThread.Sync(Method: TThreadMethod);
begin
  Synchronize(Method);
end;

procedure TJudgeThread.Execute;
begin
  Randomize;
  with AddTextContent do
  begin
    Content:='CenaLite! - 评测开始 - ' + ExtractFileName(JudgeConfig.FilePath)+' '+DateTimeToStr(Now)+#13#10;
    FirstIndent:=0;
    SelAttributesStyle:=[fsBold];
    SelAttributesColor:=clBlack;
    Sync(AddText);
  end;
  JudgeMainThread;
  with AddTextContent do
  begin
    Content:=#13#10+'CenaLite! - 评测结束 ' + DateTimeToStr(Now);
    FirstIndent:=0;
    SelAttributesStyle:=[fsBold];
    SelAttributesColor:=clBlack;
    Sync(AddText);
  end;
end;

constructor TJudgeThread.Create;
begin
FreeOnTerminate:=True;
inherited Create(True); //创建结束但不立即执行
end;

procedure TJudgeThread.AddText;
begin
  MainForm.redt1.SelStart:=Length(MainForm.redt1.Text)-1;
  MainForm.redt1.SelLength:=Length(AddTextContent.Content);
  MainForm.redt1.Paragraph.FirstIndent:=AddTextContent.FirstIndent;
  MainForm.redt1.SelAttributes.Style:=AddTextContent.SelAttributesStyle;
  MainForm.redt1.SelAttributes.Color:=AddTextContent.SelAttributesColor;
  MainForm.redt1.Lines.Add(AddTextContent.Content);
  SendMessage(MainForm.redt1.Handle,WM_VSCROLL,SB_BOTTOM,0);
end;

function JavaScriptEscapeCharacter(s:string):string;
var
 ans:string;
begin
 ans:=StringReplace(s,'\','\\',[rfReplaceAll]); //替换反斜杠
 ans:=StringReplace(ans,'''','\''',[rfReplaceAll]); //替换' 到\'
 ans:=StringReplace(ans,'"','\''',[rfReplaceAll]); //替换" 到\'
 ans:=StringReplace(ans,#13#10,'\n',[rfReplaceAll]); //替换回车
 JavaScriptEscapeCharacter:=ans;
end;

procedure TJudgeThread.AddCEHTML;
begin
  HTMLCompileError:=AddHTMLContentCE;
end;

procedure TJudgeThread.AddHTML;
//将Html代码生成出来保存到变量里面
begin
  if AddHTMLContent.ID mod 2 = 1 then
  begin
    HtmlContent:=HtmlContent+'<tr><th scope="row" class="spec">测试点'+IntToStr(AddHTMLContent.ID) +'</th>';
    //HtmlContent:=HtmlContent+'<td><span class="' + AddHTMLContent.SpanClass +'">'+ AddHTMLContent.Detail +'</span></td>';
    if AddHTMLContent.Information = '' then
      HtmlContent:=HtmlContent+'<td><span class="' + AddHTMLContent.SpanClass +'">'+ AddHTMLContent.Detail +'</span></td>'
    else
      HtmlContent:=HtmlContent+'<td><span class="' + AddHTMLContent.SpanClass +'">'+ AddHTMLContent.Detail +'&nbsp;<a href=''javascript:void(0);'' onclick="javascript:alert('''+ JavaScriptEscapeCharacter(AddHTMLContent.Information) +''')">(?)</a></span></td>';


    HtmlContent:=HtmlContent+'<td><span class="' + AddHTMLContent.SpanClass +'">'+ AddHTMLContent.Time +'</span></td>';
    HtmlContent:=HtmlContent+'<td><span class="' + AddHTMLContent.SpanClass +'">' + AddHTMLContent.Memory +'</span></td></tr>';

  end
  else begin
    HtmlContent:=HtmlContent+'<tr><th scope="row" class="specalt">测试点'+IntToStr(AddHTMLContent.ID) +'</th>';
    if AddHTMLContent.Information = '' then
      HtmlContent:=HtmlContent+'<td class="alt"><span class="' + AddHTMLContent.SpanClass +'">'+ AddHTMLContent.Detail +'</span></td>'
    else
      HtmlContent:=HtmlContent+'<td class="alt"><span class="' + AddHTMLContent.SpanClass +'">'+ AddHTMLContent.Detail +'&nbsp;<a href=''javascript:void(0);'' onclick="javascript:alert('''+ JavaScriptEscapeCharacter(AddHTMLContent.Information) +''')">(?)</a></span></td>';

    HtmlContent:=HtmlContent+'<td class="alt"><span class="' + AddHTMLContent.SpanClass +'">'+ AddHTMLContent.Time +'</span></td>';
    HtmlContent:=HtmlContent+'<td class="alt"><span class="' + AddHTMLContent.SpanClass +'">' + AddHTMLContent.Memory +'</span></td></tr>';

  end;
end;

end.
