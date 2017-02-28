unit uCamera;

interface

uses
  uVectors, uRay;

type
  TCamera = class abstract
  private
    FWidth, FHeight: Integer;
    FAspectRatio: Single;
  public
    procedure SetupView(AWidth, AHeight: Integer); virtual;

    function GetRay(U, V: Single): TRay; virtual; abstract;

    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property AspectRatio: Single read FAspectRatio;
  end;

  TSimpleCamera = class(TCamera)
  private
    FOrigin: TVec3F;
    FCorner: TVec3F;
    FHorz, FVert: TVec3F;
  public
    procedure SetupView(AWidth, AHeight: Integer); override;

    function GetRay(U, V: Single): TRay; override;
  end;

  TPerspectiveCamera = class(TCamera)
  private
    FOrigin, FTarget, FUp: TVec3F;
    FFOV: Single;

    FCenter: TVec3F;
    FHorz, FVert: TVec3F;
  public
    constructor Create(const ALookFrom, ALookAt, AUp: TVec3F; FOV: Single);

    procedure SetupView(AWidth, AHeight: Integer); override;

    function GetRay(U, V: Single): TRay; override;
  end;

implementation

uses
  Math;

{ TCamera }
procedure TCamera.SetupView(AWidth, AHeight: Integer);
begin
  if (AWidth = 0) or (AHeight = 0) then
    Exit;

  FWidth := AWidth;
  FHeight := AHeight;
  FAspectRatio := FWidth / FHeight;
end;

{ TSimpleCamera }
procedure TSimpleCamera.SetupView(AWidth, AHeight: Integer);
begin
  inherited SetupView(AWidth, AHeight);
  FOrigin := Vec3F(0, 0, 0);
  FCorner := Vec3F(-AspectRatio, 1, -1);
  FHorz := AspectRatio * Vec3F(2, 0, 0);
  FVert := Vec3F(0, 2, 0);
end;

function TSimpleCamera.GetRay(U, V: Single): TRay;
begin
  Result := TRay.Create(FOrigin, FCorner + U * FHorz - V * FVert);
end;

{ TPerspectiveCamera }
constructor TPerspectiveCamera.Create(const ALookFrom, ALookAt, AUp: TVec3F; FOV: Single);
begin
  FOrigin := ALookFrom;
  FTarget := ALookAt;
  FUp := AUp;
  FFOV := FOV;
end;

procedure TPerspectiveCamera.SetupView(AWidth, AHeight: Integer);
var
  Theta: Single;
  HalfHeight, HalfWidth: Single;
  xAxis, yAxis, zAxis: TVec3F;
begin
  inherited SetupView(AWidth, AHeight);
  Theta := FFOV * Pi / 180;
  HalfWidth := Tan(Theta * 0.5);
  HalfHeight := HalfWidth / AspectRatio;

  zAxis := (FTarget - FOrigin).Normalize;
  xAxis := FUp.Cross(zAxis).Normalize;
  yAxis := zAxis.Cross(xAxis).Normalize;

  FCenter := FOrigin + zAxis;
  FHorz := 2 * HalfWidth * xAxis;
  FVert := 2 * HalfHeight * yAxis;
end;

function TPerspectiveCamera.GetRay(U, V: Single): TRay;
begin
  Result := TRay.Create(FOrigin, FCenter + (0.5 - U) * FHorz + (0.5 - V) * FVert - FOrigin);
end;

end.
