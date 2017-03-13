unit uMaterial;

interface

uses
  uVectors, uRay, uColor, uTexture;

type
  TMaterial = class
  public
    function Scatter(const AOrigin, AIncident, ANormal: TVec3F;
      out Scattered: TRay; out Attenuation: TColorVec): Boolean; virtual; abstract;
  end;

  TLambertian = class(TMaterial)
  private
    FOwnTexture: Boolean;
    FAlbedo: TTexture;
  public
    constructor Create(const anAlbedo: TTexture; OwnTexture: Boolean = True);
    destructor Destroy; override;

    function Scatter(const AOrigin, AIncident, ANormal: TVec3F;
      out Scattered: TRay; out Attenuation: TColorVec): Boolean; override;

    property Albedo: TTexture read FAlbedo;
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
  SysUtils, Math, uMathUtils, uSamplingUtils;

const
  cPrecisionDelta = 1e-4;

{ TLambertian }
constructor TLambertian.Create(const anAlbedo: TTexture; OwnTexture: Boolean = True);
begin
  FAlbedo := anAlbedo;
end;

destructor TLambertian.Destroy;
begin
  if FOwnTexture then
    FreeAndNil(FAlbedo);
  inherited;
end;

function TLambertian.Scatter(const AOrigin, AIncident, ANormal: TVec3F;
  out Scattered: TRay; out Attenuation: TColorVec): Boolean;
var
  Normal: TVec3F;
  Point: TVec3F;
begin
  {if AIncident * ANormal > 0 then
    Normal := -ANormal
  else}
    Normal := ANormal;
  Point := AOrigin;

  Scattered.Origin := AOrigin + Normal * cPrecisionDelta;
  Scattered.Direction := RandomOnUnitHemisphere.Rotate(Normal);
  Attenuation := Albedo.Value(0, 0, Point);
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

  Scattered.Origin := AOrigin + Normal * cPrecisionDelta;
  if Roughness = 0 then
    Scattered.Direction := Reflect(AIncident, Normal)
  else
    Scattered.Direction := Reflect(AIncident, RandomMicrofacetNormal(Roughness).Rotate(Normal));
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
  CosIn, CosOut: Single;
  Normal: TVec3F;
  N1, N2: Single;
  R{, R0}: Single;
begin
  Attenuation := ColorVec(1.0, 1.0, 1.0);

  CosIn := AIncident * ANormal;
  if CosIn > 0 then
  begin
    // The ray is inside the material
    Normal := -ANormal;
    N1 := Refraction;
    N2 := 1;
  end
  else
  begin
    // The ray is outside the material
    Normal := ANormal;
    CosIn := -CosIn;
    N1 := 1;
    N2 := Refraction;
  end;

  CosOut := 1 - Sqr(N1 / N2) * (1 - Sqr(CosIn));
  if CosOut < 0 then
  begin
    // Total internal reflection case
    Scattered.Origin := AOrigin + Normal * cPrecisionDelta;
    Scattered.Direction := Reflect(AIncident, Normal);
    Exit(True);
  end;

  CosOut := Sqrt(CosOut);
  // Calculate the Fresnel coefficient for a randomly polarized ray
  R := 0.5 * (Sqr((N1 * cosIn - N2 * cosOut) / (N1 * cosIn + N2 * cosOut)) + Sqr((N2 * cosIn - N1 * cosOut) / (N1 * cosOut + N2 * cosIn)));
  // Calculate Schlick approximation coefficient
  {R0 := Sqr((N1 - N2) / (N1 + N2));
  R := R0 + (1 - R0) * Power(1 - uMathUtils.Min(CosIn, CosOut), 5);}
  if RandomF < R then
  begin
    Scattered.Origin := AOrigin + Normal * cPrecisionDelta;
    Scattered.Direction := Reflect(AIncident, Normal);
  end
  else
  begin
    Scattered.Origin := AOrigin - Normal * cPrecisionDelta;
    R := N1 / N2;
    Scattered.Direction := AIncident * R + Normal * (R * CosIn - CosOut);
  end;
  Result := True;
end;

end.
