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

    function GetColor(const ARay: TRay): TColorVec;

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
  cSPP = 40;
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
        Color := Color + GetColor(Ray);
      end;
      Color := Color / cSPP;
      Result[X, Y] := GammaCorrection(Color, 2).GetFlat;
    end;
end;

function TRenderer.GetColor(const ARay: TRay): TColorVec;
var
  T: Single;
  Hit: TRayHit;
  Target: TVec3F;
begin
  if Scene.Hit(ARay, Hit) then
  begin
    Target := Hit.Point + Hit.Normal * 1e-5 + RandomOnUnitSphere.Rotate(Hit.Normal);
    //Target := Hit.Point + Hit.Normal +  RandomInUnitSphere;
    Result := 0.5 * GetColor(TRay.Create(Hit.Point, Target - Hit.Point));
    //Result := 0.5 * TColorVec.Create(Hit.Normal.X + 1, Hit.Normal.Y + 1, Hit.Normal.Z + 1);
  end
  else
  begin
    T := 0.5 * (ARay.Direction.Y + 1);
    Result := (1 - T) * TColorVec.Create(1.0, 1.0, 1.0) + T * TColorVec.Create(0.5, 0.7, 1.0);
  end;
end;

end.
