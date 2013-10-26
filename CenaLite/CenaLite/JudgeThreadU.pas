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
    ID:Integer; //�����ID
    Detail:string;
    SpanClass:string; //ac ͨ�� wa ����Ĵ�  ot ����ʱ������ re ����ʱ��������
    Time:String;
    Memory:String;
    Information:string; //��ϸ��Ϣ ���ڴ���Ĵ�
  end;


const
  COMP_SUCCEED                    =  0  ;
  COMP_PIPEERROR                  =  1  ;
  COMP_CREATEPROCESSERROR         =  2  ;
  ST_UNKNOWN                      =  0  ;  // δ֪
  ST_OK                           =  1  ;  // ����
  ST_CANNOT_EXECUTE               =  2  ;  // �޷�����
  ST_TIME_LIMIT_EXCEEDED          =  3  ;  // ��ʱ
  ST_MEMORY_LIMIT_EXCEEDED        =  4  ;  // ���ڴ�
  ST_RUNTIME_ERROR                =  5  ;  // ����ʱ����
  ST_CRASH                        =  6  ;  // ����

  ST_CORRECT                      =  7  ;  // ��ȷ
  ST_WRONG_ANSWER                 =  8  ;  // ����Ĵ�
  ST_PART_CORRECT                 =  9  ;  // �ò��ַ�
  ST_PROGRAM_NO_OUTPUT            =  10 ;  // ���������
  ST_NO_STANDARD_INPUT            =  12 ;  // �ޱ�׼����
  ST_NO_STANDARD_OUTPUT           =  13 ;  // �ޱ�׼���


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
//ɾ��Ŀ¼��Ŀ¼�µ������ļ� ��EXE
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
    DeleteFile(sFile);         //ɾ���ļ�
   until FindNext(sr) <> 0;
   FindClose(sr);
 end;
end;
procedure DeleteDir(sDirectory:String);
//ɾ��Ŀ¼��Ŀ¼�µ������ļ�ͬʱɾ���ļ���
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
    DeleteDir(sFile) //�ݹ�
    else if (sr.Attr and faAnyFile) = sr.Attr then
    DeleteFile(sFile);       //ɾ���ļ�
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
  //����һ�����д�д��������ϵĲ��������ַ���
  for i := 0 to Random(5)+3 do
  case i mod 2 of
    1:ans:=ans+Chr(Random(26)+65);
    0:ans:=ans+Chr(Random(10)+48);
  end;
  Result:=ans;
 end;

procedure TJudgeThread.SyncHTML(Detail,SpanClass:string;Time:double;Memory:integer;Information:string);
//��MainFormU��ȫ�ֱ�����ȫд��HTMLֵ
{
  rHTML=record
    ID:Integer; //�����ID
    Detail:string;
    SpanClass:string; //ac ͨ�� wa ����Ĵ�  ot ����ʱ������ re ����ʱ��������
    Time:String;
    Memory:String;
    Information:string; //��ϸ��Ϣ ���ڴ���Ĵ�
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
//��MainFormU��ȫ�ֱ�����ȫд�����ʧ�ܵ���Ϣ
begin
  AddHTMLContentCE:=StringReplace(Detail,#13,'<br \>',[rfReplaceAll]);
  Sync(AddCEHTML);
end;


procedure TJudgeThread.JudgeMainThread; stdcall;
//2011��2��1��0:14:38 �������Ƹú��� �������д���Һø���ġ�
var
 SourceFile{�����ļ�},NewSourceFile{�����ļ���λ��}:string;
 RunTimePath{����ʱĿ¼},TempDirPath{��ʱ�ļ���Ŀ¼},RandomString{����ַ���}:string;
 CompilerPath{������λ��},CompilerFileName{�������ļ�}:string;
 InputFile,OutputFile:string;

 I,iCompileResult:Integer;
 lpCompileInfo{������Ϣ}:PAnsiChar;
  CompareResult: Integer;
  Report: WideString;
var
 //��ʱ����
 pTimerResult:Pointer;
 TimerResult:rTimerReturnResult;
begin
 SourceFile:=JudgeConfig.FilePath;
 RunTimePath:=ExtractFilePath(ParamStr(0)); //��\��β

 TempDirPath:=RunTimePath+'WorkDir\';
 DeleteDir(TempDirPath);
 CreateDir(TempDirPath); //�����ʱ�ļ���

 RandomString:=GetRandomString;
 NewSourceFile:=TempDirPath+RandomString+ExtractFileExt(SourceFile);

 CompilerPath:=RunTimePath;


 if FileExists(SourceFile) then
  CopyFile(PChar(SourceFile),PChar(NewSourceFile),True);

  CompilerFileName:='\WorkDir\'+RandomString;
  case JudgeConfig.FileType of //���ñ�������
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
          Content:='�޷��������Compile_PipeError���޷����������ܵ�';
          SyncCEHTML(Content);
          Sync(AddText);
        end;

        Exit;
    end;
    COMP_CREATEPROCESSERROR:
    begin
        with AddTextContent do
        begin
          Content:='�޷��������Compile_CreateProcessError���޷����ñ�����';
          SyncCEHTML(Content);
          Sync(AddText);
        end;
        Exit;
    end;
    COMP_SUCCEED: //�ɹ����ñ�����
    begin
        if FileExists(TempDirPath+RandomString+'.exe') then
        begin
         //����ɹ�
        end else begin
         //����ʧ��
          with AddTextContent do
          begin
            Content:='�޷��������'+#13#10+lpCompileInfo;
            SyncCEHTML(Content);
            Sync(AddText);
          end;
          Exit;
        end;
    end;
  end;

  InputFile:=TempDirPath+JudgeConfig.InputFileName;
  OutputFile:=TempDirPath+JudgeConfig.OutputFileName;

  for I := 0 to Length(JudgeConfig.InputFile)-1 do  //!!!��ʼ����ÿһ�������
  begin
    AddHTMLContent.ID:=I + 1;
    DeleteFilesExceptEXE(TempDirPath);  //ɾ����EXE֮����κ��ļ�
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
            Content:='���Ե�'+IntToStr(I+1)+#9+'δ֪�Ĵ���';
            SelAttributesColor:=clRed;
            Sync(AddText);
            SyncHTML('δ֪�Ĵ���','re',0,0,'');
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
              Content:='���Ե�'+IntToStr(I+1)+#9+'��ȷ ('+{FormatFloat('0.000',Time)} FloatToStr(Time)+'ms��'+IntToStr(Memory)+'KB)';
              SelAttributesColor:=clGreen;
			        SyncHTML('��ȷ','ac',Time,Memory,'');
             end;
            ST_WRONG_ANSWER:
             begin
              Content:='���Ե�'+IntToStr(I+1)+#9+'����Ĵ�';
              SelAttributesColor:=clRed;
			        SyncHTML('����Ĵ�','wa',Time,Memory,Report);
             end;
            ST_PROGRAM_NO_OUTPUT:
             begin
              if Information<>0 then
              begin
               //���������������������ʱ����
                Content:='���Ե�'+IntToStr(I+1)+#9+'����ʱ���� (ExitCode��'+IntToStr(Information)+')';
                SelAttributesColor:=$ff0097;
                SyncHTML('����ʱ���� (ExitCode��' +IntToStr(Information)+')','re',0,0,'');
              end else begin
                Content:='���Ե�'+IntToStr(I+1)+#9+'���������';
                SelAttributesColor:=clBlack;
				        SyncHTML('���������','',0,0,'');
              end;
             end;
            ST_NO_STANDARD_OUTPUT:
             begin
              Content:='���Ե�'+IntToStr(I+1)+#9+'�ޱ�׼���';
              SelAttributesColor:=clBlack;
			        SyncHTML('�ޱ�׼���','',0,0,'');
             end;
            end;
            Sync(AddText);
          end;
        end;
        ST_CANNOT_EXECUTE:
        begin
          with AddTextContent do
          begin
            Content:='���Ե�'+IntToStr(I+1)+#9+'�޷����г���';
            SelAttributesColor:=clBlack;
            SyncHTML('�޷����г���','',0,0,'');
          end;
          Sync(AddText);
        end;
        ST_MEMORY_LIMIT_EXCEEDED:;
        ST_TIME_LIMIT_EXCEEDED:
        begin
          with AddTextContent do
          begin
            if Time<=0 then
              Content:='���Ե�'+IntToStr(I+1)+#9+'����ʱ������'
            else
              Content:='���Ե�'+IntToStr(I+1)+#9+'����ʱ������ ('+{FormatFloat('0.000',Time)}FloatToStr(Time)+'ms)';
            SyncHTML('����ʱ������','ot',0,0,'');
            SelAttributesColor:=$001188FF;
          end;
          Sync(AddText);
        end;
        ST_RUNTIME_ERROR:
        begin
          with AddTextContent do
          begin
            Content:='���Ե�'+IntToStr(I+1)+#9+'����ʱ���� (ExitCode��'+IntToStr(Information)+')';
            SelAttributesColor:=$ff0097;
			      SyncHTML('����ʱ���� '+IntToStr(Information),'re',0,0,'');
          end;
          Sync(AddText);
        end;
        ST_CRASH:
        begin
          with AddTextContent do
          begin
            Content:='���Ե�'+IntToStr(I+1)+#9+'����ʱ���� ('+EXCEPTIONCODE(Information)+')';
            SelAttributesColor:=clPurple;
			      SyncHTML('����ʱ���� '+EXCEPTIONCODE(Information),'re',0,0,'');
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
    Content:='CenaLite! - ���⿪ʼ - ' + ExtractFileName(JudgeConfig.FilePath)+' '+DateTimeToStr(Now)+#13#10;
    FirstIndent:=0;
    SelAttributesStyle:=[fsBold];
    SelAttributesColor:=clBlack;
    Sync(AddText);
  end;
  JudgeMainThread;
  with AddTextContent do
  begin
    Content:=#13#10+'CenaLite! - ������� ' + DateTimeToStr(Now);
    FirstIndent:=0;
    SelAttributesStyle:=[fsBold];
    SelAttributesColor:=clBlack;
    Sync(AddText);
  end;
end;

constructor TJudgeThread.Create;
begin
FreeOnTerminate:=True;
inherited Create(True); //����������������ִ��
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
 ans:=StringReplace(s,'\','\\',[rfReplaceAll]); //�滻��б��
 ans:=StringReplace(ans,'''','\''',[rfReplaceAll]); //�滻' ��\'
 ans:=StringReplace(ans,'"','\''',[rfReplaceAll]); //�滻" ��\'
 ans:=StringReplace(ans,#13#10,'\n',[rfReplaceAll]); //�滻�س�
 JavaScriptEscapeCharacter:=ans;
end;

procedure TJudgeThread.AddCEHTML;
begin
  HTMLCompileError:=AddHTMLContentCE;
end;

procedure TJudgeThread.AddHTML;
//��Html�������ɳ������浽��������
begin
  if AddHTMLContent.ID mod 2 = 1 then
  begin
    HtmlContent:=HtmlContent+'<tr><th scope="row" class="spec">���Ե�'+IntToStr(AddHTMLContent.ID) +'</th>';
    //HtmlContent:=HtmlContent+'<td><span class="' + AddHTMLContent.SpanClass +'">'+ AddHTMLContent.Detail +'</span></td>';
    if AddHTMLContent.Information = '' then
      HtmlContent:=HtmlContent+'<td><span class="' + AddHTMLContent.SpanClass +'">'+ AddHTMLContent.Detail +'</span></td>'
    else
      HtmlContent:=HtmlContent+'<td><span class="' + AddHTMLContent.SpanClass +'">'+ AddHTMLContent.Detail +'&nbsp;<a href=''javascript:void(0);'' onclick="javascript:alert('''+ JavaScriptEscapeCharacter(AddHTMLContent.Information) +''')">(?)</a></span></td>';


    HtmlContent:=HtmlContent+'<td><span class="' + AddHTMLContent.SpanClass +'">'+ AddHTMLContent.Time +'</span></td>';
    HtmlContent:=HtmlContent+'<td><span class="' + AddHTMLContent.SpanClass +'">' + AddHTMLContent.Memory +'</span></td></tr>';

  end
  else begin
    HtmlContent:=HtmlContent+'<tr><th scope="row" class="specalt">���Ե�'+IntToStr(AddHTMLContent.ID) +'</th>';
    if AddHTMLContent.Information = '' then
      HtmlContent:=HtmlContent+'<td class="alt"><span class="' + AddHTMLContent.SpanClass +'">'+ AddHTMLContent.Detail +'</span></td>'
    else
      HtmlContent:=HtmlContent+'<td class="alt"><span class="' + AddHTMLContent.SpanClass +'">'+ AddHTMLContent.Detail +'&nbsp;<a href=''javascript:void(0);'' onclick="javascript:alert('''+ JavaScriptEscapeCharacter(AddHTMLContent.Information) +''')">(?)</a></span></td>';

    HtmlContent:=HtmlContent+'<td class="alt"><span class="' + AddHTMLContent.SpanClass +'">'+ AddHTMLContent.Time +'</span></td>';
    HtmlContent:=HtmlContent+'<td class="alt"><span class="' + AddHTMLContent.SpanClass +'">' + AddHTMLContent.Memory +'</span></td></tr>';

  end;
end;

end.
