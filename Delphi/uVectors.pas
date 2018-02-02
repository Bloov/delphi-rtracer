unit uVectors;

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

    class operator Negative(const Vec: TVec3F): TVec3F; inline;
    class operator Positive(const Vec: TVec3F): TVec3F; inline;
    class operator Equal(const A, B: TVec3F): Boolean; inline;
    class operator NotEqual(const A, B: TVec3F): Boolean; inline;
    class operator Add(const A, B: TVec3F): TVec3F; inline;
    class operator Subtract(const A, B: TVec3F): TVec3F; inline;
    class operator Multiply(const A: TVec3F; B: Single): TVec3F; overload; inline;
    class operator Multiply(A: Single; const B: TVec3F): TVec3F; overload; inline;
    class operator Multiply(const A, B: TVec3F): Single; overload; //inline;
    class operator Divide(const A: TVec3F; B: Single): TVec3F; overload; inline;
    class operator Divide(A: Single; const B: TVec3F): TVec3F; overload; inline;

    // componentwise operations
    function CMul(const Vec: TVec3F): TVec3F; inline;
    function CDiv(const Vec: TVec3F): TVec3F; inline;
    function CMin(const Vec: TVec3F): TVec3F;
    function CMax(const Vec: TVec3F): TVec3F;

    function Dot(const Vec: TVec3F): Single; inline;
    function CrossAsm(const Vec: TVec3F): TVec3F;
    function Cross{Native}(const Vec: TVec3F): TVec3F; inline;
    function Projection(const Vec: TVec3F): TVec3F; inline;
    function NormalizeAsm(): TVec3F; //inline;
    function Normalize{Native}(): TVec3F; inline;
    function Distance(const Vec: TVec3F): Single; inline;
    function Clip(ALength: Single): TVec3F;
    function Stretch(ALength: Single): TVec3F;
    function Lerp(const Target: TVec3F; Time: Single): TVec3F; inline;
    function Rotate{Asm}(const ANormal: TVec3F): TVec3F;
    function RotateNative(const ANormal: TVec3F): TVec3F;

    function Length(): Single; inline;
    function LengthSqr(): Single; inline;

    function IsZero(): Boolean; inline;
    function IsAnyZero(): Boolean; inline;
    function IsValid(): Boolean;
    function IsInf(): Boolean;

    case Boolean of
      True: (Arr: array [0..3] of Single);
      False: (X, Y, Z: Single);
  end;

function Vec2F(X, Y: Single): TVec2F; inline;
function Vec3F(X, Y, Z: Single): TVec3F; inline;

implementation

uses
  Math, uMathUtils;

var
  Spacer0: Integer;
  Spacer1: Integer;
  //Spacer2: Integer;
  // Apply spacers for adjust Vectors align by 16 byte
  Vec3Mask: TVec3F;
  XUnit: TVec3F;
  YUnit: TVec3F;
  ZUnit: TVec3F;
  AllUnit: TVec3F;

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

class operator TVec3F.Multiply(const A, B: TVec3F): Single;
asm
  movups xmm0, [A];
  movups xmm1, [B];
  dpps   xmm0, xmm1, 01110001b;
  movss  [Result], xmm0;
end;
{begin
  Result := A.X * B.X + A.Y * B.Y + A.Z * B.Z;
end;}

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
begin
  Result.X := Min(X, Vec.X);
  Result.Y := Min(Y, Vec.Y);
  Result.Z := Min(Z, Vec.Z);
end;

function TVec3F.CMax(const Vec: TVec3F): TVec3F;
begin
  Result.X := Max(X, Vec.X);
  Result.Y := Max(Y, Vec.Y);
  Result.Z := Max(Z, Vec.Z);
end;

function TVec3F.Dot(const Vec: TVec3F): Single;
begin
  Result := Self * Vec;
end;

function TVec3F.CrossAsm(const Vec: TVec3F): TVec3F;
asm
  movups xmm0, [Self];
  movups xmm1, [Vec];
  movaps xmm7, [Vec3Mask];
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
end;

function TVec3F.Cross{Native}(const Vec: TVec3F): TVec3F;
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

function TVec3F.NormalizeAsm(): TVec3F;
asm
  movups  xmm0, [Self];
  movaps  xmm7, [Vec3Mask];
  andps   xmm0, xmm7;
  movaps  xmm2, xmm0;

  mulps   xmm0, xmm0;
  haddps  xmm0, xmm0;
  haddps  xmm0, xmm0;
  //dpps    xmm0, xmm0, 01111111b;
  sqrtps  xmm0, xmm0;
  divps   xmm2, xmm0;

  movups  [Result], xmm2;
end;

function TVec3F.Normalize{Native}(): TVec3F;
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

function TVec3F.Lerp(const Target: TVec3F; Time: Single): TVec3F;
begin
  Result := (1 - Time) * Self + Time * Target;
end;

function TVec3F.Rotate{Asm}(const ANormal: TVec3F): TVec3F;
const
  cPrecision: Single = 1e-4;
asm
  movups xmm0, [ANormal];
  movaps xmm7, [Vec3Mask];
  andps  xmm0, xmm7;
  // ANormal in xmm0
  // Vec3Mask in xmm7
  movaps xmm1, [XUnit];
  // XVec in xmm1
  movaps xmm2, [ZUnit];
  // ZVec in xmm2

  movaps  xmm3, xmm0;
  dpps    xmm3, xmm2, 01111111b;
  // ANormal * ZVec in xmm3 (dot product)

  xorps   xmm4, xmm4;
  subss   xmm4, xmm3;
  maxss   xmm3, xmm4;
  // Abs(ANormal * ZVec) in xmm3

  subss   xmm1, xmm3;
  xorps   xmm4, xmm4;
  subss   xmm4, xmm1;
  maxss   xmm1, xmm4;
  // Abs(1 - Abs(ANormal, ZVec)) in xmm1

  // check 1 - Abs(1 - Abs(ANormal, ZVec)) < cPrecision
  movss  xmm3, [cPrecision];
  comiss xmm3, xmm1;
  ja     @simple_case;

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
  subps  xmm3, xmm4;
  // bX = Cross(ANormal, ZVec) in xmm3

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
  subps  xmm1, xmm2;
  // bY = Cross(ANormal, bX) in xmm1

  // xmm0 - ANormal
  // xmm1 - bY
  // xmm3 - bX

  // Normalize bX
  movaps  xmm2, xmm3;
  dpps    xmm3, xmm3, 01111111b
  sqrtps  xmm3, xmm3;
  divps   xmm2, xmm3;
  // bX in xmm2

  // Normalize bY
  movaps  xmm3, xmm1;
  dpps    xmm1, xmm1, 01111111b;
  sqrtps  xmm1, xmm1;
  divps   xmm3, xmm1;
  // bY in xmm3

  // Transform the unit vector to this basis
  // xmm0 - ANormal
  // xmm2 - bX
  // xmm3 - bY

  movups  xmm1, [Self];
  andps   xmm1, xmm7;
  // Self in xmm1

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
  dpps    xmm0, xmm1, 01111111b;
  // now ANormal * Self in xmm0 (dot product)

  xorps   xmm2, xmm2;
  comiss  xmm0, xmm2;
  ja      @simple_result

  subps   xmm2, xmm1;
  movups  [Result], xmm2;
  jmp     @return;

@simple_result:
  //  Result = Self * Sign(Self * ANormal);
  movups  [Result], xmm1;

@return:
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

initialization
  Spacer0 := 0;
  Spacer1 := 0;
  //Spacer2 := 0;

  PCardinal(Pointer(@Vec3Mask.Arr[0]))^ := $FFFFFFFF;
  PCardinal(Pointer(@Vec3Mask.Arr[1]))^ := $FFFFFFFF;
  PCardinal(Pointer(@Vec3Mask.Arr[2]))^ := $FFFFFFFF;
  PCardinal(Pointer(@Vec3Mask.Arr[3]))^ := 0;

  XUnit := Vec3F(1, 0, 0);
  XUnit.Arr[3] := 0;

  YUnit := Vec3F(0, 1, 0);
  YUnit.Arr[3] := 0;

  ZUnit := Vec3F(0, 0, 1);
  ZUnit.Arr[3] := 0;

  AllUnit := Vec3F(1, 1, 1);
  AllUnit.Arr[3] := 0;
end.

