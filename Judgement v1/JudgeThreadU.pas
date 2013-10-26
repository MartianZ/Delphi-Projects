unit JudgeThreadU;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Dialogs, StdCtrls, ComCtrls, IniFiles, XMLIntf, XMLDoc, ActiveX;
type
 //*********** dataconf Xml数组化结构体 BEGIN **********//
 rCompiler=record
     Title:String;
     ExtName:String;
     CompileCommand:String;
     ExecuteCommand:String;
  end;
 rTestcase=record
   timelimit:Double;
   memorylimit:Cardinal;
   score:Double;
   tcInputFilename:array of string;
   tcOutputFilename:string;
 end;
 rProblem=record
   Title:string;
   InputFilename,LibraryFile:array of string;
   OutputFilename,Filename,CustomCompareFile:string;
   Comparetype:integer;
   Customchecker:string;
   testcase:array of rTestcase;
 end;
  //*********** dataconf Xml数组化结构体 END**********//
 //*********** 返回信息用结构体 BEGIN **********//
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
  rProgressBarPosition=record
    Number:ShortInt;
    Position:integer;
  end;
 //*********** 返回信息用结构体 END ***********//
 //*********** Result.xml 数组化结构体 BEGIN **********//
 rTestCaseResult=record
  rttStatus:Integer;
  rttExitCode:Cardinal;
  rttTime:Double;
  rttDetail:WideString;
  rttMemory:Integer;
  rttScore:Double;
 end;
 rProblemResult=record
  XMLFile:String;
  rtTitle,rtFilename,rtHash:String;
  rtStatus:Integer;
  rtDetail:PAnsiChar;
  rtTestCase:array of rTestCaseResult;
 end;

 //*********** Result.xml 数组化结构体 END  **********//
type
  TJudgeThread = class(TThread)
  private
    procedure Sync(Method: TThreadMethod);
  protected
    function JudgeMainThread:Integer; stdcall;
    procedure Execute; override;
    procedure AddText;
    procedure WriteXml;
    procedure ChangeLabel1;
    procedure ChangeLabel2;
    procedure ChangeLabel3;
    procedure ChangeProgressBar;
  public
    constructor Create(ContestPathT,XmlFileNameT:String;CenaHD:Cardinal);
  end;
var
  Problems:array of rProblem;
  Compilers:array of rCompiler;
  ContestPathA,XmlFileNameA:String;
  AddTextContent:rAddText;
  ProgressBarPosition:rProgressBarPosition;
  Label1Content,Label2Content,Label3Content:string;
  JudgeResult:rProblemResult;
  JudgeFaster:Boolean;
  InstanceNumner:String;
  CenaMainFormHANDLE:Cardinal;

const
  JM_NOCONFIGFILE                 =  1  ;   //缺少配置文件
  JM_CONFIGFILEERROR              =  2  ;   //配置文件错误
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

  ST_NO_SOURCE_FILE               =  14 ;  // 无程序
  ST_COMPILATION_ERROR            =  16 ;  // 编译错误
implementation
uses
  JudgeFormU,CompareU,Crc32U;

function iCompile(lpFileName:AnsiString;lpCompileCommand:AnsiString;lpCompileInfo:Pointer):Integer; stdcall;
external 'Module\Compile.dll';
function DoIt(Cmd:AnsiString;TimeLimit:Cardinal;MemoryLimit:Integer;JudgeFasterA:Boolean):Pointer;stdcall;
external 'Module\TimerOne.dll';

FUNCTION EXCEPTIONCODE(EC:CARDINAL):string;
BEGIN
  CASE EC OF
   STATUS_ACCESS_VIOLATION:RESULT:='EXCEPTION_ACCESS_VIOLATION';
   STATUS_IN_PAGE_ERROR:RESULT:='EXCEPTION_IN_PAGE_ERROR';
   STATUS_INVALID_HANDLE:RESULT:='EXCEPTION_INVALID_HANDLE';
   STATUS_NO_MEMORY:RESULT:='EXCEPTION_NO_MEMORY';
   STATUS_ILLEGAL_INSTRUCTION:RESULT:='EXCEPTION_ILLEGAL_INSTRUCTION';
   STATUS_NONCONTINUABLE_EXCEPTION:RESULT:='EXCEPTION_NONCONTINUABLE_EXCEPTION';
   STATUS_INVALID_DISPOSITION:RESULT:='EXCEPTION_INVALID_DISPOSITION';
   STATUS_ARRAY_BOUNDS_EXCEEDED:RESULT:='EXCEPTION_ARRAY_BOUNDS_EXCEEDED';
   STATUS_FLOAT_DENORMAL_OPERAND:RESULT:='EXCEPTION_FLOAT_DENORMAL_OPERAND';
   STATUS_FLOAT_DIVIDE_BY_ZERO:RESULT:='EXCEPTION_FLOAT_DIVIDE_BY_ZERO';
   STATUS_FLOAT_INEXACT_RESULT:RESULT:='EXCEPTION_FLOAT_INEXACT_RESULT';
   STATUS_FLOAT_INVALID_OPERATION:RESULT:='EXCEPTION_INVALID_OPERATION_OR_DIVIDE_BY_ZERO';
   STATUS_FLOAT_OVERFLOW:RESULT:='EXCEPTION_FLOAT_OVERFLOW';
   STATUS_FLOAT_STACK_CHECK:RESULT:='EXCEPTION_FLOAT_STACK_CHECK';
   STATUS_FLOAT_UNDERFLOW:RESULT:='EXCEPTION_FLOAT_UNDERFLOW';
   STATUS_INTEGER_DIVIDE_BY_ZERO:RESULT:='EXCEPTION_INTEGER_DIVIDE_BY_ZERO';
   STATUS_INTEGER_OVERFLOW:RESULT:='EXCEPTION_INTEGER_OVERFLOW';
   STATUS_PRIVILEGED_INSTRUCTION:RESULT:='EXCEPTION_PRIVILEGED_INSTRUCTION';
   STATUS_STACK_OVERFLOW:RESULT:='EXCEPTION_STACK_OVERFLOW';
   STATUS_CONTROL_C_EXIT:RESULT:='EXCEPTION_CONTROL_C_EXIT';
   MAXIMUM_WAIT_OBJECTS:RESULT:='EXCEPTION_WAIT_OBJECTS';
   ELSE BEGIN
     RESULT:= INTTOSTR(EC);
   END;
  END;
END;
function GetRandomString:string;
var
 ans:String;
 i:integer;
begin
  //生成一个含有大写、数字组合的字符串
  for i := 0 to Random(5)+3 do
  case i mod 2 of
    1:ans:=ans+Chr(Random(26)+65);
    0:ans:=ans+Chr(Random(10)+48);
  end;
  {
  if FormatDateTime('m-d',Now)='1-1' then
   ans:='HappyNewYeah'+ans;
  if FormatDateTime('m-d',Now)='12-25' then
   ans:='MerryChristmas'+ans;
  }
  Result:=ans;
  //Result:=Chr(Random(26)+65)+Chr(Random(10)+48)+Chr(Random(26)+65)+Chr(Random(26)+65)+Chr(Random(10)+48)+Chr(Random(10)+48)+Chr(Random(10)+48);
end;
function min(a,b:Integer):Integer;
begin
  if a<b then exit(a) else exit(b);

end;
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


procedure LoadXml;
var
  root, cont, prob, node, node2: IXMLNode;
  i:integer;
  XmlFileName:String;
  nProblems{问题总数},nTestcase{评测点数目},npInput{问题输入文件个数},ntcInput{评测点输入文件个数},nLibrary{附件文件个数}:integer;
  iniFile:TIniFile;
  nCompilers{编译器总数}:integer;
  in_steam,out_steam:TMemoryStream;
begin

{
  第一步
  模拟Cena的LoadFromFile(ojtc.pas)函数读取xml，然后完全数组化
  方便评测过程中快速读取
}
//Problem:array of rProblem;
//SetLength(Problems,n)等价于array[0..n-1] ;

  XmlFileName:=XmlFileNameA;

  {
  try
   in_steam:=TMemoryStream.Create;

   out_steam:=TMemoryStream.Create;

   in_steam.LoadFromFile('C:\test33\data\dataconf.xml');
   out_steam.Position:=0;
   (in_steam,out_steam,15);
   //UnpackStream(in_steam,out_steam);
   //out_steam.Seek(0, soFromBeginning);
   //JudgeForm.doc.LoadFromStream(out_steam);
  finally
   in_steam.Free;
   out_steam.Free;
  end;         }

  try
    judgeform.doc.LoadFromFile(XmlFileName);
    JudgeForm.doc.Active:=True;
    {
      经过测试如果使用动态创建对象 使用 TXMLDocument 类或者使用 IXMLDocument 接口
      都会出现Invalid pointer operation或者Access violation还有NextSibling不稳定
      所以无奈 采用控件  ——Martian @ 2010年12月19日0:21:07
      另外对是否内存泄露持怀疑态度 算了 只读取一次
    }
  if JudgeForm.doc=nil then
  begin
   ShowMessage('XML Document not parsed successfully.');
   exit;
  end
  else begin
    root:=JudgeForm.doc.DocumentElement;
    if root.NodeName='cena' then begin
      cont:=root.ChildNodes.First;
      while cont<>nil do begin
        if cont.NodeName='contest' then begin

          //JudgeForm.Caption:='正在评测 —— ' + cont.AttributeNodes['title'].Text;
          //Juror:=(libxml2.xmlGetProp(cont,'juror'));
          prob:=cont.ChildNodes.First;
          nProblems:=0;
          while prob<>nil do
          begin
           if prob.NodeName='problem' then nProblems:=nProblems+1;
          //先循环一遍获得题目总数}
          prob:=prob.NextSibling;
          end;

          SetLength(Problems,nProblems);
          prob:=nil;
          prob:=cont.ChildNodes.First;
          i:=0;

          while prob<>nil do
          begin
            if prob.NodeName='problem' then begin

              with Problems[i] do begin
                Title:=(prob.AttributeNodes['title'].Text); //问题标题
                FileName:=(prob.AttributeNodes['filename'].Text);  //源程序文件名

                nTestcase:=0;
                npInput:=0;
                nLibrary:=0;
                node:=prob.ChildNodes.First;

                while node<>nil do
                begin
                  if node.NodeName='testcase' then begin

                    nTestcase:=nTestcase+1;
                    SetLength(Problems[i].testcase,nTestcase);

                    with Problems[i].testcase[nTestcase-1] do begin //nTestcase-1

                      node2:=node.ChildNodes.First;
                      ntcInput:=0;
                      while node2<>nil do begin

                        if node2.NodeName='input' then
                        begin
                          ntcInput:=ntcInput+1;
                          SetLength(tcInputFilename,ntcInput);
                          tcInputFilename[ntcInput-1]:=(node2.AttributeNodes['filename'].Text);
                        end;
                       if node2.NodeName='output' then
                         tcOutputFilename:=(node2.AttributeNodes['filename'].Text);

                        node2:=node2.NextSibling;
                      end;
                      Score:=strtofloat(node.AttributeNodes['score'].Text);
                      TimeLimit:=strtofloat(node.AttributeNodes['timelimit'].Text);
                      MemoryLimit:=strtoint(node.AttributeNodes['memorylimit'].Text);
                    end;
                  end;
                  if node.NodeName='input' then
                  begin
                    npInput:=npInput+1;
                    SetLength(InputFilename,npInput);
                    InputFilename[npInput-1]:=(node.AttributeNodes['filename'].Text);
                  end;
                  if node.NodeName='output' then
                    OutputFilename:=(node.AttributeNodes['filename'].Text);
                  if node.NodeName='library' then
                  begin
                    nLibrary:=nLibrary+1;
                    SetLength(LibraryFile,nLibrary);
                    LibraryFile[nLibrary-1]:=(node.AttributeNodes['filename'].Text);
                  end;
                  node:=node.NextSibling;
                end;

                CompareType:=strtoint(prob.AttributeNodes['comparetype'].Text);
                CustomCompareFile:=(prob.AttributeNodes['customchecker'].Text);

              end;
              i:=i+1;
            end;
            prob:=prob.NextSibling;
          end;

        end;
        cont:=cont.NextSibling;
      end;
    end;
  end;
  finally
    JudgeForm.doc.Active:=False;
    JudgeForm.doc.xml.Clear;
  end;
  {第一步完成}
  {第二步
    读取编译器配置 同时数组化 ——Martian @ 2010年12月19日11:09:18
  }
  iniFile:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'Settings.ini');
  try
    nCompilers:=iniFile.ReadInteger('Compilers','COUNT',0);
    if nCompilers=0 then exit;
    SetLength(Compilers,nCompilers);
    for I := 1 to nCompilers do
    begin
      Compilers[i-1].Title:=iniFile.ReadString('Compilers','Compiler'+IntToStr(i)+'.Title','');
      Compilers[i-1].ExtName:=iniFile.ReadString('Compilers','Compiler'+IntToStr(i)+'.ExtName','');
      Compilers[i-1].CompileCommand:=iniFile.ReadString('Compilers','Compiler'+IntToStr(i)+'.CompileCommand','');
      Compilers[i-1].ExecuteCommand:=iniFile.ReadString('Compilers','Compiler'+IntToStr(i)+'.ExecuteCommand','');
    end;
  finally
    iniFile.Free;
  end;

end;

function GetProblemLastHash(xml,problemname:string):string;
begin
  with JudgeForm do
  begin

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

function TJudgeThread.JudgeMainThread:Integer; stdcall;
var //我讨厌delphi的变量定义方式
 ContestPath{试题目录}:String;
 RunTimePath{程序运行所在目录}:string;
 TempDirPath{临时文件夹目录}:string;
 ini:TIniFile;
 nPersons:integer;
 i,j,k,n:integer;
 PersonFolder,bkPersonFolder,NewFileName,OldFileName,RandomString:String;
 PersonFolders:array of string;
 PersonName:array of string;
 SourceFileExist:Integer;
 tcNewFileName,tcOldFileName:string;
var
 //编译部分
 lpFileName,lpCompileCommand:String;
 lpCompileInfo:PAnsiChar;
 iResult:Integer;
var
 //计时部分
 pTimerResult:Pointer;
 TimerResult:rTimerReturnResult;
var
 //比较部分
 Report:WideString;
 CompareResult:Integer;
var
 //XML部分
 m:integer;
var
 //通信部分
 TEMP_STRING:string;
const
 JUDGE_BEGIN      =   '!'; //正在评测
 JUDGE_END        =   '@'; //评测结束

begin
 //ContestPath:=PChar(p); //备份一遍指针，不然出事
 ContestPath:=ContestPathA;
 RunTimePath:=ExtractFilePath(ParamStr(0)); //以\结尾
 if not FileExists(RunTimePath+'\Judge.ini') then
  exit(JM_NOCONFIGFILE);
 ini:=TIniFile.Create(RunTimePath+'\Judge.ini');
 try
    nPersons:=ini.ReadInteger('Judge'+InstanceNumner,'COUNT',0); //读取待评测选手数
    if nPersons=0 then exit(JM_CONFIGFILEERROR);
    for I := 1 to nPersons do
    begin
      PersonFolder:=ini.ReadString('Judge'+InstanceNumner,'PERSON'+IntToStr(i),'');
      if PersonFolder='' then Continue;
      bkPersonFolder:=PersonFolder;
      PersonFolder:=ContestPath+'\src\'+PersonFolder+'\'; //读取每个选手的文件夹名 也就是选手名
      if DirectoryExists(PersonFolder) then
      begin
      SetLength(PersonFolders,Length(PersonFolders)+1);
      PersonFolders[Length(PersonFolders)-1]:=PersonFolder; //存放到数组中
      SetLength(PersonName,Length(PersonName)+1);
      PersonName[Length(PersonName)-1]:=bkPersonFolder;
      end;
    end;
 finally
   ini.Free;
 end;


 Getmem(lpCompileInfo,65535*SizeOf(AnsiChar));
 TempDirPath:='tmp\TMP'+GetRandomString+'\';

 SetLength(bkPerson,Length(PersonName));
 //string这种由delphi管理生存周期的变量 还是循环赋值比较保险
 for i := 0 to Length(PersonName) - 1 do
   bkPerson[i]:=PersonName[i];


 for i := 0 to Length(PersonFolders) - 1 do  //!!!开始遍历每一个选手
 begin
  //2010年12月24日22:09:37 生成临时文件夹目录 方便多进程评测
  //TEMP_STRING:=ExtractFileName(Copy(PersonFolders[i],0,Length(PersonFolders[i])-1));

  bkCurrent:=i;

  TEMP_STRING:=PersonName[i];
  Label1Content:='正在评测 '+TEMP_STRING+' 的程序...';
  Sync(ChangeLabel1);
  SyncToMainForm(JUDGE_BEGIN+TEMP_STRING);

  JudgeResult.XMLFile:=PersonFolders[i]+'result.xml';


  with ProgressBarPosition do
  begin
    Number:=1;
    Position:=Trunc(i/Length(PersonFolders)*100);
    Sync(ChangeProgressBar);
  end;
  Label3Content:='剩余 '+IntToStr(Length(PersonFolders)-1-i)+' 名选手，当前进度：'+IntToStr(i+1)+'/'+IntToStr(Length(PersonFolders));
  Sync(ChangeLabel3);

  for j := 0 to (Length(Problems) - 1) do  //!!!开始遍历每一个问题
  begin
    //让JudgeResult的rtTestCase数组维数与Problem的相同
    SetLength(JudgeResult.rtTestCase,Length(Problems[j].testcase));

    with ProgressBarPosition do
    begin
      Number:=3;
      Position:=Trunc((j+1)/Length(Problems)*100);
      Sync(ChangeProgressBar);
    end;
    with ProgressBarPosition do
    begin
      Number:=2;
      Position:=0;
      Sync(ChangeProgressBar);
    end;
    with Problems[j] do
    begin
      with AddTextContent do
      begin
        Content:='正在评测 '+Title+' ('+Filename+')...';
        FirstIndent:=0;
        SelAttributesStyle:=[fsBold];
        SelAttributesColor:=clBlack;
      end;

      Sync(AddText);
       //判断源文件是否存在 同时可以获得采用哪个编译器
       SourceFileExist:=-1;
       for k := 0 to Length(Compilers)-1 do
       begin
         if FileExists(PersonFolders[i]+Filename+'.'+Compilers[k].ExtName) then
         begin
           SourceFileExist:=k;
           Break;
         end;
       end;
       Label2Content:='正在寻找源程序...';
       Sync(ChangeLabel2);
       if SourceFileExist=-1 then
       begin
         //源程序不存在
          with AddTextContent do
          begin
            Content:='找不到源程序。';
            FirstIndent:=10;
            SelAttributesStyle:=[];
            SelAttributesColor:=clBlack;
          end;
          with JudgeResult do
          begin
            rtTitle:=Title;
            rtStatus:=ST_NO_SOURCE_FILE;
            rtHash:='0';
            rtDetail:='';
            rtFilename:='';
            for m := 0 to Length(rtTestCase) - 1 do
            begin
              with rtTestCase[m] do
              begin
                rttStatus:=ST_NO_SOURCE_FILE;
                rttExitCode:=0;
                rttTime:=0;
                rttMemory:=0;
                rttScore:=0;
              end;
            end;
              
          end;
         Sync(WriteXml);
         Sync(AddText);
         Continue;
       end;
       with AddTextContent do
       begin
          Content:='找到文件'+#9+Filename+'.'+Compilers[SourceFileExist].ExtName;
          FirstIndent:=10;
          SelAttributesStyle:=[];
          SelAttributesColor:=clBlack;
          with JudgeResult do
          begin
            rtTitle:=Title;
            rtHash:=''; //从下方处理
            rtFilename:=Filename+'.'+Compilers[SourceFileExist].ExtName;
          end;
       end;
       with ProgressBarPosition do
       begin
        Number:=2;
        Position:=1;
        Sync(ChangeProgressBar);
       end;
       Sync(AddText);
       Label2Content:='正在编译...';
       Sync(ChangeLabel2);
       //清空工作目录
       DeleteDir(RunTimePath+TempDirPath);
       CreateDirectory(PChar(RunTimePath+TempDirPath),nil);
       //复制源文件到工作目录
       RandomString:=GetRandomString;
       NewFileName:=RunTimePath+TempDirPath+RandomString+'.'+Compilers[SourceFileExist].ExtName;
       OldFileName:=PersonFolders[i]+Filename+'.'+Compilers[SourceFileExist].ExtName;
       JudgeResult.rtHash:=IntToStr(CRC32file(OldFileName));
       if not CopyFile(PChar(OldFileName),PChar(NewFileName),False) then Continue;

       //复制附加文件到工作目录
       for k := 0 to Length(LibraryFile) - 1 do
       begin
         CopyFile(PChar(ContestPath+'\data\'+LibraryFile[k]),PChar(RunTimePath+TempDirPath+LibraryFile[k]),False);
       end;
       //调用编译器
       if Compilers[SourceFileExist].CompileCommand<>'' then //如果存在编译命令则进行编译 否则直接按编译成功处理
       begin
         lpFileName:=RandomString;
         lpCompileCommand:=Compilers[SourceFileExist].CompileCommand;
         iResult:=iCompile('\'+TempDirPath+lpFileName,lpCompileCommand,@lpCompileInfo);
         //lpCompileInfo:=nil;
         case iResult of
          COMP_PIPEERROR:begin

            //创建管道失败 编译失败
            with AddTextContent do
            begin
              Content:='无法编译程序，COMPILE_PIPEERROR';
              FirstIndent:=10;
              SelAttributesStyle:=[];
              SelAttributesColor:=clBlack;
            end;
            with JudgeResult do
            begin
              rtStatus:=ST_COMPILATION_ERROR;
              rtDetail:='创建匿名管道失败，无法调用编译器编译程序';
              for m := 0 to Length(rtTestCase) - 1 do
              begin
                with rtTestCase[m] do
                begin
                  rttStatus:=ST_COMPILATION_ERROR;
                  rttExitCode:=0;
                  rttTime:=0;
                  rttMemory:=0;
                  rttScore:=0;
                end;
              end;
            end;
            Sync(WriteXml);
            Sync(AddText);
            Continue;
          end;
          COMP_CREATEPROCESSERROR:begin

            //调用编译器失败 编译失败
            with AddTextContent do
            begin
              Content:='无法编译程序，COMPILE_CREATEPROCESSERROR';
              FirstIndent:=10;
              SelAttributesStyle:=[];
              SelAttributesColor:=clBlack;
            end;
            with JudgeResult do
            begin
              rtStatus:=ST_COMPILATION_ERROR;
              rtDetail:='编译失败，无法调用编译器编译程序';
              for m := 0 to Length(rtTestCase) - 1 do
              begin
                with rtTestCase[m] do
                begin
                  rttStatus:=ST_COMPILATION_ERROR;
                  rttExitCode:=0;
                  rttTime:=0;
                  rttMemory:=0;
                  rttScore:=0;
                end;
              end;
            end;
            Sync(WriteXml);
            Sync(AddText);
            Continue;
          end;
          COMP_SUCCEED:begin
            //成功调用编译器
            if FileExists(RunTimePath+TempDirPath+RandomString+'.exe') then
            begin
             //编译成功
              with JudgeResult do
              begin
                rtStatus:=ST_OK;
                rtDetail:=lpCompileInfo;
              end;
            end else begin
             //编译失败
              with AddTextContent do
              begin
                Content:='无法编译程序！';
                FirstIndent:=10;
                SelAttributesStyle:=[];
                SelAttributesColor:=clBlack;
              end;
              with JudgeResult do
              begin
                rtStatus:=ST_COMPILATION_ERROR;

                rtDetail:=lpCompileInfo;
                for m := 0 to Length(rtTestCase) - 1 do
                begin
                  with rtTestCase[m] do
                  begin
                    rttStatus:=ST_COMPILATION_ERROR;
                    rttExitCode:=0;
                    rttTime:=0;
                    rttMemory:=0;
                    rttScore:=0;
                  end;
                end;
              end;
             Sync(WriteXml);
             Sync(AddText);
             Continue;
            end;

          end;
         end;
       end else begin
        //编译成功
          with JudgeResult do
          begin
            rtStatus:=ST_OK;
            rtDetail:='';
          end;
       end;

       with ProgressBarPosition do
       begin
        Number:=2;
        Position:=5;
        Sync(ChangeProgressBar);
       end;

       for k := 0 to Length(testcase)-1 do  //!!!开始遍历每一个评测点
       begin
        with ProgressBarPosition do
        begin
          Number:=2;
          Position:=Trunc((k+1)/Length(testcase)*100);
          Sync(ChangeProgressBar);
        end;
         with testcase[k] do
         begin
          DeleteFilesExceptEXE(RunTimePath+TempDirPath); //删除除EXE之外的任何文件
          Label2Content:='正在清理临时文件夹...';
          Sync(ChangeLabel2);
          for n := 0 to min(Length(InputFilename),Length(tcInputFilename))-1 do
          begin
            //复制输入文件
            tcNewFileName:=RunTimePath+TempDirPath+InputFilename[n];
            tcOldFileName:=ContestPath+'\data\'+tcInputFilename[n];
            if CopyFile(PChar(tcOldFileName),PChar(tcNewFileName),false) then
            begin
            //TODO:Cena这里设置了文件属性FILE_ATTRIBUTE_ARCHIVE，不知道有何目的
            SetFileAttributesW(PWideChar(tcNewFileName),FILE_ATTRIBUTE_ARCHIVE)
            end;

          end;
            //运行 计时
            Label2Content:='正在评测...';
            Sync(ChangeLabel2);
            pTimerResult:=DoIt(RunTimePath+TempDirPath+RandomString+'.exe',Trunc(timelimit*1000),memorylimit,JudgeFaster);
            CopyMemory(@TimerResult,pTimerResult,SizeOf(TimerResult));
            with TimerResult do
            begin

              case Status of
              ST_UNKNOWN:
              begin
                with AddTextContent do
                begin
                  Content:='测试点'+IntToStr(k+1)+#9+'未知的错误！';
                  FirstIndent:=10;
                  SelAttributesStyle:=[];
                  SelAttributesColor:=clRed;
                  Sync(AddText);
                end;
                with JudgeResult.rtTestCase[k] do
                begin
                  rttStatus:=ST_UNKNOWN;
                  rttExitCode:=Information;
                  rttTime:=Time;
                  rttDetail:='测试点发生未知错误';
                  rttMemory:=Memory;
                  rttScore:=0;
                end;
              end;
              ST_OK:
              begin
                {with AddTextContent do
                begin
                  Content:='测试点'+IntToStr(k+1)+#9+'正确('+FormatFloat('0.000',Time)+'s，'+IntToStr(Memory)+'KB)';
                  FirstIndent:=10;
                  SelAttributesStyle:=[];
                  SelAttributesColor:=clGreen;
                  Sync(AddText);
                end; }
                Label2Content:='正在比较...';
                Sync(ChangeLabel2);

                with AddTextContent do
                begin
                  case Comparetype of
                    0{逐字节比较}:CompareResult:=CompareBin(PWideChar(RunTimePath+TempDirPath+OutputFilename),PWideChar(ContestPath+'\data\'+tcOutputFilename),Report);
                    1{忽略空格}:CompareResult:=Compare(PWideChar(RunTimePath+TempDirPath+OutputFilename),PWideChar(ContestPath+'\data\'+tcOutputFilename),Report);
                  end;
                  FirstIndent:=10;
                  SelAttributesStyle:=[];
                  case CompareResult of
                  ST_CORRECT:
                   begin
                    Content:='测试点'+IntToStr(k+1)+#9+'正确 ('+FormatFloat('0.000',Time)+'s，'+IntToStr(Memory)+'KB)';
                    SelAttributesColor:=clGreen;
                    with JudgeResult.rtTestCase[k] do
                    begin
                      rttStatus:=ST_CORRECT;
                      rttExitCode:=Information;
                      rttTime:=Time;
                      rttDetail:='';
                      rttMemory:=Memory;
                      rttScore:=score;
                    end;
                   end;
                  ST_WRONG_ANSWER:
                   begin
                    Content:='测试点'+IntToStr(k+1)+#9+'错误的答案';
                    SelAttributesColor:=clRed;
                    with JudgeResult.rtTestCase[k] do
                    begin
                      rttStatus:=ST_WRONG_ANSWER;
                      rttExitCode:=Information;
                      rttTime:=Time;
                      rttDetail:=Report;
                      rttMemory:=Memory;
                      rttScore:=0;
                    end;
                   end;
                  ST_PROGRAM_NO_OUTPUT:
                   begin
                    if Information<>0 then
                    begin
                     //发生被编译器处理的运行时错误
                      Content:='测试点'+IntToStr(k+1)+#9+'运行时错误 (ExitCode：'+IntToStr(Information)+')';
                      SelAttributesColor:=$ff0097;
                      with JudgeResult.rtTestCase[k] do
                      begin
                        rttStatus:=ST_RUNTIME_ERROR;
                        rttExitCode:=Information;
                        rttTime:=Time;
                        rttDetail:='';
                        rttMemory:=Memory;
                        rttScore:=0;
                      end;
                    end else begin
                      Content:='测试点'+IntToStr(k+1)+#9+'程序无输出';
                      SelAttributesColor:=clBlack;
                      with JudgeResult.rtTestCase[k] do
                      begin
                        rttStatus:=ST_PROGRAM_NO_OUTPUT;
                        rttExitCode:=Information;
                        rttTime:=Time;
                        rttDetail:='';
                        rttMemory:=Memory;
                        rttScore:=0;
                      end;
                    end;
                   end;
                  ST_NO_STANDARD_OUTPUT:
                   begin
                    Content:='测试点'+IntToStr(k+1)+#9+'无标准输出';
                    SelAttributesColor:=clBlack;
                      with JudgeResult.rtTestCase[k] do
                      begin
                        rttStatus:=ST_NO_STANDARD_OUTPUT;
                        rttExitCode:=Information;
                        rttTime:=Time;
                        rttDetail:='';
                        rttMemory:=Memory;
                        rttScore:=0;
                      end;
                   end;
                  end;
                  Sync(AddText);
                end;
              end;
              ST_CANNOT_EXECUTE:
              begin
                with AddTextContent do
                begin
                  Content:='测试点'+IntToStr(k+1)+#9+'无法运行程序';
                  FirstIndent:=10;
                  SelAttributesStyle:=[];
                  SelAttributesColor:=clBlack;
                  with JudgeResult.rtTestCase[k] do
                  begin
                    rttStatus:=ST_CANNOT_EXECUTE;
                    rttExitCode:=Information;
                    rttTime:=Time;
                    rttDetail:='';
                    rttMemory:=Memory;
                    rttScore:=0;
                  end;
                end;
                Sync(AddText);
              end;
              ST_MEMORY_LIMIT_EXCEEDED:
              begin
                with AddTextContent do
                begin
                  Content:='测试点'+IntToStr(k+1)+#9+'超出内存限制';
                  FirstIndent:=10;
                  SelAttributesStyle:=[];
                  SelAttributesColor:=clBlack;
                  with JudgeResult.rtTestCase[k] do
                  begin
                    rttStatus:=ST_MEMORY_LIMIT_EXCEEDED;
                    rttExitCode:=Information;
                    rttTime:=Time;
                    rttDetail:='';
                    rttMemory:=Memory;
                    rttScore:=0;
                  end;
                end;
                Sync(AddText);
              end;
              ST_TIME_LIMIT_EXCEEDED:
              begin
                with AddTextContent do
                begin
                  if Time<=0 then
                  begin
                   if JudgeFaster then
                    Content:='测试点'+IntToStr(k+1)+#9+'超过时间限制 (>'+FormatFloat('0.00',(timelimit))+'s)'
                   else
                    Content:='测试点'+IntToStr(k+1)+#9+'超过时间限制 (>'+FormatFloat('0.00',(timelimit*2))+'s)';
                  end
                  else
                    Content:='测试点'+IntToStr(k+1)+#9+'超过时间限制 ('+FormatFloat('0.000',Time)+'s)';


                  FirstIndent:=10;
                  SelAttributesStyle:=[];
                  SelAttributesColor:=$001188FF;
                  with JudgeResult.rtTestCase[k] do
                  begin
                    rttStatus:=ST_TIME_LIMIT_EXCEEDED;
                    rttExitCode:=Information;
                    rttTime:=Time;
                    rttDetail:='';
                    rttMemory:=Memory;
                    rttScore:=0;
                  end;
                end;
                Sync(AddText);
              end;
              ST_RUNTIME_ERROR:
              begin
                with AddTextContent do
                begin
                  Content:='测试点'+IntToStr(k+1)+#9+'运行时错误 (ExitCode：'+IntToStr(Information)+')';
                  FirstIndent:=10;
                  SelAttributesStyle:=[];
                  SelAttributesColor:=$ff0097;
                  with JudgeResult.rtTestCase[k] do
                  begin
                    rttStatus:=ST_RUNTIME_ERROR;
                    rttExitCode:=Information;
                    rttTime:=Time;
                    rttDetail:='';
                    rttMemory:=Memory;
                    rttScore:=0;
                  end;
                end;
                Sync(AddText);
              end;
              ST_CRASH:
              begin
                with AddTextContent do
                begin
                  Content:='测试点'+IntToStr(k+1)+#9+'运行时崩溃 ('+EXCEPTIONCODE(Information)+')';
                  FirstIndent:=10;
                  SelAttributesStyle:=[];
                  SelAttributesColor:=clPurple;
                  with JudgeResult.rtTestCase[k] do
                  begin
                    rttStatus:=ST_CRASH;
                    rttExitCode:=Information;
                    rttTime:=Time;
                    rttDetail:='';
                    rttMemory:=Memory;
                    rttScore:=0;
                  end;
                end;
                Sync(AddText);
              end;
              end;
            end;



         end;
       end;
       Sync(WriteXml);
    end;
  end;
  SyncToMainForm(JUDGE_END+TEMP_STRING);
 end;

 try
  DeleteDir(RunTimePath+TempDirPath);
  FreeMem(lpCompileInfo);
  DeleteDir(RunTimePath+TempDirPath);
 except
   //Do Nothing
 end;

end;

procedure TJudgeThread.Execute;
begin
CoInitialize(nil);
Randomize;
LoadXml; //加载XML到数组
JudgeMainThread;
CoUninitialize;
end;

procedure TJudgeThread.ChangeProgressBar;
begin
 with ProgressBarPosition do
 begin
   case Number of
   1:begin
     case Position of
      -1:JudgeForm.pb1.Style:=pbstMarquee;
      else
      begin
        JudgeForm.pb1.Style:=pbstNormal;
        JudgeForm.pb1.Position:=Position;
      end;
     end;
   end;
   2:JudgeForm.pb2.Position:=Position;
   3:JudgeForm.pb3.Position:=Position;
   end;
 end;
end;

procedure TJudgeThread.ChangeLabel1;
begin
 JudgeForm.lbl6.Caption:=Label1Content;
end;

procedure TJudgeThread.ChangeLabel2;
begin
 if JudgeFaster then exit;

 JudgeForm.lbl4.Caption:=Label2Content;
 Sleep(10);

end;

procedure TJudgeThread.ChangeLabel3;
begin
 JudgeForm.lbl7.Caption:=Label3Content+'  '+JudgeForm.lbl7.Hint;
end;

procedure TJudgeThread.AddText;
begin
  JudgeForm.redt1.SelStart:=Length(JudgeForm.redt1.Text)-1;
  JudgeForm.redt1.SelLength:=Length(AddTextContent.Content);
  JudgeForm.redt1.Paragraph.FirstIndent:=AddTextContent.FirstIndent;
  JudgeForm.redt1.SelAttributes.Style:=AddTextContent.SelAttributesStyle;
  JudgeForm.redt1.SelAttributes.Color:=AddTextContent.SelAttributesColor;
  JudgeForm.redt1.Lines.Add(AddTextContent.Content);
  SendMessage(JudgeForm.redt1.Handle,WM_VSCROLL,SB_BOTTOM,0);
end;

procedure TJudgeThread.WriteXml;
var
 root,pnode,tnode:IXMLNode;
 i,pnodeindex:integer;
begin
  with JudgeForm do
  begin

    with JudgeResult do
    begin
     doc2.XML.Clear;
     if FileExists(XMLFile) then
       doc2.LoadFromFile(XMLFile);
       //doc2.LoadFromFile();

      doc2.Active:=true;
      doc2.Encoding:='UTF-8';



       root:=doc2.DocumentElement;
       if root=nil then
       begin
        root:=doc2.AddChild('cena');
        root.SetAttribute('version','2.0');
        root:=root.AddChild('result');
        root.SetAttribute('judgetime',{DateTimeToStr(now)}FloatToStr(now));
       end else
       begin
        root:=root.ChildNodes.First;
        root.SetAttribute('judgetime',{DateTimeToStr(now)}FloatToStr(now));
        pnode:=root.ChildNodes.First;
         while pnode<>nil do
         begin
            if pnode.NodeName='problem' then
             if pnode.HasAttribute('title') then
              if pnode.GetAttribute('title')=rtTitle then
              begin
                pnode.ParentNode.ChildNodes.Delete(root.ChildNodes.IndexOf(pnode));  //删除之前的相同的问题节点
              end;
            pnode:=pnode.NextSibling;
         end;
       end;

       pnode:=root.AddChild('problem');
       pnode.SetAttribute('title',rtTitle);
       pnode.SetAttribute('filename',rtFilename);
       pnode.SetAttribute('status',IntToStr(rtStatus));
       pnode.SetAttribute('hash',rtHash);
       pnode.SetAttribute('detail',string(rtDetail)); //建立问题父节点

       for I := 0 to Length(rtTestCase) - 1 do   //写入测试点数据
       begin
        with rtTestCase[i] do
        begin
         tnode:=pnode.AddChild('testcase');
         tnode.SetAttribute('status',IntToStr(rttStatus));
         tnode.SetAttribute('exitcode',IntToStr(rttExitCode));
         tnode.SetAttribute('detail',rttDetail);
         tnode.SetAttribute('time',FormatFloat('0.000',rttTime));
         tnode.SetAttribute('memory',IntToStr(rttMemory));
         tnode.SetAttribute('score',FloatToStr(rttScore));
        end;
       end;
       doc2.SaveToFile(XMLFile);
       doc2.xml.Clear;
       doc2.Active:=false;
      end;
    end;

end;



constructor TJudgeThread.Create(ContestPathT:String;XmlFileNameT:String;CenaHD:Cardinal);
begin
XmlFileNameA:=XmlFileNameT;
ContestPathA:=ContestPathT;
CenaMainFormHANDLE:=CenaHD;
FreeOnTerminate:=True;
inherited Create(True); //创建结束但不立即执行
end;

procedure TJudgeThread.Sync(Method: TThreadMethod);
begin
  Synchronize(Method);
end;
end.
