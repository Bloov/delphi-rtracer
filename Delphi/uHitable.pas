unit uHitable;

interface

uses
  uVectors, uRay;

type
  THitable = class
  public
    function Hit(const ARay: TRay; var Hit: TRayHit): Boolean; virtual; abstract;
  end;

  TSphere = class(THitable)
  private
    FCenter: TVec3F;
    FRadius: Single;
  public
    constructor Create(const ACenter: TVec3F; ARadius: Single);

    function Hit(const ARay: TRay; var Hit: TRayHit): Boolean; override;

    property Center: TVec3F read FCenter;
    property Radius: Single read FRadius;
  end;

implementation

uses
  uMathUtils;

{ TSphere }
constructor TSphere.Create(const ACenter: TVec3F; ARadius: Single);
begin
  FCenter := ACenter;
  FRadius := ARadius;
end;

function TSphere.Hit(const ARay: TRay; var Hit: TRayHit): Boolean;
var
  ToSphere: TVec3F;
  B, C, T: Single;
  Disc: Single;
begin
  ToSphere := Center - ARay.Origin;
  B := ToSphere.Dot(ARay.Direction);
  C := ToSphere.LengthSqr - Radius * Radius;
  Disc := B * B - C;
  if Disc >= 0 then
  begin
    Disc := Sqrt(Disc);
    T := B - Disc;
    if T < 0 then
      T := B + Disc;

    if T > 0 then
    begin
      Result := True;
      Hit.Point := ARay.At(T);
      Hit.Normal := (Hit.Point - Center).Normalize;
      Hit.T := T;
    end
    else
      Result := False;
  end
  else
    Result := False;
end;

end.
