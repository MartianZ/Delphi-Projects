unit My_SelectDir;
interface
uses ShlObj, ActiveX, Windows, Forms;
function SelectDir(
    Owner         : THandle; //父窗口的句柄
    const Title   : string; //搜索标题
    const RemText : string; //树形框上面的说明，支持#10
    Root          : string; //根目录，''为我的电脑，可以指定例如C:\之类的
    var DefaultDir : string) //默认路径，也是接受路径
                 : boolean; //[OK]->True 否则false
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
    SendMessage(hWin, BFFM_SETSELECTION, 1, lpData); //用传过来的参数作默认路径
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
bi.ulFlags   := BIF_RETURNONLYFSDIRS OR BIF_NEWDIALOGSTYLE;//BIF_NEWDIALOGSTYLE，显示"新建文件夹"按钮
bi.lpfn      := @BrowseProc;
bi.lParam    := longint(defaultDir);      //重点是增加了这个
//设置起始路径
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
