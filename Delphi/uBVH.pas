unit uBVH;

interface

uses
  uRay, uAABB, uHitable;

type
  TBVHNode = class(THitable)
  private
    FBBox: TAABB;
    FLeft, FRight: THitable;
  public
    constructor Create(var AList: array of THitable; AFrom, ATo: Integer; ATime0, ATime1: Single);
    destructor Destroy; override;

    function Hit(const ARay: TRay; AMinDist, AMaxDist: Single; var Hit: TRayHit): Boolean; override;
    function BoundingBox(ATime0, ATime1: Single; out BBox: TAABB): Boolean; override;

    property Left: THitable read FLeft;
    property Right: THitable read FRight;
  end;

implementation

uses
  SysUtils, uMathUtils;

type
  TCompareFunc = function(A, B: THitable; ATime0, ATime1: Single): Integer;

procedure HeapSort(var AList: array of THitable; AFrom, ATo: Integer;
  ATime0, ATime1: Single; OnCompare: TCompareFunc);

  procedure Heapify(Idx, Len: Integer);
  var
    Left, Right, MaxChild: Integer;
    Tmp: THitable;
  begin
    Left := 2 * Idx + 1;
    Right := Left + 1;
    MaxChild := Left;
    while MaxChild < Len do
    begin
      if (Right < Len) and (OnCompare(AList[AFrom + Left], AList[AFrom + Right], ATime0, ATime1) < 0) then
        MaxChild := Right;

      if OnCompare(AList[AFrom + MaxChild], AList[AFrom + Idx], ATime0, ATime1) > 0 then
      begin
        Tmp := AList[AFrom + Idx];
        AList[AFrom + Idx] := AList[AFrom + MaxChild];
        AList[AFrom + MaxChild] := Tmp;
      end;

      Idx := MaxChild;
      Left := 2 * Idx + 1;
      Right := Left + 1;
      MaxChild := Left;
    end;
  end;

var
  I, Len: Integer;
  Tmp: THitable;
begin
  Len := ATo -  AFrom + 1;
  if Len <= 1 then
    Exit;

  for I := Len div 2 - 1 downto 0 do
    Heapify(I, Len);

  for I := Len - 1 downto 1 do
  begin
    Tmp := AList[AFrom];
    AList[AFrom] := AList[AFrom + I];
    AList[AFrom + I] := Tmp;
    Heapify(0, I);
  end;
end;

{ TBVHNode }
constructor TBVHNode.Create(var AList: array of THitable; AFrom, ATo: Integer; ATime0, ATime1: Single);

  function CompareX(A, B: THitable; ATime0, ATime1: Single): Integer;
  var
    BoxLeft, BoxRight: TAABB;
  begin
    if not A.BoundingBox(ATime0, ATime1, BoxLeft) or not B.BoundingBox(ATime0, ATime1, BoxRight) then
      Result := 0
    else
      Result := Sign(BoxLeft.Min_.X - BoxRight.Min_.X);
  end;

  function CompareY(A, B: THitable; ATime0, ATime1: Single): Integer;
  var
    BoxLeft, BoxRight: TAABB;
  begin
    if not A.BoundingBox(ATime0, ATime1, BoxLeft) or not B.BoundingBox(ATime0, ATime1, BoxRight) then
      Result := 0
    else
      Result := Sign(BoxLeft.Min_.Y - BoxRight.Min_.Y);
  end;

  function CompareZ(A, B: THitable; ATime0, ATime1: Single): Integer;
  var
    BoxLeft, BoxRight: TAABB;
  begin
    if not A.BoundingBox(ATime0, ATime1, BoxLeft) or not B.BoundingBox(ATime0, ATime1, BoxRight) then
      Result := 0
    else
      Result := Sign(BoxLeft.Min_.Z - BoxRight.Min_.Z);
  end;

var
  Axis: Integer;
  Count: Integer;
  BoxLeft, BoxRight: TAABB;
begin
  Axis := Random(3);
  if Axis = 0 then
    HeapSort(AList, AFrom, ATo, ATime0, ATime1, @CompareX)
  else if Axis = 1 then
    HeapSort(AList, AFrom, ATo, ATime0, ATime1, @CompareY)
  else
    HeapSort(AList, AFrom, ATo, ATime0, ATime1, @CompareZ);

  Count := ATo - AFrom + 1;
  if Count < 3 then
  begin
    FLeft := AList[AFrom];
    FRight := AList[ATo];
  end
  else
  begin
    FLeft := TBVHNode.Create(AList, AFrom, AFrom + Count div 2, ATime0, ATime1);
    FRight := TBVHNode.Create(AList, AFrom + Count div 2 + 1, ATo, ATime0, ATime1);
  end;

  if not Left.BoundingBox(ATime0, ATime1, BoxLeft)
    or not Right.BoundingBox(ATime0, ATime1, BoxRight)
  then
    raise Exception.Create('BVH fail');

  FBBox := BoxLeft;
  FBBox.ExpandWith(BoxRight);
end;

destructor TBVHNode.Destroy;
begin
  if FLeft is TBVHNode then
    FreeAndNil(FLeft);
  if FRight is TBVHNode then
    FreeAndNil(FRight);
  inherited;
end;

function TBVHNode.Hit(const ARay: TRay; AMinDist, AMaxDist: Single; var Hit: TRayHit): Boolean;
var
  IsHitLeft, IsHitRight: Boolean;
  LeftHit, RightHit: TRayHit;
begin
  if FBBox.Hit(ARay, AMinDist, AMaxDist) then
  begin
    IsHitLeft := FLeft.Hit(ARay, AMinDist, AMaxDist, LeftHit);
    IsHitRight := FRight.Hit(ARay, AMinDist, AMaxDist, RightHit);
    if IsHitLeft and IsHitRight then
    begin
      if LeftHit.Distance < RightHit.Distance then
        Hit := LeftHit
      else
        Hit := RightHit;
    end
    else if IsHitLeft then
      Hit := LeftHit
    else if IsHitRight then
      Hit := RightHit;

    Result := IsHitLeft or IsHitRight;
  end
  else
    Result := False;
end;

function TBVHNode.BoundingBox(ATime0, ATime1: Single; out BBox: TAABB): Boolean;
begin
  BBox := FBBox;
  Result := True;
end;

end.
