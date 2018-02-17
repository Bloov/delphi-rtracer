unit uRenderer;

interface

uses
  System.Diagnostics, Vcl.Graphics, uImage2D, uVectors, uRay, uColor, uScene, uCamera,
  OtlParallel, OtlCommon, OtlSync, OtlTask, OtlTaskControl;

type
  TRenderTarget = (rtColor, rtNormalColor, rtDepth, rtColorAtDepth, rtScatteredAtDepth);

  TRenderOptions = class
  private
    FParallelTasks: Integer;
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

    property ParallelTasks: Integer read FParallelTasks write FParallelTasks;
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
    FStopwatch: TStopwatch;
    FStartTime, FStopTime: Int64;

    FTotalTime: Single;
    FEmitedRays: Int64;
    FEmitedRaysByDepth: array of Int64;
    FProgress: Single; // how much of work is done
  public
    constructor Create(ADepthLimit: Integer);
    function GetCopy(): TRenderStatistics;

    procedure StartTime;
    procedure UpdateTime;

    procedure Merge(AStatistics: TRenderStatistics; MergeTime: Boolean = False);
    procedure RayEmmited(ADepth: Integer);

    function GetDepthLevelsCount(): Integer;
    function GetEmitedAtDepth(ADepth: Integer): Int64;
    function GetTotalTime(): Single;

    property EmitedRays: Int64 read FEmitedRays;
    property TotalTime: Single read GetTotalTime;
    property Progress: Single read FProgress;
  end;

  TRenderProgressCallback = reference to procedure(ARes: TBitmap; AStats: TRenderStatistics);
  TRenderFinishedCallback = reference to procedure(ARes: TBitmap; AStats: TRenderStatistics);

  TRenderer = class
  private type
    TRenderWork = class
    public
      Statistics: TRenderStatistics;
      Target: TImageBuffer2D;
      Counter: IOmniResourceCount;
      XId, YId: Integer;
      Width, Height: Integer;
      SPP: Integer;

      constructor Create(ATarget: TImageBuffer2D; ACounter: IOmniResourceCount; AXId, AYId, AWidth, AHeight, ASPP: Integer);
    end;

  private
    FOptions: TRenderOptions;
    FScene: TScene;
    FCamera: TCamera;
    FIsRendering: Boolean;
    FStatistics: TRenderStatistics;
    FStatisticsLock: IOmniCriticalSection;

    FRenderTask: IOmniTaskControl;
    FRenderWorker: IOmniBackgroundWorker;
    FCancelToken: IOmniCancellationToken;

    function GetOptions(): TRenderOptions;
    function BeginCollectStatistics(): TRenderStatistics;

    procedure GetBlocksCount(out XCount, YCount: Integer);
    procedure GetBlockSize(XIdx, YIdx: Integer; out Width, Height: Integer);

    function DoRender(const ATask: IOmniTask; OnProgress: TRenderProgressCallback): TImage2D;
    procedure DoRenderBlock(ATarget: TImageBuffer2D; AStatistics: TRenderStatistics;
      BlockX, BlockY, BlockWidth, BlockHeight, BlockSPP: Integer);

    procedure ProcessRenderWork(const AWorkItem: IOmniWorkItem);
    procedure ProcessWorkDone(const ASender: IOmniBackgroundWorker; const AWorkItem: IOmniWorkItem);

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

    function GetStatistics(): TRenderStatistics;

    function GetColor(const ARay: TRay; AStats: TRenderStatistics): TColorVec;
    function GetNormalColor(const ARay: TRay; AStats: TRenderStatistics): TColorVec;
    function GetDepthColor(const ARay: TRay; AStats: TRenderStatistics): TColorVec;
    function GetScatteredAtDepth(const ARay: TRay; AStats: TRenderStatistics; ATargetDepth: Integer): TColorVec;
    function GetColorAtDepth(const ARay: TRay; AStats: TRenderStatistics; ATargetDepth: Integer): TColorVec;

    property Options: TRenderOptions read GetOptions;
    property Scene: TScene read FScene;
    property Camera: TCamera read FCamera;
  end;

implementation

uses
  SysUtils, Math, Windows, uMathUtils, uHitable;

{ TRenderOptions }
{$REGION ' TRenderOptions '}
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
  ParallelTasks := System.CPUCount;
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
{$ENDREGION}

{ TRenderStatistics }
{$REGION ' TRenderStatistics '}
constructor TRenderStatistics.Create(ADepthLimit: Integer);
begin
  inherited Create;
  FStopwatch := TStopwatch.Create;
  SetLength(FEmitedRaysByDepth, ADepthLimit);
end;

function TRenderStatistics.GetCopy(): TRenderStatistics;
var
  I: Integer;
begin
  Result := TRenderStatistics.Create(GetDepthLevelsCount);
  Result.FProgress := FProgress;
  Result.FTotalTime := FTotalTime;
  Result.FEmitedRays := FEmitedRays;
  for I := 0 to GetDepthLevelsCount - 1 do
    Result.FEmitedRaysByDepth[I] := FEmitedRaysByDepth[I];
end;

procedure TRenderStatistics.StartTime;
begin
  FTotalTime := 0;
  FStartTime := FStopwatch.GetTimeStamp;
end;

procedure TRenderStatistics.UpdateTime;
begin
  FStopTime := FStopwatch.GetTimeStamp;
  FTotalTime := 1e3 * ((FStopTime - FStartTime) / FStopwatch.Frequency);
end;

procedure TRenderStatistics.Merge(AStatistics: TRenderStatistics; MergeTime: Boolean = False);
var
  I, Count: Integer;
begin
  FEmitedRays := FEmitedRays + AStatistics.EmitedRays;
  Count := Max(GetDepthLevelsCount, AStatistics.GetDepthLevelsCount);
  SetLength(FEmitedRaysByDepth, Count);
  for I := 0 to Count - 1 do
    FEmitedRaysByDepth[I] := FEmitedRaysByDepth[I] + AStatistics.GetEmitedAtDepth(I);

  if MergeTime then
    FTotalTime := FTotalTime + AStatistics.TotalTime;
end;

procedure TRenderStatistics.RayEmmited(ADepth: Integer);
begin
  if ADepth + 1 > Length(FEmitedRaysByDepth) then
    SetLength(FEmitedRaysByDepth, ADepth + 1);
  Inc(FEmitedRays);
  Inc(FEmitedRaysByDepth[ADepth]);
end;

function TRenderStatistics.GetDepthLevelsCount(): Integer;
begin
  Result := Length(FEmitedRaysByDepth);
end;

function TRenderStatistics.GetEmitedAtDepth(ADepth: Integer): Int64;
begin
  if ADepth < GetDepthLevelsCount then
    Result := FEmitedRaysByDepth[ADepth]
  else
    Result := 0;
end;

function TRenderStatistics.GetTotalTime(): Single;
begin
  Result := FTotalTime;
end;
{$ENDREGION}

{ TRenderer.TRenderWork }
constructor TRenderer.TRenderWork.Create(ATarget: TImageBuffer2D; ACounter: IOmniResourceCount;
  AXId, AYId, AWidth, AHeight, ASPP: Integer);
begin
  inherited Create;
  Target := ATarget;
  Counter := ACounter;
  XId := AXId;
  YId := AYId;
  Width := AWidth;
  Height := AHeight;
  SPP := ASPP;
end;

{ TRenderer }
{$REGION ' TRenderer '}
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

function TRenderer.BeginCollectStatistics(): TRenderStatistics;
begin
  FreeAndNil(FStatistics);
  FStatistics := TRenderStatistics.Create(Options.DepthLimit);
  FStatisticsLock := CreateOmniCriticalSection;
  Result := FStatistics;
end;

function TRenderer.GetStatistics(): TRenderStatistics;
begin
  if Assigned(FStatistics) then
    Result := FStatistics.GetCopy
  else
    Result := nil;
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
    FStatistics := BeginCollectStatistics;
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
  FStatistics := BeginCollectStatistics;
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

procedure TRenderer.GetBlocksCount(out XCount, YCount: Integer);
begin
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
end;

procedure TRenderer.GetBlockSize(XIdx, YIdx: Integer; out Width, Height: Integer);
begin
  Width := Options.Width;
  Height := Options.Height;
  if Options.UseBlocks then
  begin
    if (XIdx < Options.Width div Options.BlockWidth) then
      Width := Options.BlockWidth
    else
      Width := Min(Options.BlockWidth, Options.Width - Options.BlockWidth * (Options.Width div Options.BlockWidth));
    if (YIdx < Options.Height div Options.BlockHeight) then
      Height := Options.BlockHeight
    else
      Height := Min(Options.BlockHeight, Options.Height - Options.BlockHeight * (Options.Height div Options.BlockHeight));
  end;
end;

function TRenderer.DoRender(const ATask: IOmniTask; OnProgress: TRenderProgressCallback): TImage2D;
var
  Target: TImageBuffer2D;
  ProgressBitmap: Vcl.Graphics.TBitmap;
  ProgressStats: TRenderStatistics;
  XCount, YCount: Integer;
  XIdx, YIdx: Integer;
  CurWidth, CurHeight: Integer;
  CurSamples, Samples, TotalSamples: Integer;
  BlocksCounter: IOmniResourceCount;
  Wait: IOmniWaitableValue;
begin
  Camera.SetupView(Options.Width, Options.Height);
  Target := TImageBuffer2D.Create(Options.Width, Options.Height);
  try
    FRenderWorker := Parallel.BackgroundWorker;
    FRenderWorker.
      NumTasks(System.CPUCount).
      {StopOn(FCancelToken).}
      OnRequestDone_Asy(ProcessWorkDone).
      Execute(ProcessRenderWork);

    FStatistics.StartTime;
    GetBlocksCount(XCount, YCount);
    TotalSamples := Options.SamplesPerPixel;
    Samples := TotalSamples;
    while Samples > 0 do
    begin
      BlocksCounter := CreateResourceCount(XCount * YCount);
      CurSamples := Min(Samples, IfThen(Options.UseBlocks, Options.BlockSamplesPerPixel, Samples));
      for XIdx := 0 to XCount - 1 do
      begin
        if Assigned(FCancelToken) and FCancelToken.IsSignalled then
          Break;

        for YIdx := 0 to YCount - 1 do
        begin
          if Assigned(FCancelToken) and FCancelToken.IsSignalled then
            Break;

          GetBlockSize(XIdx, YIdx, CurWidth, CurHeight);
          FRenderWorker.Schedule(FRenderWorker.CreateWorkItem(
            TRenderWork.Create(Target, BlocksCounter, XIdx, YIdx, CurWidth, CurHeight, CurSamples)));
        end;
      end;
      if Assigned(FCancelToken) and FCancelToken.IsSignalled then
        Break;

      // TODO: Try to sync by locking regions in target buffer
      WaitForSingleObject(BlocksCounter.Handle, INFINITE);

      Dec(Samples, CurSamples);
      FStatistics.UpdateTime;
      FStatistics.FProgress := ((TotalSamples - Samples) / IfThen(TotalSamples = 0, 1, TotalSamples));
      if Samples = 0 then
        Break;

      if Assigned(OnProgress) then
      begin
        Wait := CreateWaitableValue;
        ProgressBitmap := Target.GetAsBitmap(Options.Gamma);
        ProgressStats := GetStatistics;
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
    FStatistics.UpdateTime;

    Result := Target.GetAsImage(Options.Gamma);
  finally
    FreeAndNil(Target);
  end;
end;

procedure TRenderer.ProcessRenderWork(const AWorkItem: IOmniWorkItem);
var
  Work: TRenderWork;
begin
  AWorkItem.SkipCompletionHandler := False;
  AWorkItem.Result := TRenderStatistics.Create(Options.DepthLimit);
  AWorkItem.Result.OwnsObject := True;
  AWorkItem.Data.OwnsObject := True;

  Work := AWorkItem.Data.AsObject as TRenderWork;
  DoRenderBlock(Work.Target, TRenderStatistics(AWorkItem.Result.AsObject), Work.XId, Work.YId, Work.Width, Work.Height, Work.SPP);
  Work.Counter.Allocate;
end;

procedure TRenderer.ProcessWorkDone(const ASender: IOmniBackgroundWorker; const AWorkItem: IOmniWorkItem);
begin
  FStatisticsLock.Acquire;
  try
    FStatistics.Merge(AWorkItem.Result.AsObject as TRenderStatistics);
  finally
    FStatisticsLock.Release;
  end;
end;

procedure TRenderer.DoRenderBlock(ATarget: TImageBuffer2D; AStatistics: TRenderStatistics;
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
        case Options.RenderTarget of
          rtColor:
            Color := Color + GetColor(Ray, AStatistics);
          rtNormalColor:
            Color := Color + GetNormalColor(Ray, AStatistics);
          rtDepth:
            Color := Color + GetDepthColor(Ray, AStatistics);
          rtColorAtDepth:
            Color := Color + GetColorAtDepth(Ray, AStatistics, Options.TargetDepth);
          rtScatteredAtDepth:
            Color := Color + GetScatteredAtDepth(Ray, AStatistics, Options.TargetDepth);
        end;
      end;
      ATarget.AddColor(ShiftX + X, ShiftY + Y, Color, BlockSPP);
    end;
  end;
end;

function TRenderer.GetColor(const ARay: TRay; AStats: TRenderStatistics): TColorVec;
var
  Depth: Integer;
  Ray, Scattered: TRay;
  Hit: TRayHit;
  Point, Normal: TVec3F;
  Attenuation: TColorVec;
begin
  Ray := ARay;
  Depth := 0;
  AStats.RayEmmited(Depth);
  Result := ColorVec(1.0, 1.0, 1.0);
  while True do
  begin
    if Depth > Options.DepthLimit then
      Exit(Result * ColorVec(0.0, 0.0, 0.0));

    if Scene.Hit(Ray, 0, MaxSingle, Hit) then
    begin
      Point := Ray.At(Hit.Distance);
      Normal := Hit.Primitive.GetNormal(Point, Hit.Time);
      if Hit.Primitive.Material.Scatter(Point, Ray.Direction, Normal, Scattered, Attenuation) then
      begin
        AStats.RayEmmited(Depth + 1);
        Ray.Assign{WithoutTime}(Scattered);
        Result := Result * Attenuation;
      end
      else
        Exit(Result * ColorVec(0.0, 0.0, 0.0));
    end
    else
      Exit(Result * Scene.GetEmptyColor(ARay));

    Inc(Depth);
  end;
end;

function TRenderer.GetNormalColor(const ARay: TRay; AStats: TRenderStatistics): TColorVec;

  function Vec2Color(const AVec: TVec3F): TColorVec;
  begin
    Result := 0.5 * ColorVec(AVec.X + 1, AVec.Y + 1, AVec.Z + 1);
  end;

var
  Hit: TRayHit;
  Point, Normal: TVec3F;
begin
  AStats.RayEmmited(0);
  if Scene.Hit(ARay, 0, MaxSingle, Hit) then
  begin
    Point := ARay.At(Hit.Distance);
    Normal := Hit.Primitive.GetNormal(Point, Hit.Time);
    Result := Vec2Color(Normal);
  end
  else
    Result := ColorVec(0.0, 0.0, 0.0);
end;

function TRenderer.GetDepthColor(const ARay: TRay; AStats: TRenderStatistics): TColorVec;

  function Depth2Color(ADepth: Integer): TColorVec;
  var
    T: Single;
  begin
    T := Sqrt(Exp(-ADepth));
    Result := ColorVec(T, T, T);
  end;

var
  Depth: Integer;
  Ray, Scattered: TRay;
  Hit: TRayHit;
  Point, Normal: TVec3F;
  Attenuation: TColorVec;
begin
  Ray := ARay;
  Depth := 0;
  AStats.RayEmmited(Depth);
  while True do
  begin
    if Depth > Options.DepthLimit then
      Exit(Depth2Color(Depth));

    if Scene.Hit(Ray, 0, MaxSingle, Hit) then
    begin
      Point := Ray.At(Hit.Distance);
      Normal := Hit.Primitive.GetNormal(Point, Hit.Time);
      if Hit.Primitive.Material.Scatter(Point, Ray.Direction, Normal, Scattered, Attenuation) then
      begin
        AStats.RayEmmited(Depth + 1);
        Ray.Assign{WithoutTime}(Scattered);
      end
      else
        Exit(Depth2Color(Depth));
    end
    else
      Exit(Depth2Color(Depth));

    Inc(Depth);
  end;
end;

function TRenderer.GetScatteredAtDepth(const ARay: TRay; AStats: TRenderStatistics; ATargetDepth: Integer): TColorVec;

  function Vec2Color(const AVec: TVec3F): TColorVec;
  begin
    Result := 0.5 * ColorVec(AVec.X + 1, AVec.Y + 1, AVec.Z + 1);
  end;

var
  Depth: Integer;
  Ray, Scattered: TRay;
  Hit: TRayHit;
  Point, Normal: TVec3F;
  Attenuation: TColorVec;
begin
  Ray := ARay;
  Depth := 0;
  AStats.RayEmmited(Depth);
  while True do
  begin
    if Depth > Options.DepthLimit then
      Exit(ColorVec(0.0, 0.0, 0.0));

    if Scene.Hit(Ray, 0, MaxSingle, Hit) then
    begin
      Point := Ray.At(Hit.Distance);
      Normal := Hit.Primitive.GetNormal(Point, Hit.Time);
      if Hit.Primitive.Material.Scatter(Point, Ray.Direction, Normal, Scattered, Attenuation) then
        if Depth <> ATargetDepth then
        begin
          AStats.RayEmmited(Depth + 1);
          Ray.Assign{WithoutTime}(Scattered);
        end
        else
          Exit(Vec2Color(Scattered.Direction))
      else
        Exit(ColorVec(0.0, 0.0, 0.0));
    end
    else
      Exit(ColorVec(0.0, 0.0, 0.0));

    Inc(Depth);
  end;
end;

function TRenderer.GetColorAtDepth(const ARay: TRay; AStats: TRenderStatistics; ATargetDepth: Integer): TColorVec;
var
  Depth: Integer;
  Ray, Scattered: TRay;
  Hit: TRayHit;
  Point, Normal: TVec3F;
  Attenuation: TColorVec;
begin
  Ray := ARay;
  Depth := 0;
  AStats.RayEmmited(Depth);
  Result := ColorVec(1.0, 1.0, 1.0);
  while True do
  begin
    if Depth > Options.DepthLimit then
      Exit(ColorVec(0.0, 0.0, 0.0));

    if Scene.Hit(Ray, 0, MaxSingle, Hit) then
    begin
      Point := Ray.At(Hit.Distance);
      Normal := Hit.Primitive.GetNormal(Point, Hit.Time);
      if Hit.Primitive.Material.Scatter(Point, Ray.Direction, Normal, Scattered, Attenuation) then
        if Depth <> ATargetDepth then
        begin
          AStats.RayEmmited(Depth + 1);
          Ray.Assign{WithoutTime}(Scattered);
          Result := Result * Attenuation;
        end
        else
          Exit(Result * Attenuation)
      else
        Exit(ColorVec(0.0, 0.0, 0.0));
    end
    else
      if Depth <> ATargetDepth then
        Exit(ColorVec(0.0, 0.0, 0.0))
      else
        Exit(Result * Scene.GetEmptyColor(ARay));

    Inc(Depth);
  end;
end;
{$ENDREGION}

end.

