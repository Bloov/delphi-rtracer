unit uMaterial;

interface

uses
  uVectors, uRay, uColor;

type
  TMaterial = class
  public
    function Scatter(const AOrigin, AIncident, ANormal: TVec3F;
      out Scattered: TRay; out Attenuation: TColorVec): Boolean; virtual; abstract;
  end;

  TLambertian = class(TMaterial)
  private
    FAlbedo: TColorVec;
  public
    constructor Create(const anAlbedo: TColorVec);

    function Scatter(const AOrigin, AIncident, ANormal: TVec3F;
      out Scattered: TRay; out Attenuation: TColorVec): Boolean; override;

    property Albedo: TColorVec read FAlbedo;
  end;

  TMetal = class(TMaterial)
  private
    FAlbedo: TColorVec;
    FRoughness: Single;
  public
    constructor Create(const anAlbedo: TColorVec; ARoughness: Single = 0.0);

    function Scatter(const AOrigin, AIncident, ANormal: TVec3F;
      out Scattered: TRay; out Attenuation: TColorVec): Boolean; override;

    property Albedo: TColorVec read FAlbedo;
    property Roughness: Single read FRoughness;
  end;

implementation

uses
  uMathUtils, uSamplingUtils;

{ TLambertian }
constructor TLambertian.Create(const anAlbedo: TColorVec);
begin
  FAlbedo := anAlbedo;
end;

function TLambertian.Scatter(const AOrigin, AIncident, ANormal: TVec3F;
  out Scattered: TRay; out Attenuation: TColorVec): Boolean;
var
  Normal: TVec3F;
begin
  {if AIncident.Dot(ANormal) > 0 then
    Normal := -ANormal
  else}
    Normal := ANormal;

  Scattered.Origin := AOrigin + Normal * 1e-5;
  Scattered.Direction := RandomOnUnitHemisphere.Rotate(Normal);
  Attenuation := Albedo;
  Result := True;
end;

{ TMetal }
constructor TMetal.Create(const anAlbedo: TColorVec; ARoughness: Single);
begin
  FAlbedo := anAlbedo;
  FRoughness := ARoughness;
end;

function TMetal.Scatter(const AOrigin, AIncident, ANormal: TVec3F;
  out Scattered: TRay; out Attenuation: TColorVec): Boolean;
var
  Normal: TVec3F;
begin
  {if AIncident.Dot(ANormal) > 0 then
    Normal := -ANormal
  else}
    Normal := ANormal;

  Scattered.Origin := AOrigin + Normal * 1e-5;
  if Roughness = 0 then
    Scattered.Direction := AIncident.Reflec(Normal)
  else
    Scattered.Direction := AIncident.Reflec(RandomMicrofacetNormal(Roughness).Rotate(Normal));
  Attenuation := Albedo;
  Result := Scattered.Direction.Dot(Normal) > 0;
end;

end.
