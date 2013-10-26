program ProjectCenaLite;

uses
  Forms,
  MainFormU in 'MainFormU.pas' {MainForm},
  JudgeThreadU in 'JudgeThreadU.pas',
  CompareU in 'CompareU.pas',
  CheckUpdateU in 'CheckUpdateU.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'CenaLite!';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
