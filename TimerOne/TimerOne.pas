unit TimerOne;

{
 仿Cena的评测计时、内存检测模块
 在Cena的基础上略有修改
 Martian 2010年12月4日
}
interface

uses
  Windows,PsAPI,SysUtils;

type
  TSystem_Performance_Information= packed record
      liIdleTime: LARGE_INTEGER;
      dwSpare:array[0..75] of DWORD;
  end;
  ReturnResult=record
    Status:Integer;
    Time:Double;
    Information:Cardinal;
    Memory:Integer;
  end;
  CheckLimitResult=record
    Status:Integer;
    Time:Double;
    Memory:Integer;
  end;

const

  ST_UNKNOWN                      =  0             ;  // 未知
  ST_OK                           =  1             ;  // 正常
  ST_CANNOT_EXECUTE               =  2             ;  // 无法运行
  ST_TIME_LIMIT_EXCEEDED          =  3             ;  // 超时
  ST_MEMORY_LIMIT_EXCEEDED        =  4             ;  // 超内存
  ST_RUNTIME_ERROR                =  5             ;  // 运行时错误
  ST_CRASH                        =  6             ;  // 崩溃
  //SystemPerformanceInformation = 2;
var
  //LastIdleTime:Int64;
  ProcessRunning:Boolean;
  JudgeFaster:Boolean;
  
function Exec(Cmd:string;TimeLimit:Cardinal{限制时间 单位毫秒};MemoryLimit:Integer{限制内存 单位kb};JudgeFasterA:Boolean):ReturnResult;
  
implementation

function NtQuerySystemInformation(infoClass: DWORD; buffer: Pointer;
  bufSize: DWORD; returnSize: PDword):DWORD; stdcall external 'ntdll.dll';
function CheckLimits(var pi:PROCESS_INFORMATION;TimeLimit:Cardinal{限制时间 单位毫秒};MemoryLimit:Integer{限制内存 单位kb}):CheckLimitResult;
var
  ct,et,kt,ut,ut2:FILETIME;
  Time:Double;
  TimeLimitMax:Double; //限制时间(s)  TimeLimit换算成秒以后*3
  pmc:_PROCESS_MEMORY_COUNTERS;
begin
  Result.Status:=ST_OK;
  Result.Time:=0;
  Result.Memory:=0;

  GetProcessTimes(pi.hProcess,ct,et,kt,ut);  //获取进程的时间 仅需要UserTime 用户时间
  ut2:=ut; //因为Int64(ut)会修改指针 所以备份一遍
  {
    Cena的计时模式的研究：
     运行程序过程中，用户时间减去启动进程到进程满载的CPU空闲时间
     如果程序执行完毕以后没有超时，则加紧要求，直接使用用户时间
     感觉多此一举
     所以以下代码仅使用UserTime 暂时不考虑CPU空闲时间
     ——Martian 2010年12月4日
  }
  if JudgeFaster then
  TimeLimitMax:=TimeLimit/1000 //最长执行时间
  else
  TimeLimitMax:=(TimeLimit/1000)*2;


  if {Final}True then
  begin
    Time:=trunc((int64(ut))/10000)/1000;
  end;{ else
  begin
    Time:=(int64(ut)+GetIdleTime-LastIdleTime)/10000000;
    Form1.lbl2.Caption:=FloatToStr(Time);
  end;}

  //16bit程序无法获取内存 Cena中进行了判断
  //但是现在的新版编译器均不再编译16BIT程序 所以可以直接取内存
  try
    ZeroMemory(@pmc,sizeof(pmc));
    pmc.cb:=sizeof(pmc);
    GetProcessMemoryInfo(pi.hProcess,@pmc,sizeof(pmc));
    Result.Memory:=pmc.PeakPagefileUsage shr 10;
    if Result.Memory>MemoryLimit then begin
      { 超出内存限制 }
      Result.Time:=-1;
      Result.Status:=ST_MEMORY_LIMIT_EXCEEDED;
      TerminateProcess(pi.hProcess,1);
      Exit;
    end;
  except
    Result.Memory:=-1;
  end;
  Result.Time:=Time;
  if Time>TimeLimit/1000 then
  begin
   Result.Status:=ST_TIME_LIMIT_EXCEEDED;
   { 超过时间限制 }
  end;
  if Time>TimeLimitMax then
  begin
   Result.Status:=ST_TIME_LIMIT_EXCEEDED;
   Result.Time:=-1;
   TerminateProcess(pi.hProcess,1);
   { 超过限制时间三倍 返回 同时结束进程 }
  end;
end;

function ExtractFilePath(const FileName: string): string;
var
  I: Integer;
begin
  I := LastDelimiter(PathDelim + DriveDelim, FileName);
  Result := Copy(FileName, 1, I);
end;

function Exec(Cmd:AnsiString;TimeLimit:Cardinal{限制时间 单位毫秒};MemoryLimit:Integer{限制内存 单位kb};JudgeFasterA:Boolean{是否启用快速评测}):ReturnResult;
var
 si:STARTUPINFO;
 pi:PROCESS_INFORMATION;
 ok:boolean;
 de:_DEBUG_EVENT;
 CheckLimitResultA:CheckLimitResult;
 ExceptionInfo:String;
 WorkPath:string;
begin
 FillChar(si,SizeOf(si),0);
 ProcessRunning:=False;
 Result.Status:=ST_UNKNOWN;
 Result.Time:=0;
 Result.Information:=0;
 JudgeFaster:=JudgeFasterA;
 with si do
 begin
    cb:=sizeof(si);
    dwFlags:=STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    //dwFlags:=STARTF_USESHOWWINDOW;
    wShowWindow:=SW_HIDE;
    hStdOutput := 0;
    hStdInput := 0;
    hStdError := 0;
 end;
 WorkPath:=ExtractFilePath(Cmd);
 //以下代码均修改自Cena源程序
 ok:=CreateProcess(nil,PChar(Cmd),nil,nil,True,DEBUG_PROCESS or DEBUG_ONLY_THIS_PROCESS or CREATE_NEW_CONSOLE,nil,PChar(WorkPath),si,pi);
 if ok then
 begin
    ProcessRunning:=True;
    {LastIdleTime:=GetIdleTime;}
    Repeat
      while WaitForDebugEvent(de,1) do
      begin
        ContinueDebugEvent(de.dwProcessId,de.dwThreadId,DBG_CONTINUE);
        case de.dwDebugEventCode of
        EXCEPTION_DEBUG_EVENT:
          begin
           case de.Exception.ExceptionRecord.ExceptionCode of
                {STATUS_ACCESS_VIOLATION, STATUS_ILLEGAL_INSTRUCTION, STATUS_NO_MEMORY
                STATUS_IN_PAGE_ERROR, STATUS_INVALID_HANDLE, STATUS_PRIVILEGED_INSTRUCTION:   // !!! any other possible statuses?
                begin
                  Result.Status:=ST_CRASH_A;
                  Result.Time:=0;
                  Result.Information:=de.Exception.ExceptionRecord.ExceptionCode;
                  TerminateProcess(pi.hProcess,de.Exception.ExceptionRecord.ExceptionCode);
                end;  }
                {STATUS_FLOAT_DIVIDE_BY_ZERO, STATUS_INTEGER_OVERFLOW,
                STATUS_FLOAT_OVERFLOW, STATUS_STACK_OVERFLOW, STATUS_INTEGER_DIVIDE_BY_ZERO:
                begin
                  Result.Status:=ST_CRASH_B;
                  Result.Information:=de.Exception.ExceptionRecord.ExceptionCode;
                  TerminateProcess(pi.hProcess,de.Exception.ExceptionRecord.ExceptionCode);
                end;    }
                STATUS_BREAKPOINT:; {Every program will have a breakpoint at starting}
                STATUS_SEGMENT_NOTIFICATION:; {only 16bit DOS want this}
                else begin
                  Result.Status:=ST_CRASH;
                  Result.Time:=0;
                  Result.Information:=de.Exception.ExceptionRecord.ExceptionCode;
                  //经过测试直接传String无法得到值，只能传Cardinal
                  TerminateProcess(pi.hProcess,de.Exception.ExceptionRecord.ExceptionCode);
                  {
                    删掉原Cena的判崩溃方式
                    除STATUS_BREAKPOINT与STATUS_SEGMENT_NOTIFICATION均统一响应
                  }
                end;

                
           end;
        end;
        CREATE_THREAD_DEBUG_EVENT:;
        CREATE_PROCESS_DEBUG_EVENT: CloseHandle(de.CreateProcessInfo.hFile);
        EXIT_THREAD_DEBUG_EVENT:;
        EXIT_PROCESS_DEBUG_EVENT:
          begin
            if de.dwProcessId=pi.dwProcessId then begin
              if Result.Status=ST_UNKNOWN then
                Result.Status:=ST_OK;
                {
                  这里有两种情况：
                  一、正常结束
                  二、编译器已经处理一些错误，比如数组下溢，以致程序不崩溃，然后结束程序
                }

              Result.Information:=de.ExitProcess.dwExitCode;    //详细说明参见该模块文档的“补充说明”部分
              ProcessRunning:=False;
            end;
          end;
        LOAD_DLL_DEBUG_EVENT:CloseHandle(de.LoadDll.hFile);
        UNLOAD_DLL_DEBUG_EVENT:;
        OUTPUT_DEBUG_STRING_EVENT:;
        RIP_EVENT:;
        end;
        if not ProcessRunning then Break;
      end;
      if not ProcessRunning then break;
      CheckLimitResultA:=CheckLimits(pi,TimeLimit,MemoryLimit);
      Result.Status:=CheckLimitResultA.Status;
      Result.Time:=CheckLimitResultA.Time;
      Result.Memory:=CheckLimitResultA.Memory;
    until not ProcessRunning;

 end else begin
   Result.Status:=ST_CANNOT_EXECUTE;
   Result.Time:=0;
   Result.Information:=0;
   Result.Memory:=0;
 end;
 CloseHandle(pi.hProcess);
 CloseHandle(pi.hThread);
end;


end.
