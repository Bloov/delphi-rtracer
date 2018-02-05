unit uRenderer;

interface

uses
  Vcl.Graphics, uImage2D, uVectors, uRay, uColor, uScene, uCamera,
  OtlParallel, OtlCommon, OtlSync, OtlTask, OtlTaskControl;

type
  TRenderTarget = (rtColor, rtNormalColor, rtDepth, rtColorAtDepth, rtScatteredAtDepth);

  TRenderOptions = class
  private
    FRenderTarget: TRenderTarget;
    FDepthLimit: Integer;
    FTargetDepth: Integer;

    FGamma: Single;
    FWidth, FHeight: Integer;
    FSPP: Integer;

    FUseBlocks: Boolean;
    FBlockWidth, FBlockHeight: Integer;
    FBlockSPP: Integer;
  public
    constructor Create;

    function Copy(): TRenderOptions;
    procedure CopyFrom(AFrom: TRenderOptions);

    procedure SetToDefault;

    property RenderTarget: TRenderTarget read FRenderTarget write FRenderTarget;
    property DepthLimit: Integer read FDepthLimit write FDepthLimit;
    property TargetDepth: Integer read FTargetDepth write FTargetDepth;
    property Gamma: Single read FGamma write FGamma;
    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    property SamplesPerPixel: Integer read FSPP write FSPP;
    property UseBlocks: Boolean read FUseBlocks write FUseBlocks;
    property BlockWidth: Integer read FBlockWidth write FBlockWidth;
    property BlockHeight: Integer read FBlockHeight write FBlockHeight;
    property BlockSamplesPerPixel: Integer read FBlockSPP write FBlockSPP;
  end;

  TRenderStatistics = class
  private
    FEmitedRays: Int64;
    FTotalTime: Single; // in millisecons
    FProgress: Single;
  public
    property EmitedRays: Int64 read FEmitedRays;
    property TotalTime: Single read FTotalTime;
    property Progress: Single read FProgress;
  end;

  TRenderProgressCallback = reference to procedure(ARes: TBitmap; AStats: TRenderStatistics);
  TRenderFinishedCallback = reference to procedure(ARes: TBitmap; AStats: TRenderStatistics);

  TRenderer = class
  private type
    TRenderWork = class
    public
      Target: TAccumulationBuffer2D;
      CountBlocks: IOmniResourceCount;
      BlockX_Id, BlockY_Id: Integer;
      BlockWidth, BlockHeight: Integer;
      BlockSPP: Integer;

      constructor Create(ATarget: TAccumulationBuffer2D; ACount: IOmniResourceCount; AXId, AYId, AWidth, AHeight, ASPP: Integer);
    end;

  private
    FOptions: TRenderOptions;
    FScene: TScene;
    FCamera: TCamera;
    FEmitedRays: Int64;
    FStartTime, FEndTime: Int64;
    FIsRendering: Boolean;

    FRenderTask: IOmniTaskControl;
    FRenderWorker: IOmniBackgroundWorker;
    FCancelToken: IOmniCancellationToken;

    function GetOptions(): TRenderOptions;
    function GetEmptyColor(const ARay: TRay; ADepth: Integer): TColorVec;

    function DoRender(const ATask: IOmniTask; OnProgress: TRenderProgressCallback): TImage2D;
    procedure DoRenderBlock(ATarget: TAccumulationBuffer2D;
      BlockX, BlockY, BlockWidth, BlockHeight, BlockSPP: Integer);

    procedure ProcessRenderWork(const AWorkItem: IOmniWorkItem);

  public
    constructor Create();
    destructor Destroy; override;

    procedure SetScene(AScene: TScene);
    procedure SetCamera(ACamera: TCamera);

    function Render(AOptions: TRenderOptions = nil): TImage2D;
    function RenderAsync(AOptions: TRenderOptions;
      OnProgress: TRenderProgressCallback; OnFinished: TRenderFinishedCallback): IOmniCancellationToken;
    function IsRendering(): Boolean;
    procedure CancelRender();

    function GetStatistics(AProgress: Single = 1.0): TRenderStatistics;

    function GetColor(const ARay: TRay; ADepth: Integer): TColorVec;
    function GetNormalColor(const ARay: TRay): TColorVec;
    function GetDepthColor(const ARay: TRay; ADepth: Integer): TColorVec;
    function GetScatteredAtDepth(const ARay: TRay; ADepth, ATargetDepth: Integer): TColorVec;
    function GetColorAtDepth(const ARay: TRay; ADepth, ATargetDepth: Integer): TColorVec;

    property Options: TRenderOptions read GetOptions;
    property Scene: TScene read FScene;
    property Camera: TCamera read FCamera;
  end;

implementation

uses
  SysUtils, Math, Windows, uMathUtils, uHitable;

{ TRenderOptions }
constructor TRenderOptions.Create;
begin
  inherited Create;
  SetToDefault;
end;

function TRenderOptions.Copy(): TRenderOptions;
begin
  Result := TRenderOptions.Create;
  Result.RenderTarget := RenderTarget;
  Result.DepthLimit := DepthLimit;
  Result.TargetDepth := TargetDepth;
  Result.Gamma := Gamma;
  Result.Width := Width;
  Result.Height := Height;
  Result.SamplesPerPixel := SamplesPerPixel;
  Result.UseBlocks := UseBlocks;
  Result.BlockWidth := BlockWidth;
  Result.BlockHeight := BlockHeight;
  Result.BlockSamplesPerPixel := BlockSamplesPerPixel;
end;

procedure TRenderOptions.CopyFrom(AFrom: TRenderOptions);
begin
  if AFrom = nil then
    Exit;

  RenderTarget := AFrom.RenderTarget;
  DepthLimit := AFrom.DepthLimit;
  TargetDepth := AFrom.TargetDepth;
  Gamma := AFrom.Gamma;
  Width := AFrom.Width;
  Height := AFrom.Height;
  SamplesPerPixel := AFrom.SamplesPerPixel;
  UseBlocks := AFrom.UseBlocks;
  BlockWidth := AFrom.BlockWidth;
  BlockHeight := AFrom.BlockHeight;
  BlockSamplesPerPixel := AFrom.BlockSamplesPerPixel;
end;

procedure TRenderOptions.SetToDefault;
begin
  RenderTarget := rtColor;
  DepthLimit := 50;
  TargetDepth := 0;
  Gamma := 2.0;
  Width := 1024;
  Height := 1024;
  SamplesPerPixel := 32;
  UseBlocks := True;
  BlockWidth := 64;
  BlockHeight := 64;
  BlockSamplesPerPixel := 8;
end;

{ TRenderer.TRenderWork }
constructor TRenderer.TRenderWork.Create(ATarget: TAccumulationBuffer2D; ACount: IOmniResourceCount;
  AXId, AYId, AWidth, AHeight, ASPP: Integer);
begin
  inherited Create;
  Target := ATarget;
  CountBlocks := ACount;
  BlockX_Id := AXId;
  BlockY_Id := AYId;
  BlockWidth := AWidth;
  BlockHeight := AHeight;
  BlockSPP := ASPP;
end;

{ TRenderer }
constructor TRenderer.Create();
begin
  inherited Create;
end;

destructor TRenderer.Destroy;
begin
  FreeAndNil(FCamera);
  FreeAndNil(FScene);
  FreeAndNil(FOptions);
  inherited;
end;

function TRenderer.GetOptions(): TRenderOptions;
begin
  if FOptions = nil then
    FOptions := TRenderOptions.Create;
  Result := FOptions;
end;

function TRenderer.GetStatistics(AProgress: Single = 1.0): TRenderStatistics;
var
  Freq: Int64;
begin
  Result := TRenderStatistics.Create;
  Result.FEmitedRays := FEmitedRays;
  Result.FProgress := AProgress;
  QueryPerformanceFrequency(Freq);
  if (Freq <> 0) and (FEndTime <> 0) then
    Result.FTotalTime := 1000 * (FEndTime - FStartTime) / Freq;
end;

function TRenderer.GetEmptyColor(const ARay: TRay; ADepth: Integer): TColorVec;
begin
  Result := ColorVec(1.0, 1.0, 1.0).Lerp(ColorVec(0.5, 0.7, 1.0), 0.5 * (ARay.Direction.Y + 1));
end;

procedure TRenderer.SetScene(AScene: TScene);
begin
  if AScene = FScene then
    Exit;

  FreeAndNil(FScene);
  FScene := AScene;
end;

procedure TRenderer.SetCamera(ACamera: TCamera);
begin
  if ACamera = FCamera then
    Exit;

  FreeAndNil(FCamera);
  FCamera := ACamera;
end;

function TRenderer.IsRendering(): Boolean;
begin
  Result := FIsRendering;
end;

procedure TRenderer.CancelRender();
begin
  if Assigned(FCancelToken) then
    FCancelToken.Signal;
end;

function TRenderer.Render(AOptions: TRenderOptions): TImage2D;
begin
  if IsRendering then
    Exit(nil);
  if AOptions <> nil then
    Options.CopyFrom(AOptions);

  FIsRendering := True;
  try
    Result := DoRender(nil, nil);
  finally
    FIsRendering := False;
  end;
end;

function TRenderer.RenderAsync(AOptions: TRenderOptions;
  OnProgress: TRenderProgressCallback; OnFinished: TRenderFinishedCallback): IOmniCancellationToken;
begin
  if IsRendering then
    Exit(nil);
  if AOptions <> nil then
    Options.CopyFrom(AOptions);

  FIsRendering := True;
  FCancelToken := CreateOmniCancellationToken;
  FRenderTask := CreateTask(
    procedure(const ATask: IOmniTask)
    var
      Res: TImage2D;
      ResBitmap: Vcl.Graphics.TBitmap;
      ResStats: TRenderStatistics;
    begin
      Res := DoRender(ATask, OnProgress);
      try
        if Assigned(OnFinished) then
        begin
          ResBitmap := Res.GetAsBitmap;
          ResStats := GetStatistics;
          ATask.Invoke(
            procedure
            begin
              OnFinished(ResBitmap, ResStats);
            end);
        end;
      finally
        FreeAndNil(Res);
      end;
    end)
  .MsgWait
  .OnTerminated(
    procedure
    begin
      FRenderTask := nil;
      FCancelToken := nil;
      FIsRendering := False;
    end)
  .Run;

  Result := FCancelToken;
end;

function TRenderer.DoRender(const ATask: IOmniTask; OnProgress: TRenderProgressCallback): TImage2D;
var
  Target: TAccumulationBuffer2D;
  ProgressBitmap: Vcl.Graphics.TBitmap;
  ProgressStats: TRenderStatistics;
  XCount, YCount: Integer;
  CurWidth, CurHeight: Integer;
  CurSamples, Samples, TotalSamples: Integer;
  NumX, NumY: Integer;
  WorkItem: IOmniWorkItem;
  Wait: IOmniWaitableValue;
  CountBlocks: IOmniResourceCount;
begin
  Target := TAccumulationBuffer2D.Create(Options.Width, Options.Height);
  try
    Camera.SetupView(Options.Width, Options.Height);

    XCount := 1;
    YCount := 1;
    if Options.UseBlocks then
    begin
      XCount := Options.Width div Options.BlockWidth;
      YCount := Options.Height div Options.BlockHeight;
      if Options.Width mod Options.BlockWidth <> 0 then
        Inc(XCount);
      if Options.Height mod Options.BlockHeight <> 0 then
        Inc(YCount);
    end;

    FRenderWorker := Parallel.BackgroundWorker;
    FRenderWorker.NumTasks(System.CPUCount).{StopOn(FCancelToken).}Execute(ProcessRenderWork);

    TotalSamples := Options.SamplesPerPixel;
    Samples := TotalSamples;
    FEmitedRays := 0;
    QueryPerformanceCounter(FStartTime);
    while Samples > 0 do
    begin
      CurSamples := Samples;
      if Options.UseBlocks then
        CurSamples := Min(Samples, Options.BlockSamplesPerPixel);

      CountBlocks := CreateResourceCount(XCount * YCount);
      for NumX := 0 to XCount - 1 do
      begin
        if Assigned(FCancelToken) and FCancelToken.IsSignalled then
          Break;

        for NumY := 0 to YCount - 1 do
        begin
          if Assigned(FCancelToken) and FCancelToken.IsSignalled then
            Break;

          CurWidth := Options.Width;
          CurHeight := Options.Height;
          if Options.UseBlocks then
          begin
            if (NumX < Options.Width div Options.BlockWidth) then
              CurWidth := Options.BlockWidth
            else
              CurWidth := Min(Options.BlockWidth, Options.Width - Options.BlockWidth * (Options.Width div Options.BlockWidth));
            if (NumY < Options.Height div Options.BlockHeight) then
              CurHeight := Options.BlockHeight
            else
              CurHeight := Min(Options.BlockHeight, Options.Height - Options.BlockHeight * (Options.Height div Options.BlockHeight));
          end;

          WorkItem := FRenderWorker.CreateWorkItem(TRenderWork.Create(Target, CountBlocks, NumX, NumY, CurWidth, CurHeight, CurSamples));
          FRenderWorker.Schedule(WorkItem);
        end;
      end;
      if Assigned(FCancelToken) and FCancelToken.IsSignalled then
        Break;

      // TODO: Try to sync by locking regions in target buffer
      WaitForSingleObject(CountBlocks.Handle, INFINITE);
      Samples := Samples - CurSamples;
      if Samples = 0 then
        Break;

      QueryPerformanceCounter(FEndTime);
      if Assigned(OnProgress) then
      begin
        Wait := CreateWaitableValue;
        ProgressBitmap := Target.GetAsBitmap(Options.Gamma);
        ProgressStats := GetStatistics((TotalSamples - Samples) / IfThen(TotalSamples = 0, 1, TotalSamples));
        ATask.Invoke(
          procedure
          begin
            OnProgress(ProgressBitmap, ProgressStats);
            Wait.Signal;
          end);
        Wait.WaitFor;
      end;
    end;
    FRenderWorker.Terminate(INFINITE);
    FRenderWorker := nil;

    QueryPerformanceCounter(FEndTime);
    Result := Target.GetAsImage(Options.Gamma);
  finally
    FreeAndNil(Target);
  end;
end;

procedure TRenderer.ProcessRenderWork(const AWorkItem: IOmniWorkItem);
var
  Work: TRenderWork;
begin
  AWorkItem.Data.OwnsObject := True;
  Work := AWorkItem.Data.AsObject as TRenderWork;
  DoRenderBlock(Work.Target, Work.BlockX_Id, Work.BlockY_Id, Work.BlockWidth, Work.BlockHeight, Work.BlockSPP);
  Work.CountBlocks.Allocate;
end;

procedure TRenderer.DoRenderBlock(ATarget: TAccumulationBuffer2D;
  BlockX, BlockY, BlockWidth, BlockHeight, BlockSPP: Integer);
var
  X, Y, ShiftX, ShiftY: Integer;
  Sample: Integer;
  U, V: Single;
  Ray: TRay;
  Color: TColorVec;
begin
  ShiftX := BlockX * Options.BlockWidth;
  ShiftY := BlockY * Options.BlockHeight;
  for Y := 0 to BlockHeight - 1 do
  begin
    if Assigned(FCancelToken) and FCancelToken.IsSignalled then
      Break;

    for X := 0 to BlockWidth - 1 do
    begin
      if Assigned(FCancelToken) and FCancelToken.IsSignalled then
        Break;

      Color := ColorVec(0.0, 0.0, 0.0);
      for Sample := 1 to BlockSPP do
      begin
        U := (ShiftX + X + RandomF) / ATarget.Width;
        V := (ShiftY + Y + RandomF) / ATarget.Height;
        Ray := Camera.GetRay(U, V);
        AtomicIncrement(FEmitedRays, 1);
        case Options.RenderTarget of
          rtColor:
            Color := Color + GetColor(Ray, 0);
          rtNormalColor:
            Color := Color + GetNormalColor(Ray);
          rtDepth:
            Color := Color + GetDepthColor(Ray, 0);
          rtColorAtDepth:
            Color := Color + GetColorAtDepth(Ray, 0, Options.TargetDepth);
          rtScatteredAtDepth:
            Color := Color + GetScatteredAtDepth(Ray, 0, Options.TargetDepth);
        end;
      end;
      ATarget.AddColor(ShiftX + X, ShiftY + Y, Color, BlockSPP);
    end;
  end;
end;

function TRenderer.GetColor(const ARay: TRay; ADepth: Integer): TColorVec;
var
  Hit: TRayHit;
  Point, Normal: TVec3F;
  Scattered: TRay;
  Attenuation: TColorVec;
begin
  if ADepth >= Options.DepthLimit then
  begin
    Result :=  ColorVec(0.0, 0.0, 0.0);
    Exit;
  end;

  if Scene.Hit(ARay, 0, MaxSingle, Hit) then
  begin
    Point := ARay.At(Hit.Distance);
    Normal := Hit.Primitive.GetNormal(Point, Hit.Time);
    if Hit.Primitive.Material.Scatter(Point, ARay.Direction, Normal, Scattered, Attenuation) then
    begin
      Scattered.Time := ARay.Time;
      Result := Attenuation * GetColor(Scattered, ADepth + 1);
    end
    else
      Result :=  ColorVec(0.0, 0.0, 0.0);
  end
  else
    Result := GetEmptyColor(ARay, ADepth);
end;

function TRenderer.GetNormalColor(const ARay: TRay): TColorVec;

  function Vec2Color(const AVec: TVec3F): TColorVec;
  begin
    Result := 0.5 * ColorVec(AVec.X + 1, AVec.Y + 1, AVec.Z + 1);
  end;

var
  Hit: TRayHit;
  Point, Normal: TVec3F;
begin
  if Scene.Hit(ARay, 0, MaxSingle, Hit) then
  begin
    Point := ARay.At(Hit.Distance);
    Normal := Hit.Primitive.GetNormal(Point, Hit.Time);
    Result := Vec2Color(Normal);
  end
  else
    Result := ColorVec(0.0, 0.0, 0.0);
end;

function TRenderer.GetDepthColor(const ARay: TRay; ADepth: Integer): TColorVec;

  function Depth2Color(ADepth: Integer): TColorVec;
  var
    T: Single;
  begin
    T := Sqrt(Exp(-ADepth));
    Result := ColorVec(T, T, T);
  end;

var
  Hit: TRayHit;
  Point, Normal: TVec3F;
  Scattered: TRay;
  Attenuation: TColorVec;
begin
  if ADepth >= Options.DepthLimit then
  begin
    Result :=  Depth2Color(ADepth);
    Exit;
  end;

  if Scene.Hit(ARay, 0, MaxSingle, Hit) then
  begin
    Point := ARay.At(Hit.Distance);
    Normal := Hit.Primitive.GetNormal(Point, Hit.Time);
    if Hit.Primitive.Material.Scatter(Point, ARay.Direction, Normal, Scattered, Attenuation) then
    begin
      Scattered.Time := ARay.Time;
      Result := GetDepthColor(Scattered, ADepth + 1);
    end
    else
      Result := Depth2Color(ADepth);
  end
  else
    Result := Depth2Color(ADepth);
end;

function TRenderer.GetScatteredAtDepth(const ARay: TRay; ADepth, ATargetDepth: Integer): TColorVec;

  function Vec2Color(const AVec: TVec3F): TColorVec;
  begin
    Result := 0.5 * ColorVec(AVec.X + 1, AVec.Y + 1, AVec.Z + 1);
  end;

var
  Hit: TRayHit;
  Point, Normal: TVec3F;
  Scattered: TRay;
  Attenuation: TColorVec;
begin
  if ADepth >= Options.DepthLimit then
  begin
    Result :=  ColorVec(0.0, 0.0, 0.0);
    Exit;
  end;

  if Scene.Hit(ARay, 0, MaxSingle, Hit) then
  begin
    Point := ARay.At(Hit.Distance);
    Normal := Hit.Primitive.GetNormal(Point, Hit.Time);
    if Hit.Primitive.Material.Scatter(Point, ARay.Direction, Normal, Scattered, Attenuation) then
      if ADepth <> ATargetDepth then
      begin
        Scattered.Time := ARay.Time;
        Result := GetScatteredAtDepth(Scattered, ADepth + 1, ATargetDepth);
      end
      else
        Result := Vec2Color(Scattered.Direction)
    else
      Result := ColorVec(0.0, 0.0, 0.0);
  end
  else
    Result := ColorVec(0.0, 0.0, 0.0);
end;

function TRenderer.GetColorAtDepth(const ARay: TRay; ADepth, ATargetDepth: Integer): TColorVec;
var
  Hit: TRayHit;
  Point, Normal: TVec3F;
  Scattered: TRay;
  Attenuation: TColorVec;
begin
  if ADepth > ATargetDepth then
  begin
    Result :=  ColorVec(0.0, 0.0, 0.0);
    Exit;
  end;

  if Scene.Hit(ARay, 0, MaxSingle, Hit) then
  begin
    Point := ARay.At(Hit.Distance);
    Normal := Hit.Primitive.GetNormal(Point, Hit.Time);
    if Hit.Primitive.Material.Scatter(Point, ARay.Direction, Normal, Scattered, Attenuation) then
      if ADepth <> ATargetDepth then
      begin
        Scattered.Time := ARay.Time;
        Result := Attenuation * GetColorAtDepth(Scattered, ADepth + 1, ATargetDepth);
      end
      else
        Result := Attenuation
    else
      Result := ColorVec(0.0, 0.0, 0.0);
  end
  else
    if ADepth <> ATargetDepth then
      Result := ColorVec(0.0, 0.0, 0.0)
    else
      Result := GetEmptyColor(ARay, ADepth);
end;

end.

