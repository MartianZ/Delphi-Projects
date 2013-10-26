unit My_SelectDir;
interface
uses ShlObj, ActiveX, Windows, Forms;
function SelectDir(
    Owner         : THandle; //�����ڵľ��
    const Title   : string; //��������
    const RemText : string; //���ο������˵����֧��#10
    Root          : string; //��Ŀ¼��''Ϊ�ҵĵ��ԣ�����ָ������C:\֮���
    var DefaultDir : string) //Ĭ��·����Ҳ�ǽ���·��
                 : boolean; //[OK]->True ����false
implementation
uses Controls, Dialogs;
var OpenTitle : string;
procedure CenterWindow(phWnd:HWND);
var
   hParentOrOwner : HWND;
   rc, rc2        : Windows.TRect;
   x,y            : integer;
begin
hParentOrOwner:=GetParent(phWnd);
if (hParentOrOwner=HWND(nil)) then
      SystemParametersInfo(SPI_GETWORKAREA, 0, @rc, 0)
else
      Windows.GetClientRect(hParentOrOwner, rc);
GetWindowRect(phWnd, rc2);
x:=((rc.Right-rc.Left) - (rc2.Right-rc2.Left)) div 2 + rc.Left;
y:=((rc.Bottom-rc.Top) - (rc2.Bottom-rc2.Top)) div 2 + rc.Top;
SetWindowPos(phWnd, HWND_TOP, x, y , 0, 0, SWP_NOSIZE);
end;
function BrowseProc(
    hWin   : THandle;
    uMsg   : Cardinal;
    lParam : LPARAM;
    lpData : LPARAM) : LRESULT; stdcall;
begin
if (uMsg = BFFM_INITIALIZED) then
begin
    SendMessage(hWin, BFFM_SETSELECTION, 1, lpData); //�ô������Ĳ�����Ĭ��·��
    SetWindowText(hWin, PChar(OpenTitle));
    CenterWindow(hWin);
end;
Result := 0;
end;
function SelectPath(
    Owner       : THandle;
    const Title   : string;
    const RemText : string;
    Root        : string;
    DefaultDir : PChar) : string;
var
bi                    : TBrowseInfo; //uses ShlObj
IdList,RootItemIDList : PItemIDList;
IDesktopFolder        : IShellFolder;
Eaten,Flags           : LongWord;
begin
result   :=   '';
FillChar(bi, SizeOf(bi), 0);
bi.hwndOwner := Owner;
OpenTitle    := Title;
bi.lpszTitle := PChar(RemText);
bi.ulFlags   := BIF_RETURNONLYFSDIRS OR BIF_NEWDIALOGSTYLE;//BIF_NEWDIALOGSTYLE����ʾ"�½��ļ���"��ť
bi.lpfn      := @BrowseProc;
bi.lParam    := longint(defaultDir);      //�ص������������
//������ʼ·��
if Root<>'' then
begin
    SHGetDesktopFolder(IDesktopFolder);
    IDesktopFolder.ParseDisplayName(Application.Handle,   nil,
    POleStr(WideString(Root)), Eaten, RootItemIDList, Flags);//uses   ActiveX
    bi.pidlRoot:=RootItemIDList;
end;
IdList       := SHBrowseForFolder(bi);
if IdList<>nil then
begin
    SetLength(result,   255);
    SHGetPathFromIDList(IdList,   PChar(result));
    result := string(pchar(result));
// if result<>'' then
// if result[Length(result)] <>'\' then
//     result   :=   result   +   '\';
    end;
end;
function SelectDir(
    Owner         : THandle;
    const Title   : string;
    const RemText : string;
    Root          : string;
    var DefaultDir : string) : boolean;
var
s          : string;
begin
s:=DefaultDir;
s:=SelectPath(Owner, Title, RemText, Root, PChar(s));
if (s<>'') then
begin
    if (s=DefaultDir) then
        Result:=false
    else
    begin
        DefaultDir:=s;
        Result:=true;
    end;
end
else
        Result:=false;
end;
end.
