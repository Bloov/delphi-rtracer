unit uRenderer;

interface

uses
  uImage2D, uVectors, uRay, uColor, uScene, uCamera;

type
  TRenderer = class
  private
    FScene: TScene;
    FCamera: TCamera;
  public
    constructor Create(AScene: TScene);
    destructor Destroy; override;

    function Render(AWidth, AHeight: Integer): TImage2D;
    //procedure Render(ATarget: TImageAccumulator);

    function GetColor(const ARay: TRay; ADepth: Integer): TColorVec;

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
      end;
      Color := Color / cSPP;
      Result[X, Y] := GammaCorrection(Color, 2).GetFlat;
    end;
end;

function TRenderer.GetColor(const ARay: TRay; ADepth: Integer): TColorVec;
var
  T: Single;
  Hit: TRayHit;
  Target: TVec3F;
begin
  if Scene.Hit(ARay, Hit) then
  begin
    if ADepth < 50 then
    begin
      Result := 0.5 * GetColor(TRay.Create(Hit.Point + Hit.Normal * 1e-5, RandomOnUnitHemisphere.Rotate(Hit.Normal)), ADepth + 1);
      //Result := 0.5 * TColorVec.Create(Hit.Normal.X + 1, Hit.Normal.Y + 1, Hit.Normal.Z + 1);
    end
    else
      //Result := TColorVec.Create(255 - ADepth * 5, 255 - ADepth * 5, 255 - ADepth * 5);
      Result :=  TColorVec.Create(0.0, 0.0, 0.0);
  end
  else
  begin
    T := 0.5 * (ARay.Direction.Y + 1);
    Result := (1 - T) * TColorVec.Create(1.0, 1.0, 1.0) + T * TColorVec.Create(0.5, 0.7, 1.0);
    //Result := TColorVec.Create(255 - ADepth * 5, 255 - ADepth * 5, 255 - ADepth * 5);
  end;
end;

end.
