{*******************************************************************************

                CenaLite - Compare Library

      File:                 CompareU.pas
      Created By:           Cena
      Modification Date:    2011-1-17

      Copyright (c) 2010-2011 Cena

*******************************************************************************}


unit CompareU;

interface
function Compare(fn1,fn2: pwidechar; var Report: widestring): integer;
function CompareBin(fn1,fn2: pwidechar; var Report: widestring): integer;

implementation
uses SysUtils, windows, dialogs;

const
  bufsize=65536;
  _n=#13#10;
  ST_CORRECT                           =  7             ;  // ��ȷ
  ST_WRONG_ANSWER                      =  8             ;  // ����Ĵ�
  //ST_PART_CORRECT                      =  9             ;  // �ò��ַ�
  ST_PROGRAM_NO_OUTPUT                 =  10            ;  // ���������
  //ST_NO_STANDARD_INPUT                 =  12            ;  // �ޱ�׼����
  ST_NO_STANDARD_OUTPUT                =  13            ;  // �ޱ�׼���
type
  Tbuf=array[0..bufsize-1]of AnsiChar;
  Tchar=record
    have: boolean;
    eml: cardinal;
    he: boolean;
    c: AnsiChar;
  end;


var
  f: array[0..1]of cardinal;
  fs: array[0..1]of int64;
  buf: array[0..1]of Tbuf;
  bp: array[0..1]of cardinal;
  line: cardinal;
  col: array[0..1]of cardinal;
  readed: array[0..1]of cardinal;

  chars: array[0..1]of Tchar;


  checked: int64;


function ReadChar(i: integer): AnsiChar;
var
  x: cardinal;
begin
  if readed[i]=fs[i] then Result:=#0
  else begin
    if bp[i]=bufsize then begin
      ReadFile(f[i],buf[i],bufsize,x,nil);
      bp[i]:=0;
    end;
    result:=buf[i][bp[i]];
    inc(bp[i]);
    inc(readed[i]);
  end;
end;

function GetStr(i,long: integer): string;
var
  j: integer;
  ch: AnsiChar;
begin
  result:='';
  for j:=1 to long do begin
    ch:=ReadChar(i);
    if (ch=#13)or(ch=#10)or(ch=#0) then exit;
    result:=result+ch;
  end;
end;

procedure GetChar(fi: integer);
var
  ch: AnsiChar;
  last: AnsiChar;
begin
  with chars[fi] do begin

  last:=#0;
  repeat
    ch:=ReadChar(fi);
{
    if readed[i]=fs[i] then ch:=#0
    else begin
      if bp[i]=bufsize then begin
        ReadFile(f[i],buf[i],bufsize,x,nil);
        bp[i]:=0;
      end;
      ch:=buf[i][bp[i]];
      inc(bp[i]);
      inc(readed[i]);
    end;
}
    if ch=#0 then exit;

    if ch=#10 then begin
      if last<>#13 then inc(eml);
      col[fi]:=0;
      he:=false;
    end else
      if ch=#13 then begin
        inc(eml);
        col[fi]:=0;
        he:=false;
      end else begin
        inc(col[fi]);
        if ch=' ' then begin
          if eml=0 then he:=true;
        end else begin
          c:=ch;
          break;
        end;
      end;

    last:=ch;
  until false;
  have:=true;

  if fi=0 then inc(line,eml);

  end;
end;

function MakeLine(i: integer): string;
var
  st: string;
begin
  result:='';
  with chars[i] do begin

  if eml=0 then result:=result+'...';
  if he then result:=result+' ';
  result:=result+c;
  st:=GetStr(i,6);
  if Length(st)>5 then result:=result+copy(st,1,5)+'...'
  else result:=result+st;

  end;
end;

function CheckNow(fn1,fn2: pwidechar; var Report: widestring):integer;
begin
//  Report^:='no difference.';
  result:=ST_CORRECT;
  fillchar(chars,2*sizeof(Tchar),0);
  chars[0].eml:=1;
  chars[1].eml:=1;

  repeat
    GetChar(0);
    GetChar(1);

    if (not chars[0].have)and(not chars[1].have) then exit;
    if (chars[0].have)and(not chars[1].have) then begin
      Report:='ѡ������ȱ�׼�������';
      result:=ST_WRONG_ANSWER;
      exit;
    end;
    if (chars[1].have)and(not chars[0].have) then begin
      result:=ST_WRONG_ANSWER;
      Report:='��׼�����ѡ���������';
      exit;
    end;
    if (chars[0].eml>chars[1].eml) then begin
      result:=ST_WRONG_ANSWER;
      Report:=      '�ڵ� '+IntToStr(line-(chars[0].eml-chars[1].eml))+' ��:'+_n+
                     '----ѡ������ĵ� '+IntToStr(col[0])+' ��----'+_n+
                     '>(��)'+_n+
                     '----��׼����ĵ� '+IntToStr(col[1])+' ��----'+_n+
                     '>'+MakeLine(1)
                    ;
      exit;
    end;
    if (chars[1].eml>chars[0].eml) then begin
      result:=ST_WRONG_ANSWER;
      Report:=       '�ڵ� '+IntToStr(line)+' ��:'+_n+
                     '----ѡ������ĵ� '+IntToStr(col[0])+' ��----'+_n+
                     '>'+MakeLine(0)+_n+
                     '----��׼����ĵ� '+IntToStr(col[1])+' ��----'+_n+
                     '>(��)'
              ;
      exit;
    end;
    if (chars[0].he<>chars[1].he)or(chars[0].c<>chars[1].c) then begin
      result:=ST_WRONG_ANSWER;
      Report:=       '�ڵ� '+IntToStr(line)+' ��:'+_n+
                     '----ѡ������ĵ� '+IntToStr(col[0])+' ��----'+_n+
                     '>'+MakeLine(0)+_n+
                     '----��׼����ĵ� '+IntToStr(col[1])+' ��----'+_n+
                     '>'+MakeLine(1)
              ;
      exit;
    end;

    fillchar(chars,2*sizeof(Tchar),0);
  until false;
end;


function Compare(fn1,fn2: pwidechar; var Report: widestring): integer;
{
   ���׿ո���β�ո񽫱�����
   ���еĶ���ո񽫱�ѹ����һ���ո�

   ������ո���ļ�β�Ŀ���Ҳ�������Ե�
}
label
 Start;
begin
  Start:
  f[0]:=CreateFileW(fn1,GENERIC_READ,FILE_SHARE_READ,nil,OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,0);
  if f[0]=INVALID_HANDLE_VALUE then begin

    if GetLastError=ERROR_SHARING_VIOLATION then goto Start;


    result:=ST_PROGRAM_NO_OUTPUT;
    exit;
  end
  else
    fs[0]:=GetFileSize(f[0],nil);

  f[1]:=CreateFileW(fn2,GENERIC_READ,FILE_SHARE_READ,nil,OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,0);
  if f[1]=INVALID_HANDLE_VALUE then begin

    if GetLastError=ERROR_SHARING_VIOLATION then goto Start;

    windows.CloseHandle(f[0]);
    result:=ST_NO_STANDARD_OUTPUT;
    exit;
  end
  else
    fs[1]:=GetFileSize(f[1],nil);

  // Init
  bp[0]:=bufsize;
  bp[1]:=bufsize;
  line:=0;
  fillchar(col,sizeof(col),0);
  fillchar(readed,sizeof(readed),0);

  // check now
  result:=CheckNow(fn1,fn2,Report);

  windows.CloseHandle(f[0]);
  windows.CloseHandle(f[1]);

end;


function SameStr(x: integer): boolean;
var
  i: integer;
begin
  Result:=false;
  for i:=0 to x-1 do
    if buf[0][i]=buf[1][i] then inc(Checked)
    else exit;
  Result:=true;
end;


function CompareBin(fn1,fn2: pwidechar; var Report: widestring): integer;
var
  x: cardinal;
begin
  f[0]:=CreateFileW(fn1,GENERIC_READ,FILE_SHARE_READ,nil,OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,0);
  if f[0]=INVALID_HANDLE_VALUE then begin
    result:=ST_PROGRAM_NO_OUTPUT;
    exit;
  end
  else
    fs[0]:=GetFileSize(f[0],nil);

  f[1]:=CreateFileW(fn2,GENERIC_READ,FILE_SHARE_READ,nil,OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,0);
  if f[1]=INVALID_HANDLE_VALUE then begin
    windows.CloseHandle(f[0]);
    result:=ST_NO_STANDARD_OUTPUT;
    exit;
  end
  else
    fs[1]:=GetFileSize(f[1],nil);

  if fs[0]>fs[1] then begin
    Report:='ѡ������ȱ�׼�������';
    result:=ST_WRONG_ANSWER;
    CloseHandle(f[0]);
    CloseHandle(f[1]);
    exit;
  end;
  if fs[1]>fs[0] then begin
    Report:='��׼�����ѡ���������';
    result:=ST_WRONG_ANSWER;
    CloseHandle(f[0]);
    CloseHandle(f[1]);
    exit;
  end;

  Checked:=0;
  repeat
    ReadFile(f[0],buf[0],bufsize,x,nil);
    ReadFile(f[1],buf[1],bufsize,x,nil);
    if not SameStr(x){buf[0] & buf[1]}  then begin
      Report:='�ڵ�'+IntToStr(Checked)+'���ֽڴ����ֲ��';
      Result:=ST_WRONG_ANSWER;
      CloseHandle(f[0]);
      CloseHandle(f[1]);
      exit;
    end;
    if x=0 then break;
  until false;

  Result:=ST_CORRECT;
  CloseHandle(f[0]);
  CloseHandle(f[1]);
end;



end.

