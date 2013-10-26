program ProjectJudgement;

uses
  Forms,
  JudgeFormU in 'JudgeFormU.pas' {JudgeForm},
  JudgeThreadU in 'JudgeThreadU.pas',
  CompareU in 'CompareU.pas',
  Crc32U in 'Crc32U.pas' {$R *.res};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Cena2.0 Judge Module';
  Application.CreateForm(TJudgeForm, JudgeForm);
  Application.Run;
end.
