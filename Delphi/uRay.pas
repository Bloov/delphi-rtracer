unit uRay;

interface

uses
  uVectors;

type
  TRay = packed record
  public
    Origin: TVec3F;
    Direction: TVec3F;
    Time: Single;

    constructor Create(const AOrigin, ADirection: TVec3F; ATime: Single = 0);

    function At(ADistance: Single): TVec3F; inline;
  end;

implementation

{ TRay }
constructor TRay.Create(const AOrigin, ADirection: TVec3F; ATime: Single = 0);
begin
  Time := ATime;
  Origin := AOrigin;
  if not ADirection.IsZero then
    Direction := ADirection.Normalize
  else
    Direction := ADirection;
end;

function TRay.At(ADistance: Single): TVec3F;
begin
  Result := Origin + Direction * ADistance;
end;

end.
