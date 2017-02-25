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
  SysUtils, uMathUtils, uHitable;

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
  cSPP = 100;
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
      Result[X, Y] := Color.GetFlat;
    end;
end;

function TRenderer.GetColor(const ARay: TRay): TColorVec;
var
  T: Single;
  Hit: TRayHit;
begin
  if Scene.Hit(ARay, Hit) then
    Result := 0.5 * TColorVec.Create(Hit.Normal.X + 1, Hit.Normal.Y + 1, Hit.Normal.Z + 1)
  else
  begin
    T := 0.5 * (ARay.Direction.Y + 1);
    Result := (1 - T) * TColorVec.Create(1.0, 1.0, 1.0) + T * TColorVec.Create(0.5, 0.7, 1.0);
  end;
end;

end.
