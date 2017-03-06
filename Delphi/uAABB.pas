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

    function Hit(const ARay: TRay; AMinDist, AMaxDist: Single): Boolean;

    property Min: TVec3F read FMin;
    property Max: TVec3F read FMax;
  end;

implementation

uses
  uMathUtils;

{ TAABB }
constructor TAABB.Create(const A, B: TVec3F);
begin
  FMin := A;
  FMax := B;
end;

procedure TAABB.ExpandWith(const Point: TVec3F);
begin
  FMin := FMin.Min(Point);
  FMax := FMax.Max(Point);
end;

procedure TAABB.ExpandWith(const Other: TAABB);
begin
  FMin := FMin.Min(Other.Min);
  FMax := FMax.Max(Other.Max);
end;

function TAABB.Hit(const ARay: TRay; AMinDist, AMaxDist: Single): Boolean;
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
end;

end.
