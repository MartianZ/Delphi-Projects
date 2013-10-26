unit TimerOne;

{
 ��Cena�������ʱ���ڴ���ģ��
 ��Cena�Ļ����������޸�
 Martian 2010��12��4��
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

  ST_UNKNOWN                      =  0             ;  // δ֪
  ST_OK                           =  1             ;  // ����
  ST_CANNOT_EXECUTE               =  2             ;  // �޷�����
  ST_TIME_LIMIT_EXCEEDED          =  3             ;  // ��ʱ
  ST_MEMORY_LIMIT_EXCEEDED        =  4             ;  // ���ڴ�
  ST_RUNTIME_ERROR                =  5             ;  // ����ʱ����
  ST_CRASH                        =  6             ;  // ����
  //SystemPerformanceInformation = 2;
var
  //LastIdleTime:Int64;
  ProcessRunning:Boolean;
  JudgeFaster:Boolean;
  
function Exec(Cmd:string;TimeLimit:Cardinal{����ʱ�� ��λ����};MemoryLimit:Integer{�����ڴ� ��λkb};JudgeFasterA:Boolean):ReturnResult;
  
implementation

function NtQuerySystemInformation(infoClass: DWORD; buffer: Pointer;
  bufSize: DWORD; returnSize: PDword):DWORD; stdcall external 'ntdll.dll';
function CheckLimits(var pi:PROCESS_INFORMATION;TimeLimit:Cardinal{����ʱ�� ��λ����};MemoryLimit:Integer{�����ڴ� ��λkb}):CheckLimitResult;
var
  ct,et,kt,ut,ut2:FILETIME;
  Time:Double;
  TimeLimitMax:Double; //����ʱ��(s)  TimeLimit��������Ժ�*3
  pmc:_PROCESS_MEMORY_COUNTERS;
begin
  Result.Status:=ST_OK;
  Result.Time:=0;
  Result.Memory:=0;

  GetProcessTimes(pi.hProcess,ct,et,kt,ut);  //��ȡ���̵�ʱ�� ����ҪUserTime �û�ʱ��
  ut2:=ut; //��ΪInt64(ut)���޸�ָ�� ���Ա���һ��
  {
    Cena�ļ�ʱģʽ���о���
     ���г�������У��û�ʱ���ȥ�������̵��������ص�CPU����ʱ��
     �������ִ������Ժ�û�г�ʱ����ӽ�Ҫ��ֱ��ʹ���û�ʱ��
     �о����һ��
     �������´����ʹ��UserTime ��ʱ������CPU����ʱ��
     ����Martian 2010��12��4��
  }
  if JudgeFaster then
  TimeLimitMax:=TimeLimit/1000 //�ִ��ʱ��
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

  //16bit�����޷���ȡ�ڴ� Cena�н������ж�
  //�������ڵ��°�����������ٱ���16BIT���� ���Կ���ֱ��ȡ�ڴ�
  try
    ZeroMemory(@pmc,sizeof(pmc));
    pmc.cb:=sizeof(pmc);
    GetProcessMemoryInfo(pi.hProcess,@pmc,sizeof(pmc));
    Result.Memory:=pmc.PeakPagefileUsage shr 10;
    if Result.Memory>MemoryLimit then begin
      { �����ڴ����� }
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
   { ����ʱ������ }
  end;
  if Time>TimeLimitMax then
  begin
   Result.Status:=ST_TIME_LIMIT_EXCEEDED;
   Result.Time:=-1;
   TerminateProcess(pi.hProcess,1);
   { ��������ʱ������ ���� ͬʱ�������� }
  end;
end;

function ExtractFilePath(const FileName: string): string;
var
  I: Integer;
begin
  I := LastDelimiter(PathDelim + DriveDelim, FileName);
  Result := Copy(FileName, 1, I);
end;

function Exec(Cmd:AnsiString;TimeLimit:Cardinal{����ʱ�� ��λ����};MemoryLimit:Integer{�����ڴ� ��λkb};JudgeFasterA:Boolean{�Ƿ����ÿ�������}):ReturnResult;
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
 //���´�����޸���CenaԴ����
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
                  //��������ֱ�Ӵ�String�޷��õ�ֵ��ֻ�ܴ�Cardinal
                  TerminateProcess(pi.hProcess,de.Exception.ExceptionRecord.ExceptionCode);
                  {
                    ɾ��ԭCena���б�����ʽ
                    ��STATUS_BREAKPOINT��STATUS_SEGMENT_NOTIFICATION��ͳһ��Ӧ
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
                  ���������������
                  һ����������
                  �����������Ѿ�����һЩ���󣬱����������磬���³��򲻱�����Ȼ���������
                }

              Result.Information:=de.ExitProcess.dwExitCode;    //��ϸ˵���μ���ģ���ĵ��ġ�����˵��������
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
