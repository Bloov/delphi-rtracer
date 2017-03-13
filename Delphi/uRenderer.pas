unit uRenderer;

interface

uses
  uImage2D, uVectors, uRay, uColor, uScene, uCamera;

type
  TRenderer = class
  private
    FScene: TScene;
    FCamera: TCamera;
    FEmitedRays: Int64;

    function GetEmptyColor(const ARay: TRay; ADepth: Integer): TColorVec;
  public
    constructor Create(AScene: TScene);
    destructor Destroy; override;

    procedure SetCamera(ACamera: TCamera);

    function Render(AWidth, AHeight, ASamplesPerPixel: Integer): TImage2D;

    function GetColor(const ARay: TRay; ADepth: Integer): TColorVec;
    function GetNormalColor(const ARay: TRay): TColorVec;
    function GetDepthColor(const ARay: TRay; ADepth: Integer): TColorVec;
    function GetScatteredAtDepth(const ARay: TRay; ADepth, ATargetDepth: Integer): TColorVec;
    function GetColorAtDepth(const ARay: TRay; ADepth, ATargetDepth: Integer): TColorVec;

    property Scene: TScene read FScene;
    property Camera: TCamera read FCamera;
    property EmitedRays: Int64 read FEmitedRays;
  end;

implementation

uses
  SysUtils, Math, uMathUtils, uHitable;

{ TRenderer }
constructor TRenderer.Create(AScene: TScene);
begin
  FScene := AScene;
end;

destructor TRenderer.Destroy;
begin
  FreeAndNil(FCamera);
  FreeAndNil(FScene);
  inherited;
end;

function TRenderer.GetEmptyColor(const ARay: TRay; ADepth: Integer): TColorVec;
begin
  Result := ColorVec(1.0, 1.0, 1.0).Lerp(ColorVec(0.5, 0.7, 1.0), 0.5 * (ARay.Direction.Y + 1));
end;

procedure TRenderer.SetCamera(ACamera: TCamera);
begin
  if ACamera = FCamera then
    Exit;

  FreeAndNil(FCamera);
  FCamera := ACamera;
end;

function TRenderer.Render(AWidth, AHeight, ASamplesPerPixel: Integer): TImage2D;
var
  X, Y, Sample: Integer;
  U, V: Single;
  Ray: TRay;
  Color: TColorVec;
begin
  Result := TImage2D.Create(AWidth, AHeight);
  Camera.SetupView(AWidth, AHeight);

  FEmitedRays := 0;
  for Y := 0 to AHeight - 1 do
    for X := 0 to AWidth - 1 do
    begin
      Color := ColorVec(0.0, 0.0, 0.0);
      for Sample := 1 to ASamplesPerPixel do
      begin
        U := (X + RandomF) / AWidth;
        V := (Y + RandomF) / AHeight;
        Ray := Camera.GetRay(U, V);
        Color := Color + GetColor(Ray, 0);
        //Color := Color + GetNormalColor(Ray);
        //Color := Color + GetDepthColor(Ray, 0);
        //Color := Color + GetScatteredAtDepth(Ray, 0, 2);
        //Color := Color + GetColorAtDepth(Ray, 0, 10);
      end;
      Color := Color / ASamplesPerPixel;
      Result[X, Y] := GammaCorrection(Color, 2).GetFlat;
    end;
end;

function TRenderer.GetColor(const ARay: TRay; ADepth: Integer): TColorVec;
var
  Hit: TRayHit;
  Point, Normal: TVec3F;
  Scattered: TRay;
  Attenuation: TColorVec;
begin
  if ADepth >= 50 then
  begin
    Result :=  ColorVec(0.0, 0.0, 0.0);
    Exit;
  end;

  Inc(FEmitedRays);
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
  Inc(FEmitedRays);
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
  if ADepth >= 50 then
  begin
    Result :=  Depth2Color(ADepth);
    Exit;
  end;

  Inc(FEmitedRays);
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
  if ADepth >= 50 then
  begin
    Result :=  ColorVec(0.0, 0.0, 0.0);
    Exit;
  end;

  Inc(FEmitedRays);
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

  Inc(FEmitedRays);
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
