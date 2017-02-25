unit uVectors;

interface

uses
  Math;

type
  TVec2F = packed record
  public
    constructor Create(aX, aY: Single);

    class operator Negative(const Vec: TVec2F): TVec2F; inline;
    class operator Positive(const Vec: TVec2F): TVec2F; inline;
    class operator Equal(const A, B: TVec2F): Boolean; inline;
    class operator NotEqual(const A, B: TVec2F): Boolean; inline;
    class operator Add(const A, B: TVec2F): TVec2F; inline;
    class operator Subtract(const A, B: TVec2F): TVec2F; inline;
    class operator Multiply(const A: TVec2F; B: Single): TVec2F; overload; inline;
    class operator Multiply(A: Single; const B: TVec2F): TVec2F; overload; inline;
    class operator Multiply(const A, B: TVec2F): TVec2F; overload; inline;
    class operator Divide(const A: TVec2F; B: Single): TVec2F; overload; inline;
    class operator Divide(A: Single; const B: TVec2F): TVec2F; overload; inline;
    class operator Divide(const A, B: TVec2F): TVec2F; overload; inline;

    function Dot(const Vec: TVec2F): Single; inline;
    function Projection(const Vec: TVec2F): TVec2F; inline;
    function Normalize(): TVec2F; inline;
    function Distance(const Vec: TVec2F): Single; inline;
    function Clip(ALength: Single): TVec2F;
    function Stretch(ALength: Single): TVec2F;

    function Length(): Single; inline;
    function LengthSqr(): Single; inline;

    function IsZero(): Boolean;
    function IsAnyZero(): Boolean;
    function IsValid(): Boolean;
    function IsInf(): Boolean;

    case Boolean of
      True: (Arr: array [0..1] of Single);
      False: (X, Y: Single);
  end;

  TVec3F = packed record
  public
    constructor Create(aX, aY, aZ: Single);

    class operator Negative(const Vec: TVec3F): TVec3F; inline;
    class operator Positive(const Vec: TVec3F): TVec3F; inline;
    class operator Equal(const A, B: TVec3F): Boolean; inline;
    class operator NotEqual(const A, B: TVec3F): Boolean; inline;
    class operator Add(const A, B: TVec3F): TVec3F; inline;
    class operator Subtract(const A, B: TVec3F): TVec3F; inline;
    class operator Multiply(const A: TVec3F; B: Single): TVec3F; overload; inline;
    class operator Multiply(A: Single; const B: TVec3F): TVec3F; overload; inline;
    class operator Multiply(const A, B: TVec3F): TVec3F; overload; inline;
    class operator Divide(const A: TVec3F; B: Single): TVec3F; overload; inline;
    class operator Divide(A: Single; const B: TVec3F): TVec3F; overload; inline;
    class operator Divide(const A, B: TVec3F): TVec3F; overload; inline;

    function Dot(const Vec: TVec3F): Single; inline;
    function Cross(const Vec: TVec3F): TVec3F; inline;
    function Projection(const Vec: TVec3F): TVec3F; inline;
    function Normalize(): TVec3F; inline; inline;
    function Distance(const Vec: TVec3F): Single; inline;
    function Clip(ALength: Single): TVec3F;
    function Stretch(ALength: Single): TVec3F;

    function Rotate(const ANormal: TVec3F): TVec3F;

    function Length(): Single; inline;
    function LengthSqr(): Single; inline;

    function IsZero(): Boolean;
    function IsAnyZero(): Boolean;
    function IsValid(): Boolean;
    function IsInf(): Boolean;

    case Boolean of
      True: (Arr: array [0..2] of Single);
      False: (X, Y, Z: Single);
  end;

implementation

uses
  uMathUtils;

{ TVec2F }
constructor TVec2F.Create(aX, aY: Single);
begin
  X := aX;
  Y := aY;
end;

class operator TVec2F.Negative(const Vec: TVec2F): TVec2F;
begin
  Result.X := -Vec.X;
  Result.Y := -Vec.Y;
end;

class operator TVec2F.Positive(const Vec: TVec2F): TVec2F;
begin
  Result := Vec;
end;

class operator TVec2F.Equal(const A, B: TVec2F): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y);
end;

class operator TVec2F.NotEqual(const A, B: TVec2F): Boolean;
begin
  Result := (A.X <> B.X) or (A.Y <> B.Y);
end;

class operator TVec2F.Add(const A, B: TVec2F): TVec2F;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
end;

class operator TVec2F.Subtract(const A, B: TVec2F): TVec2F;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
end;

class operator TVec2F.Multiply(const A: TVec2F; B: Single): TVec2F;
begin
  Result.X := A.X * B;
  Result.Y := A.Y * B;
end;

class operator TVec2F.Multiply(A: Single; const B: TVec2F): TVec2F;
begin
  Result.X := A * B.X;
  Result.Y := A * B.Y;
end;

class operator TVec2F.Multiply(const A, B: TVec2F): TVec2F;
begin
  Result.X := A.X * B.X;
  Result.Y := A.Y * B.Y;
end;

class operator TVec2F.Divide(const A: TVec2F; B: Single): TVec2F;
var
  Norm: Single;
begin
  Norm := 1 / B;
  Result.X := A.X * Norm;
  Result.Y := A.Y * Norm;
end;

class operator TVec2F.Divide(A: Single; const B: TVec2F): TVec2F;
begin
  Result.X := A / B.X;
  Result.Y := A / B.Y;
end;

class operator TVec2F.Divide(const A, B: TVec2F): TVec2F;
begin
  Result.X := A.X / B.X;
  Result.Y := A.Y / B.Y;
end;

function TVec2F.Dot(const Vec: TVec2F): Single;
begin
  Result := X * Vec.X + Y * Vec.Y;
end;

function TVec2F.Projection(const Vec: TVec2F): TVec2F;
var
  Norm: Single;
begin
  Norm := (X * Vec.X + Y * Vec.Y) / (X * X + Y * Y);
  Result.X := X * Norm;
  Result.Y := Y * Norm;
end;

function TVec2F.Normalize(): TVec2F;
var
  Norm: Single;
begin
  Norm := 1 / Sqrt(X * X + Y * Y);
  Result.X := X * Norm;
  Result.Y := Y * Norm;
end;

function TVec2F.Distance(const Vec: TVec2F): Single;
begin
  Result := Sqrt(Sqr(X - Vec.X) + Sqr(Y - Vec.Y));
end;

function TVec2F.Clip(ALength: Single): TVec2F;
var
  Len, Clip: Single;
begin
  Clip := Abs(ALength);
  Len := Sqrt(X * X + Y * Y);
  if (Clip < Len) then
  begin
    Result.X := Result.X * Clip / Len;
    Result.Y := Result.Y * Clip / Len;
  end
  else
  begin
    Result.X := X;
    Result.Y := Y;
  end;
end;

function TVec2F.Stretch(ALength: Single): TVec2F;
var
  Norm: Single;
begin
  if (X <> 0) and (Y <> 0) then
  begin
    Norm := Abs(ALength) / Sqrt(X * X + Y * Y);
    Result.X := X * Norm;
    Result.Y := Y * Norm;
  end;
end;

function TVec2F.Length(): Single;
begin
  Result := Sqrt(X * X + Y * Y);
end;

function TVec2F.LengthSqr(): Single;
begin
  Result := X * X + Y * Y;
end;

function TVec2F.IsZero(): Boolean;
begin
  Result := (X = 0) and (Y = 0);
end;

function TVec2F.IsAnyZero(): Boolean;
begin
  Result := (X = 0) or (Y = 0);
end;

function TVec2F.IsValid(): Boolean;
begin
  Result := not IsNaN(X) and not IsNaN(Y);
end;

function TVec2F.IsInf(): Boolean;
begin
  Result := IsInfinite(X) or IsInfinite(Y);
end;

{ TVec3F }
constructor TVec3F.Create(aX, aY, aZ: Single);
begin
  X := aX;
  Y := aY;
  Z := aZ;
end;

class operator TVec3F.Negative(const Vec: TVec3F): TVec3F;
begin
  Result.X := -Vec.X;
  Result.Y := -Vec.Y;
  Result.Z := -Vec.Z;
end;

class operator TVec3F.Positive(const Vec: TVec3F): TVec3F;
begin
  Result := Vec;
end;

class operator TVec3F.Equal(const A, B: TVec3F): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z);
end;

class operator TVec3F.NotEqual(const A, B: TVec3F): Boolean;
begin
  Result := (A.X <> B.X) or (A.Y <> B.Y) or (A.Z <> B.Z);
end;

class operator TVec3F.Add(const A, B: TVec3F): TVec3F;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
  Result.Z := A.Z + B.Z;
end;

class operator TVec3F.Subtract(const A, B: TVec3F): TVec3F;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
  Result.Z := A.Z - B.Z;
end;

class operator TVec3F.Multiply(const A: TVec3F; B: Single): TVec3F;
begin
  Result.X := A.X * B;
  Result.Y := A.Y * B;
  Result.Z := A.Z * B;
end;

class operator TVec3F.Multiply(A: Single; const B: TVec3F): TVec3F;
begin
  Result.X := A * B.X;
  Result.Y := A * B.Y;
  Result.Z := A * B.Z;
end;

class operator TVec3F.Multiply(const A, B: TVec3F): TVec3F;
begin
  Result.X := A.X * B.X;
  Result.Y := A.Y * B.Y;
  Result.Z := A.Z * B.Z;
end;

class operator TVec3F.Divide(const A: TVec3F; B: Single): TVec3F;
var
  Norm: Single;
begin
  Norm := 1 / B;
  Result.X := A.X * Norm;
  Result.Y := A.Y * Norm;
  Result.Z := A.Z * Norm;
end;

class operator TVec3F.Divide(A: Single; const B: TVec3F): TVec3F;
begin
  Result.X := A / B.X;
  Result.Y := A / B.Y;
  Result.Z := A / B.Z;
end;

class operator TVec3F.Divide(const A, B: TVec3F): TVec3F;
begin
  Result.X := A.X / B.X;
  Result.Y := A.Y / B.Y;
  Result.Z := A.Z / B.Z;
end;

function TVec3F.Dot(const Vec: TVec3F): Single;
begin
  Result := X * Vec.X + Y * Vec.Y + Z * Vec.Z;
end;

function TVec3F.Cross(const Vec: TVec3F): TVec3F;
begin
  Result.X := Y * Vec.Z - Z * Vec.Y;
  Result.Y := Z * Vec.X - X * Vec.Z;
  Result.Z := X * Vec.Y - Y * Vec.X;
end;

function TVec3F.Projection(const Vec: TVec3F): TVec3F;
var
  Norm: Single;
begin
  Norm := (X * Vec.X + Y * Vec.Y + Z * Vec.Z) / (X * X + Y * Y + Z * Z);
  Result.X := X * Norm;
  Result.Y := Y * Norm;
  Result.Z := Z * Norm;
end;

function TVec3F.Normalize(): TVec3F;
var
  Norm: Single;
begin
  Norm := 1 / Sqrt(X * X + Y * Y + Z * Z);
  Result.X := X * Norm;
  Result.Y := Y * Norm;
  Result.Z := Z * Norm;
end;

function TVec3F.Distance(const Vec: TVec3F): Single;
begin
  Result := Sqrt(Sqr(X - Vec.X) + Sqr(Y - Vec.Y) + Sqr(Z - Vec.Z));
end;

function TVec3F.Clip(ALength: Single): TVec3F;
var
  Len, Clip: Single;
begin
  Clip := Abs(ALength);
  Len := Sqrt(X * X + Y * Y + Z * Z);
  if (Clip < Len) then
  begin
    Result.X := Result.X * Clip / Len;
    Result.Y := Result.Y * Clip / Len;
    Result.Z := Result.Z * Clip / Len;
  end
  else
  begin
    Result.X := X;
    Result.Y := Y;
    Result.Z := Z;
  end;
end;

function TVec3F.Stretch(ALength: Single): TVec3F;
var
  Norm: Single;
begin
  if (X <> 0) and (Y <> 0) and (Z <> 0) then
  begin
    Norm := Abs(ALength) / Sqrt(X * X + Y * Y + Z * Z);
    Result.X := X * Norm;
    Result.Y := Y * Norm;
    Result.Z := Z * Norm;
  end;
end;

function TVec3F.Rotate(const ANormal: TVec3F): TVec3F;
var
  bX, bZ: TVec3F;
begin
  // If the normal vector is already the world space upwards (or downwards) vector, don't do anything
  if not NearValue(ANormal.Dot(TVec3F.Create(0, 1, 0)), 1, 1e-3) then
  begin
    // Build the orthonormal basis of the normal vector.
    bX := ANormal.Cross(TVec3F.Create(0, 1, 0)).Normalize;
    bZ := ANormal.Cross(bX).Normalize;
    // Transform the unit vector to this basis.
    Result := bX * X + ANormal * Y + bZ * Z;
  end
  else
    Result := Self * uMathUtils.Sign(Self.Dot(ANormal));
end;

function TVec3F.Length(): Single;
begin
  Result := Sqrt(X * X + Y * Y + Z * Z);
end;

function TVec3F.LengthSqr(): Single;
begin
  Result := X * X + Y * Y + Z * Z;
end;

function TVec3F.IsZero(): Boolean;
begin
  Result := (X = 0) and (Y = 0) and (Z = 0);
end;

function TVec3F.IsAnyZero(): Boolean;
begin
  Result := (X = 0) or (Y = 0) or (Z = 0);
end;

function TVec3F.IsValid(): Boolean;
begin
  Result := not IsNaN(X) and not IsNaN(Y) and not IsNaN(Z);
end;

function TVec3F.IsInf(): Boolean;
begin
  Result := IsInfinite(X) or IsInfinite(Y) or IsInfinite(Z);
end;

end.

