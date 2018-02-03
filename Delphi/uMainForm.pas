unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  uImage2D, uVectors, uRenderer, OtlSync;

type
  TMainForm = class(TForm)
    pControls: TPanel;
    pRender: TPanel;
    imgRender: TImage;
    btnRenderControl: TButton;
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
    btnBenchmarkAABB: TButton;
    btnBenchmarkRotate: TButton;
    btnBenchmarkHit: TButton;
    btnSetupRender: TButton;
    btnSetupScene: TButton;
    cbUseViewportSize: TCheckBox;
    Label3: TLabel;
    lblRenderProgress: TLabel;
    procedure btnRenderClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnSaveImageClick(Sender: TObject);
    procedure btnBenchmarkCameraClick(Sender: TObject);
    procedure btnClearTextClick(Sender: TObject);
    procedure btnBenchmarkSceneClick(Sender: TObject);
    procedure btnBenchmarkAABBClick(Sender: TObject);
    procedure btnBenchmarkRotateClick(Sender: TObject);
    procedure btnBenchmarkHitClick(Sender: TObject);
    procedure btnSetupRenderClick(Sender: TObject);
  private
    FGlobalRenderer: TRenderer;
    FRenderOptions: TRenderOptions;
    FCancelToken: IOmniCancellationToken;

    procedure MakeTestScene(ARenderer: TRenderer; ASeed: Integer);
    procedure MakeRandomSpheresScene(ARenderer: TRenderer; ASeed: Integer);
  public
    destructor Destroy; override;

    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  VCL.Imaging.PngImage, Math, uRenderSetup,
  uMathUtils, uAABB, uSamplingUtils,
  uScene, uCamera, uHitable, uRay,
  uMaterial, uColor, uTexture, uBenchmarks,
  OtlParallel, OtlCommon;

destructor TMainForm.Destroy;
begin
  inherited;
end;

procedure TMainForm.AfterConstruction;
begin
  Randomize;
  cbUseViewportSize.Checked := True;
  FRenderOptions := TRenderOptions.Create;
  FGlobalRenderer := TRenderer.Create();
end;

procedure TMainForm.BeforeDestruction;
begin
  FreeAndNil(FRenderOptions);
  FreeAndNil(FGlobalRenderer);
end;

procedure TMainForm.MakeTestScene(ARenderer: TRenderer; ASeed: Integer);
var
  Checker: TTexture;
begin
  RandSeed := ASeed;

  //ARenderer.SetCamera(TPerspectiveCamera.Create(Vec3F(3, 3, 2), Vec3F(0, 0, -1), Vec3F(0, 1, 0), 45, 0.0));
  ARenderer.SetCamera(TPerspectiveCamera.Create(Vec3F(13, 2, 3), Vec3F(0, 0, 0), Vec3F(0, 1, 0), 35, 0.05));

  Checker := TCheckerTexture.Create(TConstantTexture.Create(ColorVec(0.2, 0.3, 0.1)),
                                    TConstantTexture.Create(ColorVec(0.9, 0.9, 0.9)), True);
  ARenderer.Scene.Add(TSphere.Create(Vec3F(0, -10, 0), 10, TLambertian.Create(Checker)));
  ARenderer.Scene.Add(TSphere.Create(Vec3F(0, +10, 0), 10, TLambertian.Create(Checker, False)));

  {ARenderer.Scene.Add(TSphere.Create(Vec3F(0, 0, -1), 0.5, TLambertian.Create(TConstantTexture.Create(ColorVec(0.1, 0.2, 0.5)))));
  //ARenderer.Scene.Add(TSphere.Create(Vec3F(0, 0, -1), 0.5, TDielectric.Create(1.5)));
  ARenderer.Scene.Add(TSphere.Create(Vec3F(0, -100.5, -1), 100, TLambertian.Create(TConstantTexture.Create(ColorVec(0.8, 0.8, 0.0)))));
  ARenderer.Scene.Add(TSphere.Create(Vec3F(1, 0, -1), 0.5, TMetal.Create(ColorVec(0.8, 0.6, 0.2), 0.2)));
  //ARenderer.Scene.Add(TSphere.Create(Vec3F(-1, 0, -1), 0.5, TLambertian.Create(ColorVec(0.1, 0.2, 0.5))));
  ARenderer.Scene.Add(TSphere.Create(Vec3F(-1, 0, -1), 0.5, TDielectric.Create(1.5)));
  ARenderer.Scene.Add(TSphere.Create(Vec3F(-1, 0, -1), -0.45, TDielectric.Create(1.5)));}

  //ARenderer.Scene.BuildBVH(ARenderer.Camera.Time0, ARenderer.Camera.Time1);
end;

procedure TMainForm.MakeRandomSpheresScene(ARenderer: TRenderer; ASeed: Integer);
const
  cLambertProb = 0.75;
  cMetalProb = 0.90;
var
  A, B: Integer;
  MatProb: Single;
  Center: TVec3F;
  Checker: TTexture;
begin
  RandSeed := ASeed;

  ARenderer.SetCamera(TPerspectiveCamera.Create(Vec3F(13, 2, 3), Vec3F(0, 0, 0), Vec3F(0, 1, 0), 30, 0.05, 10));
  ARenderer.Camera.SetupFrameTime(0, 1);

  Checker := TCheckerTexture.Create(TConstantTexture.Create(ColorVec(0.2, 0.3, 0.1)),
                                    TConstantTexture.Create(ColorVec(0.9, 0.9, 0.9)), True);
  ARenderer.Scene.Add(TSphere.Create(Vec3F(0, -1000, 0), 1000, TLambertian.Create(Checker)));
  for A := -11 to 11 do
    for B := -11 to 11 do
    begin
      MatProb := RandomF;
      Center := Vec3F(A + 0.9 * RandomF, 0.2, B + 0.9 * RandomF);
      if (Center - Vec3F(4, 0.2, 0)).Length > 0.9 then
      begin
        if MatProb < cLambertProb then
          ARenderer.Scene.Add(
            TMovingSphere.Create(Center, Center + Vec3F(0, 0.5 * RandomF, 0), 0.2, 0, 1,
              TLambertian.Create(TConstantTexture.Create(ColorVec(RandomF * RandomF, RandomF * RandomF, RandomF * RandomF)))))
        else if MatProb < cMetalProb then
          ARenderer.Scene.Add(
            TSphere.Create(Center, 0.2, TMetal.Create(ColorVec(0.5 * (1 + RandomF), 0.5 * (1 + RandomF), 0.5 * (1 + RandomF)), 0.5 * RandomF)))
        else
          ARenderer.Scene.Add(
            TSphere.Create(Center, 0.2, TDielectric.Create(1.5)));
      end;
    end;

  ARenderer.Scene.Add(TSphere.Create(Vec3F(0, 1, 0), 1, TDielectric.Create(1.5)));
  ARenderer.Scene.Add(TSphere.Create(Vec3F(-4, 1, 0), 1, TLambertian.Create(TConstantTexture.Create(ColorVec(0.4, 0.2, 0.1)))));
  ARenderer.Scene.Add(TSphere.Create(Vec3F(4, 1, 0), 1, TMetal.Create(ColorVec(0.7, 0.6, 0.5), 0)));

  ARenderer.Scene.BuildBVH(ARenderer.Camera.Time0, ARenderer.Camera.Time1);
end;

procedure TMainForm.btnBenchmarkAABBClick(Sender: TObject);
var
  TotalHits, TotalAsm, TotalNative: Single;
begin
  btnBenchmarkAABB.Enabled := False;
  Async(
    procedure
    begin
      BenchmarkAABB(TotalHits, TotalAsm, TotalNative);
    end)
  .Await(
    procedure
    begin
      btnBenchmarkAABB.Enabled := True;

      lbText.Items.Add('AABB performance:');
      lbText.Items.Add(Format('  total time %.3f seconds', [TotalAsm]));
      lbText.Items.Add(Format('  %.3f MHits per second', [TotalHits / (TotalAsm * 1e6)]));


      lbText.Items.Add('Native AABB performance:');
      lbText.Items.Add(Format('  total time %.3f seconds', [TotalNative]));
      lbText.Items.Add(Format('  %.3f MHits per second', [TotalHits / (TotalNative * 1e6)]));
    end);
end;

procedure TMainForm.btnBenchmarkCameraClick(Sender: TObject);
var
  TotalRays, TotalTime: Single;
begin
  btnBenchmarkCamera.Enabled := False;
  Async(
    procedure
    begin
      BenchmarkCamera(TotalRays, TotalTime);
    end)
  .Await(
    procedure
    begin
      lbText.Items.Add('Camera performance:');
      lbText.Items.Add(Format('  %.3f MRays per second', [TotalRays / (TotalTime * 1e6)]));
      btnBenchmarkCamera.Enabled := True;
    end);
end;

procedure TMainForm.btnBenchmarkHitClick(Sender: TObject);
var
  TotalHits, TotalTime: Single;
begin
  btnBenchmarkHit.Enabled := False;
  Async(
    procedure
    begin
      BenchmarkHit(TotalHits, TotalTime);
    end)
  .Await(
    procedure
    begin
      btnBenchmarkHit.Enabled := True;
      lbText.Items.Add('Hit performance:');
      lbText.Items.Add(Format('  total time %.3f seconds', [TotalTime]));
      lbText.Items.Add(Format('  %.3f MHits per second', [TotalHits / (TotalTime * 1e6)]));
    end);
end;

procedure TMainForm.btnBenchmarkRotateClick(Sender: TObject);
var
  TotalRotates, TotalAsm, TotalNative: Single;
  Success: Boolean;
begin
  btnBenchmarkRotate.Enabled := False;
  Async(
    procedure
    begin
      BenchmarkRotate(TotalRotates, TotalAsm, TotalNative, Success);
    end)
  .Await(
    procedure
    begin
      btnBenchmarkRotate.Enabled := True;

      lbText.Items.Add('Rotate performance:');
      lbText.Items.Add(Format('  total time %.3f seconds', [TotalAsm]));
      lbText.Items.Add(Format('  %.3f MRot per second', [TotalRotates / (TotalAsm * 1e6)]));

      lbText.Items.Add('Native rotate performance:');
      lbText.Items.Add(Format('  total time %.3f seconds', [TotalNative]));
      lbText.Items.Add(Format('  %.3f MRot per second', [TotalRotates / (TotalNative * 1e6)]));

      lbText.Items.Add(Format('Same results: %s', [BoolToStr(Success, True)]));
    end);
end;

procedure TMainForm.btnBenchmarkSceneClick(Sender: TObject);
const
  cSPP = 10;
var
  Renderer: TRenderer;
  Image: TImage2D;
  Stats: TRenderStatistics;
begin
  Image := nil;
  Renderer := TRenderer.Create();
  try
    Renderer.SetScene(TScene.Create);
    MakeRandomSpheresScene(Renderer, 117);

    Renderer.Options.CopyFrom(FRenderOptions);
    Renderer.Options.Width := 256;
    Renderer.Options.Height := 256;
    Renderer.Options.SamplesPerPixel := cSPP;

    Image := Renderer.Render;

    Stats := Renderer.GetStatistics;
    lbText.Items.Add('Render performance:');
    lbText.Items.Add(Format('  total time %.3f seconds', [Stats.TotalTime / 1e3]));
    lbText.Items.Add(Format('  %.3f MRays per second', [Stats.EmitedRays / (Stats.TotalTime * 1e3)]));

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
  cDivRes = 1;
var
  Options: TRenderOptions;
begin
  lblRenderProgress.Caption := '';
  lblRenderTime.Caption := '';
  lblRenderPerformance.Caption := '';
  btnRenderControl.Caption := 'Cancel Render';
  btnRenderControl.OnClick := btnCancelClick;

  FGlobalRenderer.SetScene(TScene.Create);
  MakeRandomSpheresScene(FGlobalRenderer, 117);
  //MakeTestScene(FGlobalRenderer, 117);

  Options := TRenderOptions.Create;
  try
    Options.CopyFrom(FRenderOptions);
    if cbUseViewportSize.Checked then
    begin
      Options.Width := imgRender.ClientWidth div cDivRes;
      Options.Height := imgRender.ClientHeight div cDivRes;
    end;

    FCancelToken := FGlobalRenderer.RenderAsync(Options,
      procedure(ARes: TBitmap; AStats: TRenderStatistics)
      begin
        imgRender.Picture.Bitmap := ARes;
        lblRenderProgress.Caption := Format('%.1f %%', [AStats.Progress * 100]);
        lblRenderTime.Caption := Format('%.3f', [AStats.TotalTime / 1000]);
        lblRenderPerformance.Caption := Format('%.3f', [AStats.EmitedRays / (AStats.TotalTime * 1e3)]);
        AStats.Free;
      end,
      procedure(ARes: TBitmap; AStats: TRenderStatistics)
      begin
        imgRender.Picture.Bitmap := ARes;
        lblRenderProgress.Caption := Format('%.1f %%', [AStats.Progress * 100]);
        lblRenderTime.Caption := Format('%.3f', [AStats.TotalTime / 1000]);
        lblRenderPerformance.Caption := Format('%.3f', [AStats.EmitedRays / (AStats.TotalTime * 1e3)]);
        AStats.Free;

        btnRenderControl.Caption := 'Render';
        btnRenderControl.OnClick := btnRenderClick;
        //btnRenderControl.Enabled := True;
      end);
  finally
    FreeAndNil(Options);
  end;
end;

procedure TMainForm.btnCancelClick(Sender: TObject);
begin
  //btnRenderControl.Enabled := False;
  FGlobalRenderer.CancelRender;
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

procedure TMainForm.btnSetupRenderClick(Sender: TObject);
var
  SetupDlg: TForm;
  Options: TRenderOptions;
begin
  Options := TRenderOptions.Create;
  SetupDlg := TSetupRender.Create(Self, Options);
  try
    Options.CopyFrom(FRenderOptions);
    if SetupDlg.ShowModal = mrOk then
      FRenderOptions.CopyFrom(Options);
  finally
    FreeAndNil(SetupDlg);
    FreeAndNil(Options);
  end;
end;

end.
