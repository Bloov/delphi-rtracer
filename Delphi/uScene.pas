unit uScene;

interface

uses
  uRay, uHitable;

type
  TScene = class
  private
    FCount, FCapacity: Integer;
    FItems: array of THitable;

    function GetItem(Index: Integer): THitable;
    function ValidIndex(Index: Integer): Boolean;

    procedure EnsureCapacityEnough;
  public
    constructor Create;
    destructor Destroy; override;

    function Add(AObject: THitable): Integer;
    procedure Delete(Index: Integer);

    function Hit(const ARay: TRay; var Hit: TRayHit): Boolean;

    property Items[Index: Integer]: THitable read GetItem;
    property Count: Integer read FCount;
  end;

implementation

uses
  SysUtils;

{ TScene }
constructor TScene.Create;
begin
  FCount := 0;
  FCapacity := 10;
  SetLength(FItems, FCapacity);
end;

destructor TScene.Destroy;
var
  I: Integer;
begin
  for I := 0 to FCount - 1 do
    FreeAndNil(FItems[I]);
  inherited;
end;

function TScene.GetItem(Index: Integer): THitable;
begin
  if ValidIndex(Index) then
    Result := FItems[Index]
  else
    Result := nil;
end;

function TScene.ValidIndex(Index: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index < FCount);
end;

procedure TScene.EnsureCapacityEnough;
begin
  if FCount < FCapacity then
    Exit;

  FCapacity := (FCapacity * 3) div 2;
  SetLength(FItems, FCapacity);
end;

function TScene.Add(AObject: THitable): Integer;
begin
  Result := -1;
  if AObject = nil then
    Exit;

  EnsureCapacityEnough;
  FItems[FCount] := AObject;
  Result := FCount;
  Inc(FCount);
end;

procedure TScene.Delete(Index: Integer);
var
  I: Integer;
begin
  if not ValidIndex(Index) then
    Exit;

  FreeAndNil(FItems[Index]);
  for I := Index + 1 to FCount - 1 do
    FItems[I - 1] := FItems[I];
  Dec(FCount);
end;

function TScene.Hit(const ARay: TRay; var Hit: TRayHit): Boolean;
var
  I: Integer;
  TmpHit: TRayHit;
  Closest: Double;
begin
  Result := False;
  for I := 0 to Count - 1 do
    if FItems[I].Hit(ARay, TmpHit) then
    begin
      if not Result or (TmpHit.T < Closest) then
        Hit := TmpHit;

      Closest := Hit.T;
      Result := True;
    end;
end;

end.
