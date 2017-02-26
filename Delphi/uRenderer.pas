unit uRenderer;

interface

uses
  uImage2D, uVectors, uRay, uColor, uScene, uCamera;

type
  TRenderer = class
  private
    FScene: TScene;
    FCamera: TCamera;

    function GetEmptyColor(const ARay: TRay; ADepth: Integer): TColorVec;
  public
    constructor Create(AScene: TScene);
    destructor Destroy; override;

    function Render(AWidth, AHeight: Integer): TImage2D;
    //procedure Render(ATarget: TImageAccumulator);

    function GetColor(const ARay: TRay; ADepth: Integer): TColorVec;
    function GetDepthColor(const ARay: TRay; ADepth: Integer): TColorVec;
    function GetScatteredAtDepth(const ARay: TRay; ADepth, ATargetDepth: Integer): TColorVec;
    function GetColorAtDepth(const ARay: TRay; ADepth, ATargetDepth: Integer): TColorVec;

    property Scene: TScene read FScene;
    property Camera: TCamera read FCamera;
  end;

implementation

uses
  SysUtils, uMathUtils, uHitable, uSamplingUtils;

{ TRenderer }
constructor TRenderer.Create(AScene: TScene);
begin
  FScene := AScene;
  FCamera := TSimpleCamera.Create;
end;

destructor TRenderer.Destroy;
begin
  FreeAndNil(FCamera);
  FreeAndNil(FScene);
  inherited;
end;

function TRenderer.GetEmptyColor(const ARay: TRay; ADepth: Integer): TColorVec;
var
  T: Single;
begin
  T := 0.5 * (ARay.Direction.Y + 1);
  Result := (1 - T) * TColorVec.Create(1.0, 1.0, 1.0) + T * TColorVec.Create(0.5, 0.7, 1.0);
end;

function TRenderer.Render(AWidth, AHeight: Integer): TImage2D;
const
  cSPP = 10;
var
  X, Y, Sample: Integer;
  U, V: Single;
  Ray: TRay;
  Color: TColorVec;
begin
  Result := TImage2D.Create(AWidth, AHeight);
  Camera.SetupView(AWidth, AHeight);
  for X := 0 to AWidth - 1 do
    for Y := 0 to AHeight - 1 do
    begin
      Color := TColorVec.Create(0.0, 0.0, 0.0);
      for Sample := 1 to cSPP do
      begin
        U := (X + RandomF) / AWidth;
        V := (Y + RandomF) / AHeight;
        Ray := Camera.GetRay(U, V);
        Color := Color + GetColor(Ray, 0);
        //Color := Color + GetDepthColor(Ray, 0);
        //Color := Color + GetScatteredAtDepth(Ray, 0, 2);
        //Color := Color + GetColorAtDepth(Ray, 0, 5);
      end;
      Color := Color / cSPP;
      Result[X, Y] := GammaCorrection(Color, 2).GetFlat;
    end;
end;

function TRenderer.GetColor(const ARay: TRay; ADepth: Integer): TColorVec;
var
  T: Single;
  Hit: TRayHit;
  Scattered: TRay;
  Attenuation: TColorVec;
begin
  if Scene.Hit(ARay, Hit) then
  begin
    if (ADepth < 50)
      and Hit.Material.Scatter(Hit.Point, ARay.Direction, Hit.Normal, Scattered, Attenuation)
    then
      Result := Attenuation * GetColor(Scattered, ADepth + 1)
    else
      Result :=  TColorVec.Create(0.0, 0.0, 0.0);
  end
  else
    Result := GetEmptyColor(ARay, ADepth);
end;

function TRenderer.GetDepthColor(const ARay: TRay; ADepth: Integer): TColorVec;

  function Depth2Color(ADepth: Integer): TColorVec;
  var
    T: Single;
  begin
    T := Sqrt(Exp(-ADepth));
    Result := TColorVec.Create(T, T, T);
  end;

var
  Hit: TRayHit;
  Scattered: TRay;
  Attenuation: TColorVec;
begin
  if Scene.Hit(ARay, Hit) then
  begin
    if (ADepth < 50)
      and Hit.Material.Scatter(Hit.Point, ARay.Direction, Hit.Normal, Scattered, Attenuation)
    then
      Result := GetDepthColor(Scattered, ADepth + 1)
    else
      Result := Depth2Color(ADepth);
  end
  else
    Result := Depth2Color(ADepth);
end;

function TRenderer.GetScatteredAtDepth(const ARay: TRay; ADepth, ATargetDepth: Integer): TColorVec;

  function Vec2Color(const AVec: TVec3F): TColorVec;
  begin
    Result := 0.5 * TColorVec.Create(AVec.X + 1, AVec.Y + 1, AVec.Z + 1);
  end;

var
  Hit: TRayHit;
  Scattered: TRay;
  Attenuation: TColorVec;
begin
  if Scene.Hit(ARay, Hit) then
  begin
    if (ADepth < 50)
      and Hit.Material.Scatter(Hit.Point, ARay.Direction, Hit.Normal, Scattered, Attenuation)
    then
      if ADepth <> ATargetDepth then
        Result := GetScatteredAtDepth(Scattered, ADepth + 1, ATargetDepth)
      else
        Result := Vec2Color(Scattered.Direction)
    else
      Result := TColorVec.Create(0.0, 0.0, 0.0);
  end
  else
    Result := TColorVec.Create(0.0, 0.0, 0.0);
end;

function TRenderer.GetColorAtDepth(const ARay: TRay; ADepth, ATargetDepth: Integer): TColorVec;
var
  Hit: TRayHit;
  Scattered: TRay;
  Attenuation: TColorVec;
begin
  if Scene.Hit(ARay, Hit) then
  begin
    if (ADepth < 50)
      and Hit.Material.Scatter(Hit.Point, ARay.Direction, Hit.Normal, Scattered, Attenuation)
    then
      if ADepth <> ATargetDepth then
        Result := Attenuation * GetColorAtDepth(Scattered, ADepth + 1, ATargetDepth)
      else
        Result := Attenuation
    else
      Result := TColorVec.Create(0.0, 0.0, 0.0);
  end
  else
    if ADepth <> ATargetDepth then
      Result := TColorVec.Create(0.0, 0.0, 0.0)
    else
      Result := GetEmptyColor(ARay, ADepth);
end;

end.
