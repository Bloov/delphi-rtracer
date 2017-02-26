unit uSamplingUtils;

interface

uses
  uVectors;

function RandomInUnitSphere(): TVec3F;

function RandomOnUnitSphere(): TVec3F;
function RandomOnUnitHemisphere(): TVec3F;

implementation

uses
  Math, uMathUtils;

function RandomInUnitSphere(): TVec3F;
begin
  repeat
    Result := 2 * TVec3F.Create(RandomF, RandomF, RandomF) - TVec3F.Create(1, 1, 1);
  until Result.LengthSqr < 1.0;
end;

function RandomOnUnitSphere(): TVec3F;
var
  SpherePoint: TVec3F;
begin
  SpherePoint := RandomOnUnitHemisphere;
  Result := TVec3F.Create(SpherePoint.X, SpherePoint.Y, SpherePoint.Z * Sign(0.5 - RandomF));
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
  Result := TVec3F.Create(r * Cos(theta), r * Sin(theta), Sqrt(1 - x1));
  {repeat
    x1 := 2.0 * RandomF - 1.0;
    x2 := 2.0 * RandomF - 1.0;
    r := x1 * x1 + x2 * x2;
  until r <= 1.0;
  Result := TVec3F.Create(2.0 * x1 * Sqrt(1.0 - r),
                          2.0 * x2 * Sqrt(1.0 - r),
                          r);}
end;

end.
