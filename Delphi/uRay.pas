unit uRay;

interface

uses
  uVectors;

type
  TRay = packed record
  public
    Origin: TVec3F;
    Direction: TVec3F;

    constructor Create(const AOrigin, ADirection: TVec3F);

    function At(ADistance: Single): TVec3F; inline;
  end;

implementation

{ TRay }
constructor TRay.Create(const AOrigin, ADirection: TVec3F);
begin
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
