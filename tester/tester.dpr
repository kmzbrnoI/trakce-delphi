program tester;

uses
  Forms,
  fTester in 'fTester.pas' {F_Tester},
  Trakce in '..\Trakce.pas',
  TrakceErrors in '..\TrakceErrors.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TF_Tester, F_Tester);
  Application.Run;
end.
