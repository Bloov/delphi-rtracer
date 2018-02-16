unit uAABB;

{$I defines.inc}

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

    property Min_: TVec3F read FMin;
    property Max_: TVec3F read FMax;
  end;

implementation

uses
  Math, uMathUtils;

var
  Spacer0: Integer;
  //Spacer1: Integer;
  //Spacer2: Integer;
  // Apply spacers for adjust Vectors align by 16 byte
  VecInf: TVec3F;
  VecNegInf: TVec3F;

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

// From here
// http://www.flipcode.com/archives/SSE_RayBox_Intersection_Test.shtml
function TAABB.Hit(const ARay: TRay; var MinDist, MaxDist: Single): Boolean;
{$IFDEF USE_SSE}
asm
  movups xmm0, dqword ptr [Self + TAABB.FMin];
  movups xmm1, dqword ptr [Self + TAABB.FMax];
  movups xmm2, dqword ptr [ARay + TRay.Origin];
  movups xmm3, dqword ptr [ARay + TRay.FInvDirection];
  movups xmm6, [VecInf];
  movups xmm7, [VecNegInf];

  subps  xmm0, xmm2;
  subps  xmm1, xmm2;
  mulps  xmm0, xmm3;            // l1 = (min - pos) * inv_dir
  mulps  xmm1, xmm3;            // l2 = (max - pos) * inv_dir

  movaps xmm2, xmm0;
  movaps xmm3, xmm1;
  minps  xmm2, xmm6;            // filt_l1a = min(l1, plus_inf)
  minps  xmm3, xmm6;            // filt_l2a = min(l2, plus_inf)
  maxps  xmm0, xmm7;            // filt_l1b = max(l1, minus_inf)
  maxps  xmm1, xmm7;            // filt_l2b = max(l2, minus_inf)

  maxps  xmm2, xmm3;            // lmax = max(filt_l1a, filt_l2a)
  minps  xmm0, xmm1;            // lmin = min(filt_l1a, filt_l2a)

  movaps xmm3, xmm2;
  movaps xmm1, xmm0;
  shufps xmm3, xmm3, 00111001b; // lmax0 = rotate lmax
  shufps xmm1, xmm1, 00111001b; // lmin0 = rotate lmin
  minss  xmm2, xmm3;            // lmax = min(lmax, lmax0)
  maxss  xmm0, xmm1;            // lmin = max(lmin, lmin0)

  movaps xmm4, xmm2;
  movaps xmm5, xmm0;
  movhlps xmm4, xmm4;           // lmax1
  movhlps xmm5, xmm5;           // lmin1
  minss  xmm2, xmm4;            // lmax = min(lmax, lmax1)
  maxss  xmm0, xmm5;            // lmin = max(lmin, lmin1)

  // MinDist <- lmin
  movss [MinDist], xmm0;
  // MaxDist <- lmax
  mov   eax, [MaxDist];
  movss [eax], xmm2;

  xor    al, al;      // set Result to False
  xorps  xmm6, xmm6;
  comiss xmm2, xmm6;
  jbe    @return;
  comiss xmm2, xmm0;
  jbe    @return;
  or     al,  $01
@return:
{$ELSE}
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
      // Some optimization here
      // Be aware, results may differ from HitAsm
      if MaxDist <= MinDist then
        Exit(False);
    end
    else if (ARay.Origin.Arr[I] <= FMin.Arr[I]) or (ARay.Origin.Arr[I] >= FMax.Arr[I]) then
      Exit(False);

  // Uncomment here if turn off optimization above
  Result := {(MaxDist > MinDist) and} (MaxDist > 0);
{$ENDIF}
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
      // Some optimization here
      // Be aware, results may differ from HitAsm
      if MaxDist <= MinDist then
        Exit(False);
    end
    else if (ARay.Origin.Arr[I] <= FMin.Arr[I]) or (ARay.Origin.Arr[I] >= FMax.Arr[I]) then
      Exit(False);

  // Uncomment here if turn off optimization above
  Result := {(MaxDist > MinDist) and} (MaxDist > 0);
end;

initialization
  Spacer0 := 0;
  //Spacer1 := 0;
  //Spacer2 := 0;
  VecInf := Vec3F(Infinity, Infinity, Infinity);
  VecNegInf := Vec3F(NegInfinity, NegInfinity, NegInfinity);
end.
