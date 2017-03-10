unit uAABB;

interface

uses
  uVectors, uRay;

type
  TAABB = packed record
  private
    FMin, FMax: TVec3F;
  public
    constructor Create(const A, B: TVec3F);

    procedure ExpandWith(const Point: TVec3F); overload;
    procedure ExpandWith(const Other: TAABB); overload;

    function Hit(const ARay: TRay; var MinDist, MaxDist: Single): Boolean;
    function HitNative(const ARay: TRay; var MinDist, MaxDist: Single): Boolean;
    function HitUnsafe(const ARay: TRay; var MinDist, MaxDist: Single): Boolean;

    property Min_: TVec3F read FMin;
    property Max_: TVec3F read FMax;
  end;

implementation

uses
  Math, uMathUtils;

var
  VecInf, VecNegInf: TVec3F;

{ TAABB }
constructor TAABB.Create(const A, B: TVec3F);
begin
  FMin := A;
  FMax := B;
end;

procedure TAABB.ExpandWith(const Point: TVec3F);
begin
  FMin := FMin.CMin(Point);
  FMax := FMax.CMax(Point);
end;

procedure TAABB.ExpandWith(const Other: TAABB);
begin
  FMin := FMin.CMin(Other.FMin);
  FMax := FMax.CMax(Other.FMax);
end;

function TAABB.HitNative(const ARay: TRay; var MinDist, MaxDist: Single): Boolean;
var
  I: Integer;
  invD: Single;
  cMin, cMax: Single;
begin
  for I := 0 to 2 do
    if ARay.Direction.Arr[I] <> 0 then
    begin
      invD := 1.0 / ARay.Direction.Arr[I];
      cMin := invD * (FMin.Arr[I] - ARay.Origin.Arr[I]);
      cMax := invD * (FMax.Arr[I] - ARay.Origin.Arr[I]);
      if invD < 0 then
        Swap(cMin, cMax);

      MinDist := Max(MinDist, cMin);
      MaxDist := Min(MaxDist, cMax);
      if MaxDist <= MinDist then
        Exit(False);
    end
    else if (ARay.Origin.Arr[I] <= FMin.Arr[I]) or (ARay.Origin.Arr[I] >= FMax.Arr[I]) then
      Exit(False);

  Result := (MaxDist > 0);
end;

function TAABB.Hit(const ARay: TRay; var MinDist, MaxDist: Single): Boolean;
asm
  movups xmm0, [eax];       // box_min (FMin)
  movups xmm1, [eax + $10]; // box_max (FMax)
  movups xmm2, [edx];       // pos (ARay.Origin)
  movups xmm3, [edx + $20]; // inv_d (ARay.InvDirection)
  movups xmm6, [VecInf];    // plus_inf
  movups xmm7, [VecNegInf]; // minus_inf

  subps  xmm0, xmm2; // l1 = box_min - pos
  subps  xmm1, xmm2; // l2 = box_max - pos
  mulps  xmm0, xmm3; // l1 = l1 * inv_dir
  mulps  xmm1, xmm3; // l2 = l2 * inv_dir
  // free xmm2 - xmm5

  movaps xmm2, xmm0; // copy l1
  movaps xmm3, xmm1; // copy l2
  minps  xmm2, xmm6; // filt_l1a = min(l1, plus_inf)
  minps  xmm3, xmm6; // filt_l2a = min(l2, plus_inf)
  maxps  xmm0, xmm7; // filt_l1b = max(l1, minus_inf)
  maxps  xmm1, xmm7; // filt_l2b = max(l2, minus_inf)

  maxps  xmm2, xmm3; // lmax = max(filt_l1a, filt_l2a)
  minps  xmm0, xmm1; // lmin = min(filt_l1a, filt_l2a)
  // free xmm1, xmm3, xmm4 - xmm7

  movaps xmm3, xmm2; // copy lmax
  movaps xmm1, xmm0; // copy lmin
  shufps xmm3, xmm3, 00111001b; // lmax0 = rotate lmax
  shufps xmm1, xmm1, 00111001b; // lmin0 = rotate lmin
  minss  xmm2, xmm3; // lmax = min(lmax, lmax0)
  maxss  xmm0, xmm1; // lmin = max(lmin, lmin0)

  movaps xmm4, xmm2;  // copy lmax
  movaps xmm5, xmm0;  // copy lmin
  movhlps xmm4, xmm4; // lmax1
  movhlps xmm5, xmm5; // lmin1
  minss  xmm2, xmm4;  // lmax = min(lmax, lmax1)
  maxss  xmm0, xmm5;  // lmin = max(lmin, lmin1)

  movss dword ptr [MinDist], xmm0; // MinDist <- lmin
  movss [ebp + $08], xmm2;         // MaxDist <- lmax

  xor    al, al;      // set Result to False
  xorps  xmm6, xmm6;  // make zero
  comiss xmm2, xmm6;
  jbe    @return;
  comiss xmm2, xmm0;
  jbe    @return;
  or     al,  $01
@return:
end;

function TAABB.HitUnsafe(const ARay: TRay; var MinDist, MaxDist: Single): Boolean;
var
  cMin, cMax: Single;
begin
  // X
  cMin := ARay.InvDirection.X * (FMin.X - ARay.Origin.X);
  cMax := ARay.InvDirection.X * (FMax.X - ARay.Origin.X);

  MinDist := Max(MinDist, Min(Min(cMin, cMax), MaxDist));
  MaxDist := Min(MaxDist, Max(Max(cMin, cMax), MinDist));

  // Y
  cMin := ARay.InvDirection.Y * (FMin.Y - ARay.Origin.Y);
  cMax := ARay.InvDirection.Y * (FMax.Y - ARay.Origin.Y);

  MinDist := Max(MinDist, Min(Min(cMin, cMax), MaxDist));
  MaxDist := Min(MaxDist, Max(Max(cMin, cMax), MinDist));

  // Z
  cMin := ARay.InvDirection.Z * (FMin.Z - ARay.Origin.Z);
  cMax := ARay.InvDirection.Z * (FMax.Z - ARay.Origin.Z);

  MinDist := Max(MinDist, Min(Min(cMin, cMax), MaxDist));
  MaxDist := Min(MaxDist, Max(Max(cMin, cMax), MinDist));

  Result := (MaxDist > MinDist) and (MaxDist > 0);
end;

initialization
  VecInf := Vec3F(Infinity, Infinity, Infinity);
  VecNegInf := Vec3F(NegInfinity, NegInfinity, NegInfinity);
end.
