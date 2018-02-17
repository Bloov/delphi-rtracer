unit uVectors;

{$I defines.inc}

interface

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
    function Lerp(const Target: TVec2F; Time: Single): TVec2F; inline;

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
    constructor Create(aX, aY, aZ: Single); overload;
    constructor CreateUnitSpherical(Phi, Theta: Single);

    // sets Arr[3] to zero
    procedure FixTail();

    class operator Negative(const Vec: TVec3F): TVec3F; inline;
    class operator Positive(const Vec: TVec3F): TVec3F; inline;
    class operator Equal(const A, B: TVec3F): Boolean; inline;
    class operator NotEqual(const A, B: TVec3F): Boolean; inline;
    class operator Add(const A, B: TVec3F): TVec3F; overload; {$IFNDEF USE_SSE}inline;{$ENDIF}
    class operator Add(const A: TVec3F; B: Single): TVec3F; overload; {$IFNDEF USE_SSE}inline;{$ENDIF}
    class operator Add(A: Single; const B: TVec3F): TVec3F; overload; {$IFNDEF USE_SSE}inline;{$ENDIF}
    class operator Subtract(const A, B: TVec3F): TVec3F; overload; {$IFNDEF USE_SSE}inline;{$ENDIF}
    class operator Subtract(const A: TVec3F; B: Single): TVec3F; overload; {$IFNDEF USE_SSE}inline;{$ENDIF}
    class operator Subtract(A: Single; const B: TVec3F): TVec3F; overload; {$IFNDEF USE_SSE}inline;{$ENDIF}
    class operator Multiply(const A: TVec3F; B: Single): TVec3F; overload; {$IFNDEF USE_SSE_ALLCASES}inline;{$ENDIF}
    class operator Multiply(A: Single; const B: TVec3F): TVec3F; overload; {$IFNDEF USE_SSE_ALLCASES}inline;{$ENDIF}
    class operator Multiply(const A, B: TVec3F): Single; overload; {$IFNDEF USE_SSE}inline;{$ENDIF}
    class operator Divide(const A: TVec3F; B: Single): TVec3F; overload; inline;
    class operator Divide(A: Single; const B: TVec3F): TVec3F; overload; inline;
    class operator Divide(const A, B: TVec3F): TVec3F; overload; inline;

    // Componentwise operations
    function CMul(const Vec: TVec3F): TVec3F; inline;
    function CDiv(const Vec: TVec3F): TVec3F; inline;
    function CMin(const Vec: TVec3F): TVec3F;
    function CMax(const Vec: TVec3F): TVec3F;

    function Dot(const Vec: TVec3F): Single; inline;
    function Cross(const Vec: TVec3F): TVec3F;
    function CrossNative(const Vec: TVec3F): TVec3F; inline;
    function Projection(const Vec: TVec3F): TVec3F; inline;
    function Distance(const Vec: TVec3F): Single; inline;
    function DistanceSqr(const Vec: TVec3F): Single; inline;
    function Normalize(): TVec3F; {$IFNDEF USE_SSE}inline;{$ENDIF}
    function NormalizeNative(): TVec3F; inline;
    procedure SetNormalized(); {$IFNDEF USE_SSE}inline;{$ENDIF}
    function Clip(ALength: Single): TVec3F;
    function Stretch(ALength: Single): TVec3F;
    function Lerp(const Target: TVec3F; Time: Single): TVec3F; inline;
    function Rotate(const ANormal: TVec3F): TVec3F;
    function RotateNative(const ANormal: TVec3F): TVec3F;
    function ReflectByNormal(const Normal: TVec3F): TVec3F;
    function Reflect(const Vec: TVec3F): TVec3F;

    function Length(): Single; {$IFNDEF USE_SSE}inline;{$ENDIF}
    function LengthSqr(): Single; {$IFNDEF USE_SSE}inline;{$ENDIF}

    function IsZero(): Boolean; inline;
    function IsAnyZero(): Boolean; inline;
    function IsNormalized(): Boolean; overload;
    function IsNormalized(APrecision: Single): Boolean; overload;
    function IsValid(): Boolean;
    function IsInf(): Boolean;

    case Boolean of
      True: (Arr: array [0..3] of Single);
      False: (X, Y, Z: Single);
  end;
  PVec3F = ^TVec3F;

function Vec2F(X, Y: Single): TVec2F; inline;
function Vec3F(X, Y, Z: Single): TVec3F; inline;
function Vec3Full(X, Y, Z, T: Single): TVec3F; inline;

implementation

uses
  Math, uMathUtils;

var
  VectorsMem, AlignedMem: Pointer;

  SSE_MASK_SIGN: PVec3F; // sign bit mask
  SSE_MASK_PNPN: PVec3F; // pos, neg, pos, neg XYZT mask
  SSE_MASK_NPNP: PVec3F; // neg, pos, neg, pos XYZT mask
  SSE_MASK_0FFF: PVec3F; // XYZ0 mask
  SSE_MASK_ABS: PVec3F;  // abs value mask

  SSE_XUnit: PVec3F;   // X-direction unit vector
  SSE_YUnit: PVec3F;   // Y-direction unit vector
  SSE_ZUnit: PVec3F;   // Z-direction unit vector
  SSE_XYZUnit: PVec3F; // all directions vector

  SSE_OneHalf: PVec3F; // (0.5, 0.5, 0.5, 0.5)
  SSE_One: PVec3F;     // (1.0, 1.0, 1.0, 1.0)
  SSE_Two: PVec3F;     // (2.0, 2.0, 2.0, 2.0)
  SSE_Three: PVec3F;   // (3.0, 3.0, 3.0, 3.0)

function Vec2F(X, Y: Single): TVec2F;
begin
  Result.X := X;
  Result.Y := Y;
end;

function Vec3F(X, Y, Z: Single): TVec3F;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

function Vec3Full(X, Y, Z, T: Single): TVec3F;
begin
  Result.Arr[0] := X;
  Result.Arr[1] := Y;
  Result.Arr[2] := Z;
  Result.Arr[3] := T;
end;

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

function TVec2F.Lerp(const Target: TVec2F; Time: Single): TVec2F;
begin
  Result := (1 - Time) * Self + Time * Target;
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

constructor TVec3F.CreateUnitSpherical(Phi, Theta: Single);
begin
  X := Sin(Theta) * Cos(Phi);
  Y := Sin(Theta) * Sin(Phi);
  Z := Cos(Theta);
end;

procedure TVec3F.FixTail();
begin
  Arr[3] := 0;
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
{$IFDEF USE_SSE}
asm
  movups xmm0, [A];
  movups xmm1, [B];
  addps  xmm0, xmm1;
  movups [Result], xmm0;
{$ELSE}
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
  Result.Z := A.Z + B.Z;
{$ENDIF}
end;

class operator TVec3F.Add(const A: TVec3F; B: Single): TVec3F;
begin
  Result.X := A.X + B;
  Result.Y := A.Y + B;
  Result.Z := A.Z + B;
end;

class operator TVec3F.Add(A: Single; const B: TVec3F): TVec3F;
begin
  Result.X := A + B.X;
  Result.Y := A + B.Y;
  Result.Z := A + B.Z;
end;

class operator TVec3F.Subtract(const A, B: TVec3F): TVec3F;
{$IFDEF USE_SSE}
asm
  movups xmm0, [A];
  movups xmm1, [B];
  subps  xmm0, xmm1;
  movups [Result], xmm0;
{$ELSE}
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
  Result.Z := A.Z - B.Z;
{$ENDIF}
end;

class operator TVec3F.Subtract(const A: TVec3F; B: Single): TVec3F;
begin
  Result.X := A.X - B;
  Result.Y := A.Y - B;
  Result.Z := A.Z - B;
end;

class operator TVec3F.Subtract(A: Single; const B: TVec3F): TVec3F;
begin
  Result.X := A - B.X;
  Result.Y := A - B.Y;
  Result.Z := A - B.Z;
end;

class operator TVec3F.Multiply(const A: TVec3F; B: Single): TVec3F;
{$IFDEF USE_SSE_ALLCASES}
asm
  movups xmm0, [A];
  movss  xmm1, [B];
  shufps xmm1, xmm1, 00000000b;
  mulps  xmm0, xmm1;
  movups [Result], xmm0;
{$ELSE}
begin
  Result.X := A.X * B;
  Result.Y := A.Y * B;
  Result.Z := A.Z * B;
{$ENDIF}
end;

class operator TVec3F.Multiply(A: Single; const B: TVec3F): TVec3F;
{$IFDEF USE_SSE_ALLCASES}
asm
  movss xmm0, [A];
  movups xmm1, [B];
  shufps xmm0, xmm0, 00000000b;
  mulps  xmm0, xmm1;
  movups [Result], xmm0;
{$ELSE}
begin
  Result.X := A * B.X;
  Result.Y := A * B.Y;
  Result.Z := A * B.Z;
{$ENDIF}
end;

class operator TVec3F.Multiply(const A, B: TVec3F): Single;
{$IFDEF USE_SSE_ALLCASES}
asm
  movups xmm0, [A];
  movups xmm1, [B];
  dpps   xmm0, xmm1, 01110001b;
  movss  [Result], xmm0;
{$ELSE}
begin
  Result := A.X * B.X + A.Y * B.Y + A.Z * B.Z;
{$ENDIF}
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
  Result.X := A.Z / B.X;
  Result.Y := A.Y / B.Y;
  Result.Z := A.Z / B.Z;
end;

function TVec3F.CMul(const Vec: TVec3F): TVec3F;
begin
  Result.X := X * Vec.X;
  Result.Y := Y * Vec.Y;
  Result.Z := Z * Vec.Z;
end;

function TVec3F.CDiv(const Vec: TVec3F): TVec3F;
begin
  Result.X := X / Vec.X;
  Result.Y := Y / Vec.Y;
  Result.Z := Z / Vec.Z;
end;

function TVec3F.CMin(const Vec: TVec3F): TVec3F;
{$IFDEF USE_SSE}
asm
  movups xmm0, [Self];
  movups xmm1, [Vec];
  minps  xmm0, xmm1;
  movups [Result], xmm0;
{$ELSE}
begin
  Result.X := Min(X, Vec.X);
  Result.Y := Min(Y, Vec.Y);
  Result.Z := Min(Z, Vec.Z);
{$ENDIF}
end;

function TVec3F.CMax(const Vec: TVec3F): TVec3F;
{$IFDEF USE_SSE}
asm
  movups xmm0, [Self];
  movups xmm1, [Vec];
  maxps  xmm0, xmm1;
  movups [Result], xmm0;
{$ELSE}
begin
  Result.X := Max(X, Vec.X);
  Result.Y := Max(Y, Vec.Y);
  Result.Z := Max(Z, Vec.Z);
{$ENDIF}
end;

function TVec3F.Dot(const Vec: TVec3F): Single;
begin
  Result := Self * Vec;
end;

function TVec3F.Cross(const Vec: TVec3F): TVec3F;
{$IFDEF USE_SSE}
asm
  mov    ebx,  [AlignedMem];
  movups xmm0, [Self];
  movups xmm1, [Vec];
  movaps xmm7, [ebx + $30]; // SSE_MASK_0FFF
  andps  xmm0, xmm7;
  andps  xmm1, xmm7;
  movaps xmm2, xmm0;
  movaps xmm3, xmm1;

  shufps xmm0, xmm0, 11001001b; //0, 0, 2, 1
  shufps xmm1, xmm1, 11010010b; //0, 1, 0, 2
  shufps xmm2, xmm2, 11010010b; //0, 1, 0, 2
  shufps xmm3, xmm3, 11001001b; //0, 0, 2, 1

  mulps  xmm0, xmm1;
  mulps  xmm2, xmm3;
  subps  xmm0, xmm2;

  movups [Result], xmm0;
{$ELSE}
begin
  Result.X := Y * Vec.Z - Z * Vec.Y;
  Result.Y := Z * Vec.X - X * Vec.Z;
  Result.Z := X * Vec.Y - Y * Vec.X;
{$ENDIF}
end;

function TVec3F.CrossNative(const Vec: TVec3F): TVec3F;
begin
  Result.X := Y * Vec.Z - Z * Vec.Y;
  Result.Y := Z * Vec.X - X * Vec.Z;
  Result.Z := X * Vec.Y - Y * Vec.X;
end;

function TVec3F.Projection(const Vec: TVec3F): TVec3F;
var
  Norm: Single;
begin
  // Result = Self * Dot(Self * Vec) / Dot(Vec * Vec)
  Norm := (X * Vec.X + Y * Vec.Y + Z * Vec.Z) / (X * X + Y * Y + Z * Z);
  Result.X := X * Norm;
  Result.Y := Y * Norm;
  Result.Z := Z * Norm;
end;

function TVec3F.Distance(const Vec: TVec3F): Single;
begin
  Result := Sqrt(Sqr(X - Vec.X) + Sqr(Y - Vec.Y) + Sqr(Z - Vec.Z));
end;

function TVec3F.DistanceSqr(const Vec: TVec3F): Single;
begin
  Result := Sqr(X - Vec.X) + Sqr(Y - Vec.Y) + Sqr(Z - Vec.Z);
end;

function TVec3F.Normalize(): TVec3F;
{$IFDEF USE_SSE}
asm
  movups  xmm0, [Self];
  movaps  xmm1, xmm0;

  dpps    xmm0, xmm0, 01111111b;
  sqrtps  xmm0, xmm0;
  divps   xmm1, xmm0;

  movups  [Result], xmm1;
{$ELSE}
var
  Norm: Single;
begin
  Norm := 1 / Sqrt(X * X + Y * Y + Z * Z);
  Result.X := X * Norm;
  Result.Y := Y * Norm;
  Result.Z := Z * Norm;
{$ENDIF}
end;

function TVec3F.NormalizeNative(): TVec3F;
var
  Norm: Single;
begin
  Norm := 1 / Sqrt(X * X + Y * Y + Z * Z);
  Result.X := X * Norm;
  Result.Y := Y * Norm;
  Result.Z := Z * Norm;
end;

procedure TVec3F.SetNormalized(); {$IFNDEF USE_SSE}inline;{$ENDIF}
{$IFDEF USE_SSE}
asm
  movups  xmm0, [Self];
  movaps  xmm1, xmm0;

  dpps    xmm0, xmm0, 01111111b;
  sqrtps  xmm0, xmm0;
  divps   xmm1, xmm0;

  movups  [Self], xmm1;
{$ELSE}
var
  Norm: Single;
begin
  Norm := 1 / Sqrt(X * X + Y * Y + Z * Z);
  X := X * Norm;
  Y := Y * Norm;
  Z := Z * Norm;
{$ENDIF}
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

function TVec3F.Lerp(const Target: TVec3F; Time: Single): TVec3F;
begin
  Result := (1 - Time) * Self + Time * Target;
end;

function TVec3F.Rotate(const ANormal: TVec3F): TVec3F;
const
  cPrecision: Single = 1e-4;
{$IFDEF USE_SSE}
asm
  movups xmm0, [ANormal];
  mov    ebx,  [AlignedMem];
  movaps xmm7, [ebx + $30]; // SSE_MASK_0FFF
  movaps xmm6, [ebx + $40]; // SSE_MASK_ABS
  movaps xmm1, [ebx + $50]; // SSE_XUnit
  movaps xmm2, [ebx + $70]; // SSE_ZUnit
  andps  xmm0, xmm7;

  movaps  xmm3, xmm0;
  dpps    xmm3, xmm2, 01111111b;
  andps   xmm3, xmm6; // Abs(Dot(ANormal, ZVec)) in xmm3

  subss   xmm1, xmm3;
  andps   xmm1, xmm6; // Abs(1 - Abs(ANormal, ZVec)) in xmm1

  movss  xmm3, [cPrecision];
  comiss xmm3, xmm1;
  ja     @simple_case; // if 1 - Abs(1 - Abs(ANormal, ZVec)) < cPrecision

  // Build the orthonormal basis of the normal vector
  // xmm0 - ANormal
  // xmm2 - ZVec
  movaps xmm3, xmm0;
  movaps xmm4, xmm0;
  movaps xmm5, xmm2;

  shufps xmm3, xmm3, 11001001b; //3, 0, 2, 1
  shufps xmm2, xmm2, 11010010b; //3, 1, 0, 2
  shufps xmm4, xmm4, 11010010b; //3, 1, 0, 2
  shufps xmm5, xmm5, 11001001b; //3, 0, 2, 1

  mulps  xmm3, xmm2;
  mulps  xmm4, xmm5;
  subps  xmm3, xmm4; // bX = Cross(ANormal, ZVec) in xmm3

  movaps xmm1, xmm0; // copy ANormal
  movaps xmm2, xmm0;
  movaps xmm4, xmm3; // copy bX
  movaps xmm5, xmm3;

  shufps xmm1, xmm1, 11001001b; //3, 0, 2, 1
  shufps xmm4, xmm4, 11010010b; //3, 1, 0, 2
  shufps xmm2, xmm2, 11010010b; //3, 1, 0, 2
  shufps xmm5, xmm5, 11001001b; //3, 0, 2, 1

  mulps  xmm1, xmm4;
  mulps  xmm2, xmm5;
  subps  xmm1, xmm2; // bY = Cross(ANormal, bX) in xmm1

  // xmm0 - ANormal
  // xmm1 - bY
  // xmm3 - bX

  // Normalize bX
  movaps  xmm2, xmm3;
  dpps    xmm3, xmm3, 01111111b
  sqrtps  xmm3, xmm3;
  divps   xmm2, xmm3; // bX in xmm2

  // Normalize bY
  movaps  xmm3, xmm1;
  dpps    xmm1, xmm1, 01111111b;
  sqrtps  xmm1, xmm1;
  divps   xmm3, xmm1; // bY in xmm3

  // Transform the unit vector to this basis
  // xmm0 - ANormal
  // xmm2 - bX
  // xmm3 - bY

  movups  xmm1, [Self];
  andps   xmm1, xmm7; // Self in xmm1

  movss   xmm4, xmm1; // Get X
  shufps  xmm4, xmm4, 00000000b;
  mulps   xmm4, xmm2; // X * bX

  shufps  xmm1, xmm1, 11001001b; // rotate xyzw -> yxzw
  movss   xmm5, xmm1; // Get Y
  shufps  xmm5, xmm5, 00000000b;
  mulps   xmm5, xmm3; // Y * bY

  shufps  xmm1, xmm1, 11001001b; // rotate yzxw -> zxyw
  movss   xmm6, xmm1; // Get Z
  shufps  xmm6, xmm6, 00000000b;
  mulps   xmm6, xmm0; // Z * ANormal

  addps   xmm4, xmm5;
  addps   xmm4, xmm6;
  movups  [Result], xmm4;
  jmp     @return;

@simple_case:
  // xmm0 - ANormal
  movups  xmm1, [Self];
  dpps    xmm0, xmm1, 01111111b; // now ANormal * Self in xmm0 (dot product)

  xorps   xmm2, xmm2;
  comiss  xmm0, xmm2;
  ja      @simple_result

  subps   xmm2, xmm1;
  movups  [Result], xmm2;
  jmp     @return;

@simple_result:
  movups  [Result], xmm1; //  Result = Self * Sign(Self * ANormal);

@return:
{$ELSE}
var
  bX, bY: TVec3F;
begin
  // If the normal vector is already the world space upwards (or downwards) vector, don't do anything
  if not NearValue(Abs(ANormal * Vec3F(0, 0, 1)), 1, cPrecision) then
  begin
    // Build the orthonormal basis of the normal vector.
    bX := ANormal.Cross(Vec3F(0, 0, 1)).Normalize;
    bY := ANormal.Cross(bX).Normalize;
    // Transform the unit vector to this basis.
    Result := bX * X + bY * Y + ANormal * Z;
  end
  else
    Result := Self * uMathUtils.Sign(Self.Dot(ANormal));
{$ENDIF}
end;

function TVec3F.RotateNative(const ANormal: TVec3F): TVec3F;
const
  cPrecision: Single = 1e-4;
var
  bX, bY: TVec3F;
begin
  // If the normal vector is already the world space upwards (or downwards) vector, don't do anything
  if not NearValue(Abs(ANormal * Vec3F(0, 0, 1)), 1, cPrecision) then
  begin
    // Build the orthonormal basis of the normal vector.
    bX := ANormal.Cross(Vec3F(0, 0, 1)).Normalize;
    bY := ANormal.Cross(bX).Normalize;
    // Transform the unit vector to this basis.
    Result := bX * X + bY * Y + ANormal * Z;
  end
  else
    Result := Self * uMathUtils.Sign(Self.Dot(ANormal));
end;

function TVec3F.ReflectByNormal(const Normal: TVec3F): TVec3F;
{$IFDEF USE_SSE}
asm
  movups xmm0, [Self];
  movups xmm1, [Normal];

  movaps xmm2, xmm0;
  dpps   xmm2, xmm1, 01111111b;
  addps  xmm2, xmm2; // 2 * Dot(Self * Normal)

  mulps  xmm1, xmm2;
  subps  xmm0, xmm1; // Self - 2 * Normal * Dot(Self * Normal)

  movups [Result], xmm0;
{$ELSE}
begin
  Result := Self - Normal * (2 * (Self * Normal));
{$ENDIF}
end;

function TVec3F.Reflect(const Vec: TVec3F): TVec3F;
{$IFDEF USE_SSE}
asm
  movups xmm0, [Self];
  movups xmm1, [Vec];
  movaps xmm3, xmm1;
  movaps xmm2, xmm0;

  dpps   xmm3, xmm3, 01111111b;
  sqrtps xmm3, xmm3;
  divps  xmm1, xmm3; // Normalize the Vec

  dpps   xmm2, xmm1, 01111111b;
  addps  xmm2, xmm2; // 2 * Dot(Self * Normal)

  mulps  xmm1, xmm2;
  subps  xmm0, xmm1; // Self - 2 * Normal * Dot(Self * Normal)

  movups [Result], xmm0;
{$ELSE}
var
  Normal: TVec3F;
begin
  Normal := Vec.Normalize;
  Result := Self - Normal * (2 * (Self * Normal));
{$ENDIF}
end;

function TVec3F.Length(): Single;
{$IFDEF USE_SSE}
asm
  movups xmm0, [Self];
  dpps   xmm0, xmm0, 01110001b;
  sqrtss xmm0, xmm0;
  movss  [Result], xmm0;
{$ELSE}
begin
  Result := Sqrt(X * X + Y * Y + Z * Z);
{$ENDIF}
end;

function TVec3F.LengthSqr(): Single;
{$IFDEF USE_SSE}
asm
  movups xmm0, [Self];
  dpps   xmm0, xmm0, 01110001b;
  movss  [Result], xmm0;
{$ELSE}
begin
  Result := X * X + Y * Y + Z * Z;
{$ENDIF}
end;

function TVec3F.IsZero(): Boolean;
begin
  Result := (X = 0) and (Y = 0) and (Z = 0);
end;

function TVec3F.IsAnyZero(): Boolean;
begin
  Result := (X = 0) or (Y = 0) or (Z = 0);
end;

function TVec3F.IsNormalized(): Boolean;
begin
  Result := IsNormalized(1e-6);
end;

function TVec3F.IsNormalized(APrecision: Single): Boolean;
begin
  Result := (Abs(Length - 1.0) < APrecision);
end;

function TVec3F.IsValid(): Boolean;
begin
  Result := not IsNaN(X) and not IsNaN(Y) and not IsNaN(Z);
end;

function TVec3F.IsInf(): Boolean;
begin
  Result := IsInfinite(X) or IsInfinite(Y) or IsInfinite(Z);
end;

initialization
  VectorsMem := GetMemory(32 * SizeOf(TVec3F) + $10);
  AlignedMem := Pointer(((NativeUInt(VectorsMem) + $10) div $10) * $10);

  SSE_MASK_SIGN := PVec3F(NativeUInt(AlignedMem) + $00);
  PCardinal(Pointer(@SSE_MASK_SIGN.Arr[0]))^ := $80000000;
  PCardinal(Pointer(@SSE_MASK_SIGN.Arr[1]))^ := $80000000;
  PCardinal(Pointer(@SSE_MASK_SIGN.Arr[2]))^ := $80000000;
  PCardinal(Pointer(@SSE_MASK_SIGN.Arr[3]))^ := $80000000;

  SSE_MASK_PNPN := PVec3F(NativeUInt(AlignedMem) + $10);
  PCardinal(Pointer(@SSE_MASK_PNPN.Arr[0]))^ := $00000000;
  PCardinal(Pointer(@SSE_MASK_PNPN.Arr[1]))^ := $80000000;
  PCardinal(Pointer(@SSE_MASK_PNPN.Arr[2]))^ := $00000000;
  PCardinal(Pointer(@SSE_MASK_PNPN.Arr[3]))^ := $80000000;

  SSE_MASK_NPNP := PVec3F(NativeUInt(AlignedMem) + $20);
  PCardinal(Pointer(@SSE_MASK_NPNP.Arr[0]))^ := $80000000;
  PCardinal(Pointer(@SSE_MASK_NPNP.Arr[1]))^ := $00000000;
  PCardinal(Pointer(@SSE_MASK_NPNP.Arr[2]))^ := $80000000;
  PCardinal(Pointer(@SSE_MASK_NPNP.Arr[3]))^ := $00000000;

  SSE_MASK_0FFF := PVec3F(NativeUInt(AlignedMem) + $30);
  PCardinal(Pointer(@SSE_MASK_0FFF.Arr[0]))^ := $FFFFFFFF;
  PCardinal(Pointer(@SSE_MASK_0FFF.Arr[1]))^ := $FFFFFFFF;
  PCardinal(Pointer(@SSE_MASK_0FFF.Arr[2]))^ := $FFFFFFFF;
  PCardinal(Pointer(@SSE_MASK_0FFF.Arr[3]))^ := $00000000;

  SSE_MASK_ABS := PVec3F(NativeUInt(AlignedMem) + $40);
  PCardinal(Pointer(@SSE_MASK_ABS.Arr[0]))^ := $7FFFFFFF;
  PCardinal(Pointer(@SSE_MASK_ABS.Arr[1]))^ := $7FFFFFFF;
  PCardinal(Pointer(@SSE_MASK_ABS.Arr[2]))^ := $7FFFFFFF;
  PCardinal(Pointer(@SSE_MASK_ABS.Arr[3]))^ := $7FFFFFFF;

  SSE_XUnit := PVec3F(NativeUInt(AlignedMem) + $50);
  SSE_XUnit^ := Vec3Full(1, 0, 0, 0);

  SSE_YUnit := PVec3F(NativeUInt(AlignedMem) + $60);
  SSE_YUnit^ := Vec3Full(0, 1, 0, 0);

  SSE_ZUnit := PVec3F(NativeUInt(AlignedMem) + $70);
  SSE_ZUnit^ := Vec3Full(0, 0, 1, 0);

  SSE_XYZUnit := PVec3F(NativeUInt(AlignedMem) + $80);
  SSE_XYZUnit^ := Vec3Full(1, 1, 1, 0);

  SSE_OneHalf := PVec3F(NativeUInt(AlignedMem) + $90);
  SSE_OneHalf^ := Vec3Full(0.5, 0.5, 0.5, 0.5);

  SSE_One := PVec3F(NativeUInt(AlignedMem) + $A0);
  SSE_One^ := Vec3Full(1, 1, 1, 1);

  SSE_Two := PVec3F(NativeUInt(AlignedMem) + $B0);
  SSE_Two^ := Vec3Full(2, 2, 2, 2);

  SSE_Three := PVec3F(NativeUInt(AlignedMem) + $C0);
  SSE_Three^ := Vec3Full(3, 3, 3, 3);
finalization
  FreeMemory(VectorsMem);
end.

