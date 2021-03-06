unit uHitable;

{$I defines.inc}

interface

uses
  uVectors, uAABB, uRay, uMaterial;

type
  THitable = class;

  TRayHit = packed record
  public
    Primitive: THitable;
    Distance: Single;
    Time: Single;

    constructor Create(ADistance, ATime: Single; APrimitive: THitable);
  end;

  THitable = class
  private
    FMaterial: TMaterial;
  public
    constructor Create(AMaterial: TMaterial);
    destructor Destroy; override;

    function Hit(const ARay: TRay; AMinDist, AMaxDist: Single; var Hit: TRayHit): Boolean; virtual; abstract;
    function GetNormal(const APoint: TVec3F; ATime: Single = 0): TVec3F; virtual; abstract;
    function BoundingBox(ATime0, ATime1: Single; out BBox: TAABB): Boolean; virtual; abstract;

    property Material: TMaterial read Fmaterial;
  end;

  TSphere = class(THitable)
  private
    FCenter: TVec3F;
    FRadius: Single;
    FNormalSign: Single;

  protected
    function FastDisc(const ARay: TRay; var Dist: Single): Single;
  public
    constructor Create(const ACenter: TVec3F; ARadius: Single; AMaterial: TMaterial);

    function Hit(const ARay: TRay; AMinDist, AMaxDist: Single; var Hit: TRayHit): Boolean; override;
    function GetNormal(const APoint: TVec3F; ATime: Single = 0): TVec3F; override;
    function BoundingBox(ATime0, ATime1: Single; out BBox: TAABB): Boolean; override;

    property Center: TVec3F read FCenter;
    property Radius: Single read FRadius;
  end;

  TMovingSphere = class(THitable)
  private
    FCenter0, FCenter1: TVec3F;
    FTime0, FTime1: Single;
    FRadius: Single;
    FNormalSign: Single;

  protected
    function FastDisc(const ARay: TRay; const ACenter: TVec3F; var Dist: Single): Single;
  public
    constructor Create(const ACenter0, ACenter1: TVec3F; ARadius: Single; ATime0, ATime1: Single; AMaterial: TMaterial);

    function CenterAt(ATime: Single): TVec3F;
    function Hit(const ARay: TRay; AMinDist, AMaxDist: Single; var Hit: TRayHit): Boolean; override;
    function GetNormal(const APoint: TVec3F; ATime: Single = 0): TVec3F; override;
    function BoundingBox(ATime0, ATime1: Single; out BBox: TAABB): Boolean; override;

    property Center0: TVec3F read FCenter0;
    property Center1: TVec3F read FCenter1;
    property Radius: Single read FRadius;
  end;

implementation

uses
  SysUtils, uMathUtils;

{ TRayHit }
constructor TRayHit.Create(ADistance, ATime: Single; APrimitive: THitable);
begin
  Primitive := APrimitive;
  Distance := ADistance;
  Time := ATime;
end;

{ THitable }
constructor THitable.Create(AMaterial: TMaterial);
begin
  FMaterial := AMaterial;
end;

destructor THitable.Destroy;
begin
  FreeAndNil(FMaterial);
  inherited;
end;

{ TSphere }
constructor TSphere.Create(const ACenter: TVec3F; ARadius: Single; AMaterial: TMaterial);
begin
  inherited Create(AMaterial);
  FCenter := ACenter;
  FRadius := Abs(ARadius);
  FNormalSign := Sign(ARadius);
end;

function TSphere.FastDisc(const ARay: TRay; var Dist: Single): Single;
asm
  movups xmm0, dqword ptr [Self + TSphere.FCenter];
  movss  xmm1, dword  ptr [Self + TSphere.FRadius];
  movups xmm2, dqword ptr [ARay + TRay.Origin];
  movups xmm3, dqword ptr [ARay + TRay.FDirection];
  xorps  xmm6, xmm6; // Zero in xmm6

  subps  xmm0, xmm2; // ToSphere = Center - Origin in xmm0

  movaps xmm4, xmm0;
  dpps   xmm4, xmm3, 01110001b; // B = ToSphere * Direction in xmm4

  dpps   xmm0, xmm0, 01110001b;
  mulss  xmm1, xmm1;
  subss  xmm0, xmm1; // C = ToSphere * ToSphere - Radius * Radius in xmm0

  movaps xmm2, xmm4;
  mulss  xmm2, xmm2;
  subss  xmm2, xmm0; // Disc = B * B - C in xmm2


  comiss xmm2, xmm6;
  jb     @return;    // if Disc >= 0 then
  sqrtss xmm2, xmm2; // Disc = Sqrt(Disc)

  movaps xmm1, xmm4;
  subss  xmm1, xmm2; // Dist = B - Disc in xmm1

  comiss xmm6, xmm1;
  jb     @return;    // if Dist < 0 then
  movaps xmm1, xmm4;
  addss  xmm1, xmm2; // Dist = B + Disc in xmm1

@return:
  movss  [Dist],   xmm1;
  movss  [Result], xmm2;
end;

function TSphere.Hit(const ARay: TRay; AMinDist, AMaxDist: Single; var Hit: TRayHit): Boolean;
var
{$IFNDEF USE_SSE}
  ToSphere: TVec3F;
  B: Single;
{$ENDIF}
  Disc, Dist: Single;
begin
{$IFDEF USE_SSE}
  Disc := FastDisc(ARay, Dist);
{$ELSE}
  ToSphere := Center - ARay.Origin;
  B := ToSphere * ARay.Direction;
  Disc := B * B - ToSphere * ToSphere + Radius * Radius;
{$ENDIF}
  if Disc >= 0 then
  begin
  {$IFNDEF USE_SSE}
    Disc := Sqrt(Disc);
    Dist := B - Disc;
    if Dist < 0 then
      Dist := B + Disc;
  {$ENDIF}
    if (AMinDist <= Dist) and (Dist <= AMaxDist) then
    begin
      Result := True;
      Hit.Primitive := Self;
      Hit.Distance := Dist;
      Hit.Time := ARay.Time;
    end
    else
      Result := False;
  end
  else
    Result := False;
end;

function TSphere.GetNormal(const APoint: TVec3F; ATime: Single = 0): TVec3F;
begin
  Result := FNormalSign * (APoint - Center).Normalize;
end;

function TSphere.BoundingBox(ATime0, ATime1: Single; out BBox: TAABB): Boolean;
var
  R: TVec3F;
begin
  R := Vec3F(Radius, Radius, Radius);
  BBox := TAABB.Create(Center - R, Center + R);
  Result := True;
end;

{ TMovingSphere }
constructor TMovingSphere.Create(const ACenter0, ACenter1: TVec3F; ARadius: Single;
  ATime0, ATime1: Single; AMaterial: TMaterial);
begin
  inherited Create(AMaterial);
  FCenter0 := ACenter0;
  FCenter1 := ACenter1;
  FTime0 := ATime0;
  FTime1 := ATime1;
  FRadius := ARadius;
  FNormalSign := Sign(FRadius);
end;

function TMovingSphere.CenterAt(ATime: Single): TVec3F;
begin
  Result := Center0 + ((ATime - FTime0) / (FTime1 - FTime0)) * (Center1 - Center0);
end;

function TMovingSphere.FastDisc(const ARay: TRay; const ACenter: TVec3F; var Dist: Single): Single;
asm
  movups xmm0, [ACenter];
  movss  xmm1, dword  ptr [Self + TMovingSphere.FRadius];
  movups xmm2, dqword ptr [ARay + TRay.Origin];
  movups xmm3, dqword ptr [ARay + TRay.FDirection];
  xorps  xmm6, xmm6; // Zero in xmm6

  subps  xmm0, xmm2; // ToSphere = Center - Origin in xmm0

  movaps xmm4, xmm0;
  dpps   xmm4, xmm3, 01110001b; // B = ToSphere * Direction in xmm4

  dpps   xmm0, xmm0, 01110001b;
  mulss  xmm1, xmm1;
  subss  xmm0, xmm1; // C = ToSphere * ToSphere - Radius * Radius in xmm0

  movaps xmm2, xmm4;
  mulss  xmm2, xmm2;
  subss  xmm2, xmm0; // Disc = B * B - C in xmm1

  comiss xmm2, xmm6;
  jb     @return;    // if Disc >= 0 then
  sqrtss xmm2, xmm2; // Disc = Sqrt(Disc) if Disc > 0

  movaps xmm1, xmm4;
  subss  xmm1, xmm2; // Dist = B - Disc in xmm1

  comiss xmm6, xmm1;
  jb     @return;    // if Dist < 0 then
  movaps xmm1, xmm4;
  addss  xmm1, xmm2; // Dist = B + Disc in xmm1

@return:
  mov    eax, [Dist];
  movss  [eax], xmm1;
  movss  [Result], xmm2;
end;

function TMovingSphere.Hit(const ARay: TRay; AMinDist, AMaxDist: Single; var Hit: TRayHit): Boolean;
var
{$IFNDEF USE_SSE}
  ToSphere: TVec3F;
  B: Single;
{$ENDIF}
  Center: TVec3F;
  Disc, Dist: Single;
begin
  Center := CenterAt(ARay.Time);
{$IFDEF USE_SSE}
  Disc := FastDisc(ARay, Center, Dist);
{$ELSE}
  ToSphere := Center - ARay.Origin;
  B := ToSphere * ARay.Direction;
  Disc := B * B - ToSphere * ToSphere + Radius * Radius;
{$ENDIF}
  if Disc >= 0 then
  begin
  {$IFNDEF USE_SSE}
    Disc := Sqrt(Disc);
    Dist := B - Disc;
    if Dist < 0 then
      Dist := B + Disc;
  {$ENDIF}
    if (AMinDist <= Dist) and (Dist <= AMaxDist) then
    begin
      Result := True;
      Hit.Primitive := Self;
      Hit.Distance := Dist;
      Hit.Time := ARay.Time;
    end
    else
      Result := False;
  end
  else
    Result := False;
end;

function TMovingSphere.GetNormal(const APoint: TVec3F; ATime: Single = 0): TVec3F;
begin
  Result := FNormalSign * (APoint - CenterAt(ATime)).Normalize;
end;

function TMovingSphere.BoundingBox(ATime0, ATime1: Single; out BBox: TAABB): Boolean;
var
  R: TVec3F;
  CenterAt0, CenterAt1: TVec3F;
begin
  R := Vec3F(Radius, Radius, Radius);
  CenterAt0 := CenterAt(ATime0);
  CenterAt1 := CenterAt(ATime1);
  BBox := TAABB.Create(CenterAt0 - R, CenterAt0 + R);
  BBox.ExpandWith(TAABB.Create(CenterAt1 - R, CenterAt1 + R));
  Result := True;
end;

end.
