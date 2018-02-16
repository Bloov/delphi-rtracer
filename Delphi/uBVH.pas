unit uBVH;

interface

uses
  uVectors, uRay, uAABB, uHitable;

type
  TBVHNode = class(THitable)
  private
    FBBox: TAABB;
    FLeft, FRight: TBVHNode;
    FLeaf: THitable;
  public
    constructor Create(var AList: array of THitable; AFrom, ATo: Integer; ATime0, ATime1: Single);
    destructor Destroy; override;

    function Hit(const ARay: TRay; AMinDist, AMaxDist: Single; var Hit: TRayHit): Boolean; override;
    function GetNormal(const APoint: TVec3F; ATime: Single = 0): TVec3F; override;
    function BoundingBox(ATime0, ATime1: Single; out BBox: TAABB): Boolean; override;

    property Left: TBVHNode read FLeft;
    property Right: TBVHNode read FRight;
    property Leaf: THitable read FLeaf;
  end;

implementation

uses
  SysUtils, Math, uMathUtils;

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

function TBVHNode.Hit(const ARay: TRay; AMinDist, AMaxDist: Single; var Hit: TRayHit): Boolean;

{$DEFINE Swap}
  procedure Swap(var A, B: TVec2F); overload; inline;
  var
    Tmp: TVec2F;
  {$I uMathUtils.inc}

  procedure Swap(var A, B: TBVHNode); overload; inline;
  var
    Tmp: TBVHNode;
  {$I uMathUtils.inc}
{$UNDEF Swap}

var
  NearDist, FarDist: TVec2F;
  NearNode, FarNode: TBVHNode;
  IsHitNear, IsHitFar: Boolean;
  NearHit, FarHit: TRayHit;
begin
  if Leaf <> nil then
    Result := Leaf.Hit(ARay, AMinDist, AMaxDist, Hit)
  else
  begin
    NearNode := Left;
    NearDist := Vec2F(AMinDist, AMaxDist);
    FarNode := Right;
    FarDist := Vec2F(AMinDist, AMaxDist);

    IsHitNear := NearNode.FBBox.Hit(ARay, NearDist.X, NearDist.Y);
    IsHitFar := FarNode.FBBox.Hit(ARay, FarDist.X, FarDist.Y);
    if (IsHitNear and IsHitFar) then
    begin
      if FarDist.X < NearDist.X then
      begin
        Swap(NearDist, FarDist);
        Swap(NearNode, FarNode);
      end;

      IsHitNear := NearNode.Hit(ARay, AMinDist, AMaxDist, NearHit);
      if IsHitNear then
        AMaxDist := NearHit.Distance;

      IsHitFar := FarNode.Hit(ARay, AMinDist, AMaxDist, FarHit);
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
    end
    else if IsHitNear then
      IsHitNear := NearNode.Hit(ARay, AMinDist, AMaxDist, Hit)
    else if IsHitFar then
      IsHitFar := FarNode.Hit(ARay, AMinDist, AMaxDist, Hit);

    Result := IsHitNear or IsHitFar;
  end;
end;

function TBVHNode.GetNormal(const APoint: TVec3F; ATime: Single = 0): TVec3F;
begin
  Result := Vec3F(0, 0, 0);
end;

function TBVHNode.BoundingBox(ATime0, ATime1: Single; out BBox: TAABB): Boolean;
begin
  BBox := FBBox;
  Result := True;
end;

end.
