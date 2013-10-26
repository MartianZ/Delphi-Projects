{*******************************************************************************

                CenaLite - CheckUpdate Library

      File:                 CheckUpdateU.pas
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
unit CheckUpdateU;


interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Dialogs, StdCtrls, ComCtrls, ShellApi, Forms;
type
  TUpdateThread = class(TThread)
  public
    constructor Create;
  protected
    procedure Execute; override;
    procedure MessageA;
    procedure MessageB;
  end;

implementation

uses
  MainFormU;



procedure TUpdateThread.Execute;
const
  UpdateURL = 'http://api.cena2.org/CenaLiteUpdate.php?version=';
  CurrentVersion = '20110211';
var
  HTTPResult:string;
begin
  try
      HTTPResult:=MainForm.idhtp1.Get(UpdateURL+CurrentVersion);
      if HTTPResult='UpdateRequired' then
          Synchronize(MessageA)
      else if HTTPResult='UpdateRequired!' then
          Synchronize(MessageB);
  finally
    MainForm.idhtp1.Free;
  end;
end;

procedure TUpdateThread.MessageA;
begin
  if MessageBoxW(MainForm.Handle, '软件检测到官方有新版本发布，是否打开官方网站？', '更新提示', MB_YESNO +
    MB_ICONQUESTION + MB_TOPMOST) = IDYES then
  begin
    ShellExecute(0,nil,'http://www.cena2.org', nil, nil, SW_SHOWNORMAL);
    Application.Terminate;
  end;
end;

procedure TUpdateThread.MessageB;

begin
  MessageBoxW(MainForm.Handle, '软件检测到您当前的版本已经过期，单击确定引导您到官方网站下载新版！', '更新提示', MB_OK +
    MB_ICONSTOP + MB_TOPMOST);
  ShellExecute(0,nil,'http://www.cena2.org', nil, nil, SW_SHOWNORMAL);
  Application.Terminate;
end;

constructor TUpdateThread.Create;
begin
FreeOnTerminate:=True;
inherited Create(False); //立即执行
end;

end.
