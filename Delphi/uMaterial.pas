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

  TDielectric = class(TMaterial)
  private
    FRefraction: Single;
  public
    constructor Create(ARefraction: Single);

    function Scatter(const AOrigin, AIncident, ANormal: TVec3F;
      out Scattered: TRay; out Attenuation: TColorVec): Boolean; override;

    property Refraction: Single read FRefraction;
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
  {if AIncident * ANormal > 0 then
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
  {if AIncident * ANormal) > 0 then
    Normal := -ANormal
  else}
    Normal := ANormal;

  Scattered.Origin := AOrigin + Normal * 1e-5;
  if Roughness = 0 then
    Scattered.Direction := Reflect(AIncident, Normal).Normalize
  else
    Scattered.Direction := Reflect(AIncident, RandomMicrofacetNormal(Roughness).Rotate(Normal)).Normalize;
  Attenuation := Albedo;
  Result := (Scattered.Direction * Normal > 0);
end;

{ TDielectric }
constructor TDielectric.Create(ARefraction: Single);
begin
  FRefraction := ARefraction;
end;

function TDielectric.Scatter(const AOrigin, AIncident, ANormal: TVec3F;
  out Scattered: TRay; out Attenuation: TColorVec): Boolean;
var
  OutwardN: TVec3F;
  Cosine, RefractionIndex: Single;
  Reflected, Refracted: TVec3F;
  ReflectProb: Single;
begin
  if AIncident * ANormal > 0 then
  begin
    OutwardN := -ANormal;
    RefractionIndex := Refraction;
    Cosine := Refraction * AIncident * ANormal;
    {Cosine := AIncident * ANormal;
    Cosine := Sqrt(1 - Sqr(Refraction) * (1 - Sqr(Cosine)));}
  end
  else
  begin
    OutwardN := ANormal;
    RefractionIndex := 1 / Refraction;
    Cosine := -AIncident * ANormal;
  end;

  if Refract(AIncident, OutwardN, RefractionIndex, Refracted) then
    ReflectProb := Schlick(Cosine, Refraction)
  else
    ReflectProb := 1;

  Attenuation := ColorVec(1.0, 1.0, 1.0);
  Scattered.Origin := AOrigin - OutwardN * 1e-5;
  if RandomF < ReflectProb then
    Scattered.Direction := Reflect(AIncident, ANormal).Normalize
  else
    Scattered.Direction := Refracted.Normalize;

  Result := True;
end;

end.
