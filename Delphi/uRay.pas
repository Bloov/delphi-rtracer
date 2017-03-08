unit uRay;

interface

uses
  uVectors;

type
  TRay = packed record
  private
    FOrigin: TVec3F;
    FDirection: TVec3F;
    FInvDirection: TVec3F;
    FTime: Single;

    procedure SetDirection(const Value: TVec3F);
  public
    constructor Create(const AOrigin, ADirection: TVec3F; ATime: Single = 0);

    function At(ADistance: Single): TVec3F; inline;

    property Origin: TVec3F read FOrigin write FOrigin;
    property Direction: TVec3F read FDirection write SetDirection;
    property InvDirection: TVec3F read FInvDirection;
    property Time: Single read FTime write FTime;
  end;

implementation

uses
  Math;

{ TRay }
constructor TRay.Create(const AOrigin, ADirection: TVec3F; ATime: Single = 0);
begin
  Time := ATime;
  Origin := AOrigin;
  Direction := ADirection;
end;

procedure TRay.SetDirection(const Value: TVec3F);
var
  I: Integer;
  V: Single;
begin
  if not Value.IsZero then
    FDirection := Value.Normalize
  else
    FDirection := Value;

  for I := 0 to 2 do
  begin
    V := FDirection.Arr[I];
    if V <> 0 then
      FInvDirection.Arr[I] := 1 / V
    else
      FInvDirection.Arr[I] := IfThen(V = 0.0, Infinity, NegInfinity);
  end;
end;

function TRay.At(ADistance: Single): TVec3F;
begin
  Result := Origin + Direction * ADistance;
end;

end.
