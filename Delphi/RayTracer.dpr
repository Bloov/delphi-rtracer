program RayTracer;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  uImage2D in 'uImage2D.pas',
  uMathUtils in 'uMathUtils.pas',
  uVectors in 'uVectors.pas',
  uDynArrays in 'uDynArrays.pas',
  uRay in 'uRay.pas',
  uRenderer in 'uRenderer.pas',
  uColor in 'uColor.pas',
  uHitable in 'uHitable.pas',
  uScene in 'uScene.pas',
  uCamera in 'uCamera.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
