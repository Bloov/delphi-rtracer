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

function TAABB.Hit(const ARay: TRay; AMinDist, AMaxDist: Single): Boolean;
var
  invRayDir: TVec3F;
  Lo, Hi: TVec3F;
  Near, Far: Single;
begin
  invRayDir := 1 / ARay.Direction;
  Lo := invRayDir.CMul(Min - ARay.Origin);
  Hi := invRayDir.CMul(Max - ARay.Origin);

  Near := uMathUtils.Min(Lo.X, Hi.X);
  Far := uMathUtils.Max(Lo.X, Hi.X);

  Near := uMathUtils.Max(Near, uMathUtils.Min(Lo.Y, Hi.Y));
  Far := uMathUtils.Min(Far, uMathUtils.Max(Lo.Y, Hi.Y));

  Near := uMathUtils.Max(Near, uMathUtils.Min(Lo.Z, Hi.Z));
  Far := uMathUtils.Min(Far, uMathUtils.Max(Lo.Z, Hi.Z));

  Result := (Near <= Far) and (Far > 0);
end;

end.
