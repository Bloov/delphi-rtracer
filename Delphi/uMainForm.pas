unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  uImage2D, uVectors, uRenderer;

type
  TMainForm = class(TForm)
    pControls: TPanel;
    pRender: TPanel;
    imgRender: TImage;
    btnRender: TButton;
    Label1: TLabel;
    lblRenderTime: TLabel;
    dlgSaveImage: TSaveDialog;
    btnSaveImage: TButton;
    btnBenchmarkCamera: TButton;
    lbText: TListBox;
    btnClearText: TButton;
    btnBenchmarkScene: TButton;
    Label2: TLabel;
    lblRenderPerformance: TLabel;
    procedure btnRenderClick(Sender: TObject);
    procedure btnSaveImageClick(Sender: TObject);
    procedure btnBenchmarkCameraClick(Sender: TObject);
    procedure btnClearTextClick(Sender: TObject);
    procedure btnBenchmarkSceneClick(Sender: TObject);
  private
    procedure MakeTestScene(ARenderer: TRenderer);
    procedure MakeRandomSpheresScene(ARenderer: TRenderer);
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  VCL.Imaging.PngImage, uScene, uCamera, uHitable, uMaterial, uColor, uRay, uMathUtils;

procedure TMainForm.AfterConstruction;
begin
  Randomize;
end;

procedure TMainForm.BeforeDestruction;
begin
end;

procedure TMainForm.MakeTestScene(ARenderer: TRenderer);
begin
  ARenderer.SetCamera(TPerspectiveCamera.Create(Vec3F(3, 3, 2), Vec3F(0, 0, -1), Vec3F(0, 1, 0), 45, 0.0));
  //ARenderer.SetCamera(TPerspectiveCamera.Create(Vec3F(2, 0, 1), Vec3F(0, 0, -1), Vec3F(0, 1, 0), 55, 0.0));

  ARenderer.Scene.Add(TSphere.Create(Vec3F(0, 0, -1), 0.5, TLambertian.Create(ColorVec(0.1, 0.2, 0.5))));
  //ARenderer.Scene.Add(TSphere.Create(Vec3F(0, 0, -1), 0.5, TDielectric.Create(1.5)));
  ARenderer.Scene.Add(TSphere.Create(Vec3F(0, -100.5, -1), 100, TLambertian.Create(ColorVec(0.8, 0.8, 0.0))));
  ARenderer.Scene.Add(TSphere.Create(Vec3F(1, 0, -1), 0.5, TMetal.Create(ColorVec(0.8, 0.6, 0.2), 0.2)));
  //ARenderer.Scene.Add(TSphere.Create(Vec3F(-1, 0, -1), 0.5, TLambertian.Create(ColorVec(0.1, 0.2, 0.5))));
  ARenderer.Scene.Add(TSphere.Create(Vec3F(-1, 0, -1), 0.5, TDielectric.Create(1.5)));
  ARenderer.Scene.Add(TSphere.Create(Vec3F(-1, 0, -1), -0.45, TDielectric.Create(1.5)));

  ARenderer.Scene.BuildBVH(ARenderer.Camera.Time0, ARenderer.Camera.Time1);
end;

procedure TMainForm.MakeRandomSpheresScene(ARenderer: TRenderer);
var
  A, B: Integer;
  MatProb: Single;
  Center: TVec3F;
begin
  ARenderer.SetCamera(TPerspectiveCamera.Create(Vec3F(13, 2, 3), Vec3F(0, 0, 0), Vec3F(0, 1, 0), 30, 0.0, 10));
  ARenderer.Camera.SetupFrameTime(0, 1);

  ARenderer.Scene.Add(TSphere.Create(Vec3F(0, -1000, 0), 1000, TLambertian.Create(ColorVec(0.5, 0.5, 0.5))));
  for A := -11 to 11 do
    for B := -11 to 11 do
    begin
      MatProb := RandomF;
      Center := Vec3F(A + 0.9 * RandomF, 0.2, B + 0.9 * RandomF);
      if (Center - Vec3F(4, 0.2, 0)).Length > 0.9 then
      begin
        if MatProb < 0.75 then
          ARenderer.Scene.Add(
            TMovingSphere.Create(Center, Center + Vec3F(0, 0.5 * RandomF, 0), 0.2, 0, 1, TLambertian.Create(ColorVec(RandomF * RandomF, RandomF * RandomF, RandomF * RandomF))))
        else if MatProb < 0.95 then
          ARenderer.Scene.Add(
            TSphere.Create(Center, 0.2, TMetal.Create(ColorVec(0.5 * (1 + RandomF), 0.5 * (1 + RandomF), 0.5 * (1 + RandomF)), 0.5 * RandomF)))
        else
          ARenderer.Scene.Add(
            TSphere.Create(Center, 0.2, TDielectric.Create(1.5)));
      end;
    end;

  ARenderer.Scene.Add(TSphere.Create(Vec3F(0, 1, 0), 1, TDielectric.Create(1.5)));
  ARenderer.Scene.Add(TSphere.Create(Vec3F(-4, 1, 0), 1, TLambertian.Create(ColorVec(0.4, 0.2, 0.1))));
  ARenderer.Scene.Add(TSphere.Create(Vec3F(4, 1, 0), 1, TMetal.Create(ColorVec(0.7, 0.6, 0.5), 0)));

  ARenderer.Scene.BuildBVH(ARenderer.Camera.Time0, ARenderer.Camera.Time1);
end;

procedure TMainForm.btnBenchmarkCameraClick(Sender: TObject);
const
  cSPP = 10;
var
  Camera: TPerspectiveCamera;
  StartTime, EndTime, Freq: Int64;
  X, Y, S: Integer;
  U, V: Single;
  Ray: TRay;
  TotalRays, TotalTime: Single;
begin
  Camera := TPerspectiveCamera.Create(Vec3F(13, 2, 3), Vec3F(0, 0, 0), Vec3F(0, 1, 0), 45, 0.05, 10);
  try
    Camera.SetupView(1024, 1024);
    QueryPerformanceCounter(StartTime);
      for Y := 0 to 1023 do
        for X := 0 to 1023 do
        begin
          U := X / 1024;
          V := Y / 1024;
          for S := 1 to cSPP do
            Ray := Camera.GetRay(U, V);
        end;
    QueryPerformanceCounter(EndTime);
    QueryPerformanceFrequency(Freq);

    TotalTime := (EndTime - StartTime) / Freq;
    TotalRays := 1024 * 1024 * cSPP;
    lbText.Items.Add('Camera performance:');
    lbText.Items.Add(Format('  %.3f MRays per second', [TotalRays / (TotalTime * 1e6)]));
  finally
    FreeAndNil(Camera);
  end;
end;

procedure TMainForm.btnBenchmarkSceneClick(Sender: TObject);
const
  cSPP = 10;
var
  Renderer: TRenderer;
  Image: TImage2D;
  StartTime, EndTime, Freq: Int64;
  TotalRays, TotalTime: Single;
begin
  Image := nil;
  Renderer := TRenderer.Create(TScene.Create);
  try
    MakeRandomSpheresScene(Renderer);

    QueryPerformanceCounter(StartTime);
      Image := Renderer.Render(512, 512, cSPP);
    QueryPerformanceCounter(EndTime);
    QueryPerformanceFrequency(Freq);

    TotalTime := (EndTime - StartTime) / Freq;
    TotalRays := Renderer.EmitedRays;
    lbText.Items.Add('Render performance:');
    lbText.Items.Add(Format('  total time %.3f seconds', [TotalTime]));
    lbText.Items.Add(Format('  %.3f MRays per second', [TotalRays / (TotalTime * 1e6)]));

    imgRender.Picture.Bitmap := Image.GetAsBitmap;
  finally
    FreeAndNil(Image);
    FreeAndNil(Renderer);
  end;
end;

procedure TMainForm.btnClearTextClick(Sender: TObject);
begin
  lbText.Items.Clear;
end;

procedure TMainForm.btnRenderClick(Sender: TObject);
const
  cSPP = 10;
  cDivRes = 1;
var
  Renderer: TRenderer;
  Image: TImage2D;
  TargetWidth, TargetHeight: Integer;
  StartTime, EndTime, Freq: Int64;
  TotalRays, TotalTime: Single;
begin
  Image := nil;
  Renderer := TRenderer.Create(TScene.Create);
  try
    //MakeRandomSpheresScene(Renderer);
    MakeTestScene(Renderer);
    TargetWidth := imgRender.ClientWidth div cDivRes;
    TargetHeight := imgRender.ClientHeight div cDivRes;

    QueryPerformanceCounter(StartTime);
      Image := Renderer.Render(TargetWidth, TargetHeight, cSPP);
    QueryPerformanceCounter(EndTime);
    QueryPerformanceFrequency(Freq);

    TotalTime := (EndTime - StartTime) / Freq;
    TotalRays := Renderer.EmitedRays;
    lblRenderTime.Caption := Format('%.3f', [TotalTime]);
    lblRenderPerformance.Caption := Format('%.3f', [TotalRays / (TotalTime * 1e6)]);
    imgRender.Picture.Bitmap := Image.GetAsBitmap;
  finally
    FreeAndNil(Image);
    FreeAndNil(Renderer);
  end;
end;

procedure TMainForm.btnSaveImageClick(Sender: TObject);
var
  Png: TPngImage;
begin
  if imgRender.Picture.Bitmap = nil then
    Exit;

  if dlgSaveImage.Execute(Handle) then
  begin
    Png := TPngImage.Create;
    try
      Png.Assign(imgRender.Picture.Bitmap);
      Png.SaveToFile(dlgSaveImage.FileName);
    finally
      Png.Free;
    end;
  end;
end;

end.
