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

    property Min_: TVec3F read FMin;
    property Max_: TVec3F read FMax;
  end;

implementation

uses
  Math, uMathUtils;

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

function TAABB.Hit(const ARay: TRay; var MinDist, MaxDist: Single): Boolean;
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

{function TAABB.Hit(const ARay: TRay; AMinDist, AMaxDist: Single): Boolean;
var
  I: Integer;
  invD: Single;
  cMin, cMax: Single;
  tMin, tMax: Single;
begin
  tMin := AMinDist;
  tMax := AMaxDist;
  for I := 0 to 2 do
  begin
    if ARay.Direction.Arr[I] = 0 then
      Continue;

    invD := 1 / ARay.Direction.Arr[I];
    cMin := invD * (Min.Arr[I] - ARay.Origin.Arr[I]);
    cMax := invD * (Max.Arr[I] - ARay.Origin.Arr[I]);
    if invD < 0 then
      Swap(cMin, cMax);

    tMin := uMathUtils.Max(cMin, tMin);
    tMax := uMathUtils.Min(cMax, tMax);
    if tMax <= tMin then
      Exit(False);
  end;
  Result := (tMax > 0);
end;}

end.
