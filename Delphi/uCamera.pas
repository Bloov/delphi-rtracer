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

  TPerspectiveCamera = class(TCamera)
  private
    FCameraUp: TVec3F;
    FFOV: Single;
    FAperture: Single;
    FFocusDistance: Single;

    FCenter: TVec3F;
    FForward, FHorz, FVert: TVec3F;
  public
    constructor Create(const ALookFrom, ALookAt, AUp: TVec3F; FOV, Aperture, FocusDistance: Single); overload;
    constructor Create(const ALookFrom, ALookAt, AUp: TVec3F; FOV, Aperture: Single); overload;

    procedure SetupView(AWidth, AHeight: Integer); override;

    function GetRay(U, V: Single): TRay; override;

    property Position: TVec3F read FCenter;
    property Direction: TVec3F read FForward;
    property CameraUp: TVec3F read FCameraUp;
    property Aperture: Single read FAperture;
    property FieldOfView: Single read FFOV;
    property FocusDistance: Single read FFocusDistance;
  end;

implementation

uses
  Math, uSamplingUtils;

{ TCamera }
procedure TCamera.SetupView(AWidth, AHeight: Integer);
begin
  if (AWidth = 0) or (AHeight = 0) then
    Exit;

  FWidth := AWidth;
  FHeight := AHeight;
  FAspectRatio := FWidth / FHeight;
end;

{ TPerspectiveCamera }
constructor TPerspectiveCamera.Create(const ALookFrom, ALookAt, AUp: TVec3F; FOV, Aperture, FocusDistance: Single);
begin
  FCenter := ALookFrom;
  FForward := (ALookAt - ALookFrom).Normalize;
  FCameraUp := AUp;
  FFOV := FOV;
  FAperture := Aperture;
  FFocusDistance := FocusDistance;
end;

constructor TPerspectiveCamera.Create(const ALookFrom, ALookAt, AUp: TVec3F; FOV, Aperture: Single);
begin
  FCenter := ALookFrom;
  FForward := (ALookAt - ALookFrom).Normalize;
  FCameraUp := AUp;
  FFOV := FOV;
  FAperture := Aperture;
  FFocusDistance := (ALookAt - ALookFrom).Length;
end;

procedure TPerspectiveCamera.SetupView(AWidth, AHeight: Integer);
var
  Theta: Single;
  HalfHeight, HalfWidth: Single;
  xAxis, yAxis: TVec3F;
begin
  inherited SetupView(AWidth, AHeight);
  Theta := FFOV * Pi / 180;
  HalfWidth := Tan(Theta * 0.5);
  HalfHeight := HalfWidth / AspectRatio;

  xAxis := CameraUp.Cross(Direction).Normalize;
  yAxis := Direction.Cross(xAxis).Normalize;

  FHorz := 2 * HalfWidth * xAxis;
  FVert := 2 * HalfHeight * yAxis;
end;

function TPerspectiveCamera.GetRay(U, V: Single): TRay;
var
  RayOrigin: TVec3F;
  RayDirection: TVec3F;
  ScreenPoint: TVec3F;
  FocusPoint: TVec3F;
  PointOnAperture: TVec2F;
begin
  RayOrigin := FCenter;
  // In screen plane image is inverted
  ScreenPoint := RayOrigin - Direction - (0.5 - U) * FHorz - (0.5 - V) * FVert;
  RayDirection := (RayOrigin - ScreenPoint).Normalize;
  if Aperture > 0 then
  begin
    FocusPoint := RayOrigin + RayDirection * FocusDistance / RayDirection.Dot(Direction);
    PointOnAperture := FAperture * RandomInUnitDisk;
    RayOrigin := RayOrigin + PointOnAperture.X * FHorz + PointOnAperture.Y * FVert;
    RayDirection := FocusPoint - RayOrigin;
  end;
  Result := TRay.Create(RayOrigin, RayDirection);
end;

end.
