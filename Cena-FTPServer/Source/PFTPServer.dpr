program PFTPServer;

uses
  Forms,
  MainForm in 'MainForm.pas' {FTPServer},
  My_SelectDir in 'My_SelectDir.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'FTP Server - Cena2';
  Application.CreateForm(TFTPServer, FTPServer);
  Application.Run;
end.
