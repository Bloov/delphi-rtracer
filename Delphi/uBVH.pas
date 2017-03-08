unit uBVH;

interface

uses
  uRay, uAABB, uHitable;

type
  TBVHNode = class(THitable)
  private
    FBBox: TAABB;
    //FLeft, FRight: THitable;
    FLeft, FRight: TBVHNode;
    FLeaf: THitable;
  public
    constructor Create(var AList: array of THitable; AFrom, ATo: Integer; ATime0, ATime1: Single);
    destructor Destroy; override;

    function Hit(const ARay: TRay; AMinDist, AMaxDist: Single; var Hit: TRayHit): Boolean; override;
    function BoundingBox(ATime0, ATime1: Single; out BBox: TAABB): Boolean; override;

    {property Left: THitable read FLeft;
    property Right: THitable read FRight;}
    property Left: TBVHNode read FLeft;
    property Right: TBVHNode read FRight;
    property Leaf: THitable read FLeaf;
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

{var
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
  FBBox.ExpandWith(BoxRight);}

var
  Axis: Integer;
  Count: Integer;
  BoxL, BoxR: TAABB;
begin
  Count := ATo - AFrom + 1;
  if Count = 1 then
  begin
    FLeaf := AList[AFrom];
  end
  else if Count = 2 then
  begin
    FLeft := TBVHNode.Create(AList, AFrom, AFrom, ATime0, ATime1);
    FRight := TBVHNode.Create(AList, ATo, ATo, ATime0, ATime1);
  end
  else
  begin
    Axis := Random(3);
    if Axis = 0 then
      HeapSort(AList, AFrom, ATo, ATime0, ATime1, @CompareX)
    else if Axis = 1 then
      HeapSort(AList, AFrom, ATo, ATime0, ATime1, @CompareY)
    else
      HeapSort(AList, AFrom, ATo, ATime0, ATime1, @CompareZ);

    FLeft := TBVHNode.Create(AList, AFrom, AFrom + Count div 2 - 1, ATime0, ATime1);
    FRight := TBVHNode.Create(AList, AFrom + Count div 2, ATo, ATime0, ATime1);
  end;

  if ((Left <> nil) and Left.BoundingBox(ATime0, ATime1, BoxL) and Right.BoundingBox(ATime0, ATime1, BoxR))
    or ((Leaf <> nil) and Leaf.BoundingBox(ATime0, ATime1, BoxL))
  then
  begin
    FBBox := BoxL;
    if Right <> nil then
      FBBox.ExpandWith(BoxR);
  end
  else
    raise Exception.Create('BVH fail');
end;

destructor TBVHNode.Destroy;
begin
  if FLeft is TBVHNode then
    FreeAndNil(FLeft);
  if FRight is TBVHNode then
    FreeAndNil(FRight);
  inherited;
end;

{function TBVHNode.Hit(const ARay: TRay; AMinDist, AMaxDist: Single; var Hit: TRayHit): Boolean;
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
end;}

function TBVHNode.Hit(const ARay: TRay; AMinDist, AMaxDist: Single; var Hit: TRayHit): Boolean;

  procedure Swap(var A, B: TBVHNode); inline;
  var
    Tmp: TBVHNode;
  begin
    Tmp := A;
    A := B;
    B := Tmp;
  end;

var
  NMin, NMax, FMin, FMax: Single;
  IsHitNear, IsHitFar: Boolean;
  NearNode, FarNode: TBVHNode;
  NearHit, FarHit: TRayHit;
begin
  if Leaf <> nil then
    Result := Leaf.Hit(ARay, AMinDist, AMaxDist, Hit)
  else
  begin
    NMin := AMinDist;
    FMin := AMinDist;
    NMax := AMaxDist;
    FMax := AMaxDist;
    NearNode := Left;
    FarNode := Right;

    IsHitNear := NearNode.FBBox.Hit(ARay, NMin, NMax);
    IsHitFar := FarNode.FBBox.Hit(ARay, FMin, FMax);
    if (IsHitNear and IsHitFar) and (FMin < NMin) then
    begin
      uMathUtils.Swap(NMin, FMin);
      Swap(NearNode, FarNode);
    end;

    IsHitNear := IsHitNear and NearNode.Hit(ARay, AMinDist, AMaxDist, NearHit);
    if IsHitNear then
      AMaxDist := NearHit.Distance;

    IsHitFar := IsHitFar and (AMaxDist > FMin);
    IsHitFar := IsHitFar and FarNode.Hit(ARay, AMinDist, AMaxDist, FarHit);

    if IsHitNear and IsHitFar then
    begin
      if NearHit.Distance < FarHit.Distance then
        Hit := NearHit
      else
        Hit := FarHit;
    end
    else if IsHitNear then
      Hit := NearHit
    else if IsHitFar then
      Hit := FarHit;

    Result := IsHitNear or IsHitFar;
  end;
end;

function TBVHNode.BoundingBox(ATime0, ATime1: Single; out BBox: TAABB): Boolean;
begin
  BBox := FBBox;
  Result := True;
end;

end.
