unit uSamplingUtils;

interface

uses
  uVectors;

function RandomInUnitSphere(): TVec3F;
function RandomInUnitDisk(): TVec2F;

function RandomOnUnitSphere(): TVec3F;
function RandomOnUnitHemisphere(): TVec3F;

// Generate a random microfacet normal based on the Beckmann distribution with the given roughness
function RandomMicrofacetNormal(Roughness: Single): TVec3F;

function ReflectByNormal(const AVec, ANormal: TVec3F): TVec3F;

implementation

uses
  Math, uMathUtils;

function RandomInUnitSphere(): TVec3F;
begin
  repeat
    Result := 2 * Vec3F(RandomF, RandomF, RandomF) - Vec3F(1, 1, 1);
  until Result.LengthSqr < 1.0;
end;

function RandomInUnitDisk(): TVec2F;
var
  Theta, U: Single;
begin
  Theta := 2 * Pi * RandomF;
  U := Sqrt(RandomF);
  Result.X := U * Cos(Theta);
  Result.Y := U * Sin(Theta);
end;

function RandomOnUnitSphere(): TVec3F;
var
  SpherePoint: TVec3F;
begin
  SpherePoint := RandomOnUnitHemisphere;
  Result := Vec3F(SpherePoint.X, SpherePoint.Y, SpherePoint.Z * Sign(0.5 - RandomF));
end;

function RandomOnUnitHemisphere(): TVec3F;
var
  x1, x2: Single;
  theta, r: Single;
begin
  x1 := RandomF;
  x2 := RandomF;
  theta := 2 * Pi * x2;
  r := Sqrt(x1);
  Result := Vec3F(r * Cos(theta), r * Sin(theta), Sqrt(1 - x1));
  {repeat
    x1 := 2.0 * RandomF - 1.0;
    x2 := 2.0 * RandomF - 1.0;
    r := x1 * x1 + x2 * x2;
  until r <= 1.0;
  Result := Vec3F(2.0 * x1 * Sqrt(1.0 - r),
                  2.0 * x2 * Sqrt(1.0 - r),
                  r);}
end;

function RandomMicrofacetNormal(Roughness: Single): TVec3F;
var
  x1, x2: Single;
  theta, phi: Single;
begin
  x1 := RandomF;
  x2 := RandomF;
  if x1 < 1 then
    theta := ArcTan(-Roughness * Roughness * Ln(1 - x1))
  else
    theta := Pi * 0.5;
  phi := 2 * Pi * x2;
  Result := TVec3F.CreateUnitSpherical(Phi, Theta);
end;

function ReflectByNormal(const AVec, ANormal: TVec3F): TVec3F;
begin
  Result := AVec - ANormal * (2 * (AVec * ANormal));
end;

end.
