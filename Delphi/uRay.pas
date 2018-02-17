unit uRay;

interface

uses
  uVectors;

type
  TRay = packed record
  public
    Origin: TVec3F;
    // Do not set explicitly, use property!
    FDirection: TVec3F;
    FInvDirection: TVec3F;
    Time: Single;

    constructor Create(const AOrigin, ADirection: TVec3F; ATime: Single = 0);
    procedure Assign(const ARay: TRay);
    procedure AssignWithTime(const ARay: TRay);

    function At(ADistance: Single): TVec3F; inline;
    procedure SetDirection(const Value: TVec3F);

    property Direction: TVec3F read FDirection write SetDirection;
    property InvDirection: TVec3F read FInvDirection;
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

procedure TRay.Assign(const ARay: TRay);
begin
  Origin := ARay.Origin;
  FDirection := ARay.FDirection;
  FInvDirection := ARay.FInvDirection;
end;

procedure TRay.AssignWithTime(const ARay: TRay);
begin
  Origin := ARay.Origin;
  FDirection := ARay.FDirection;
  FInvDirection := ARay.FInvDirection;
  Time := ARay.Time;
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
