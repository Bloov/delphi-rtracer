unit uHitable;

interface

uses
  uVectors, uRay, uMaterial;

type
  TRayHit = packed record
  public
    Point: TVec3F;
    Normal: TVec3F;
    Distance: Single;
    Material: TMaterial;

    constructor Create(const APoint, ANormal: TVec3F; ADistance: Single; AMaterial: TMaterial);
  end;

  THitable = class
  private
    FMaterial: TMaterial;
  public
    constructor Create(AMaterial: TMaterial);
    destructor Destroy; override;

    function Hit(const ARay: TRay; var Hit: TRayHit): Boolean; virtual; abstract;

    property Material: TMaterial read Fmaterial;
  end;

  TSphere = class(THitable)
  private
    FCenter: TVec3F;
    FRadius: Single;
  public
    constructor Create(const ACenter: TVec3F; ARadius: Single; AMaterial: TMaterial);

    function Hit(const ARay: TRay; var Hit: TRayHit): Boolean; override;

    property Center: TVec3F read FCenter;
    property Radius: Single read FRadius;
  end;

implementation

uses
  SysUtils, uMathUtils;

{ TRayHit }
constructor TRayHit.Create(const APoint, ANormal: TVec3F; ADistance: Single; AMaterial: TMaterial);
begin
  Point := APoint;
  Normal := ANormal;
  Distance := ADistance;
  Material := AMaterial;
end;

{ THitable }
constructor THitable.Create(AMaterial: TMaterial);
begin
  FMaterial := AMaterial;
end;

destructor THitable.Destroy;
begin
  FreeAndNil(FMaterial);
  inherited;
end;

{ TSphere }
constructor TSphere.Create(const ACenter: TVec3F; ARadius: Single; AMaterial: TMaterial);
begin
  inherited Create(AMaterial);
  FCenter := ACenter;
  FRadius := ARadius;
end;

function TSphere.Hit(const ARay: TRay; var Hit: TRayHit): Boolean;
var
  ToSphere: TVec3F;
  B, C, Dist: Single;
  Disc: Single;
begin
  ToSphere := Center - ARay.Origin;
  B := ToSphere.Dot(ARay.Direction);
  C := ToSphere.LengthSqr - Radius * Radius;
  Disc := B * B - C;
  if Disc >= 0 then
  begin
    Disc := Sqrt(Disc);
    Dist := B - Disc;
    if Dist < 0 then
      Dist := B + Disc;

    if Dist > 0 then
    begin
      Result := True;
      Hit.Point := ARay.At(Dist);
      Hit.Normal := (Hit.Point - Center).Normalize;
      Hit.Distance := Dist;
      Hit.Material := Material;
    end
    else
      Result := False;
  end
  else
    Result := False;
end;

end.
