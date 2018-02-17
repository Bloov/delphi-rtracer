unit uImage2D;

interface

uses
  Vcl.Graphics, uColor;

type
  TImage2D = class (TObject)
  private
    FWidth, FHeight: Integer;
    FData: array of array of Cardinal;

    function ValidPixel(X, Y: Integer): Boolean;

    function GetPixel(X, Y: Integer): Cardinal;
    procedure SetPixel(X, Y: Integer; Value: Cardinal);

  public
    constructor Create(AWidth, AHeight: Integer);
    destructor Destroy; override;

    function GetAsBitmap(): TBitmap;

    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Pixel[X, Y: Integer]: Cardinal read GetPixel write SetPixel; default;
  end;

  TImageBuffer2D = class (TObject)
  private
    FWidth, FHeight: Integer;
    FData: array of TColorVec;
    FCount: array of Integer;

    function GetIndex(X, Y: Integer): Integer;
    function ValidIndex(Idx: Integer): Boolean;

  public
    constructor Create(AWidth, AHeight: Integer);
    destructor Destroy; override;

    function Copy(): TImageBuffer2D;

    function GetAsImage(Gamma: Single): TImage2D;
    function GetAsBitmap(Gamma: Single): TBitmap;

    procedure AddColor(X, Y: Integer; const Color: TColorVec; Count: Integer);
    procedure Clear;

    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
  end;

implementation

uses
  System.UITypes, uMathUtils;

{ TImage2D }
constructor TImage2D.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  FWidth := AWidth;
  FHeight := AHeight;
  SetLength(FData, AWidth, AHeight);
end;

destructor TImage2D.Destroy;
begin
  inherited;
end;

function TImage2D.ValidPixel(X, Y: Integer): Boolean;
begin
  Result := (X >= 0) and (X < FWidth) and (Y >= 0) and (Y < FHeight);
end;

function TImage2D.GetPixel(X, Y: Integer): Cardinal;
begin
  if ValidPixel(X, Y) then
    Result := FData[X, Y]
  else
    Result := 0;
end;

procedure TImage2D.SetPixel(X, Y: Integer; Value: Cardinal);
begin
  if ValidPixel(X, Y) then
    FData[X, Y] := Value;
end;

function TImage2D.GetAsBitmap(): TBitmap;
var
  X, Y: Integer;
  Line: Pointer;
begin
  Result := TBitmap.Create;
  Result.SetSize(Width, Height);
  Result.PixelFormat := pf32bit;
  for Y := 0 to Height - 1 do
  begin
    Line := Result.ScanLine[Y];
    for X := 0 to Width - 1 do
    begin
      PInteger(Line)^ := FData[X, Y];
      Inc(PInteger(Line));
    end;
  end;
end;

{ TImageBuffer2D }
constructor TImageBuffer2D.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  FWidth := AWidth;
  FHeight := AHeight;
  SetLength(FData, Width * Height);
  SetLength(FCount, Width * Height);
end;

destructor TImageBuffer2D.Destroy;
begin
  inherited;
end;

function TImageBuffer2D.GetIndex(X, Y: Integer): Integer;
begin
  Result := Y * Width + X;
end;

function TImageBuffer2D.ValidIndex(Idx: Integer): Boolean;
begin
  Result := (Idx >= 0) and (Idx < Width * Height)
end;

function TImageBuffer2D.Copy(): TImageBuffer2D;
begin
  Result := TImageBuffer2D.Create(Width, Height);
  Move(FData[0], Result.FData[0], Width * Height * SizeOf(TColorVec));
  Move(FCount[0], Result.FCount[0], Width * Height * SizeOf(Integer));
end;

function TImageBuffer2D.GetAsImage(Gamma: Single): TImage2D;
var
  I, X, Y: Integer;
  Color: TColorVec;
begin
  Result := TImage2D.Create(Width, Height);
  for Y := 0 to Height - 1 do
    for X := 0 to Width - 1 do
    begin
      I := GetIndex(X, Y);
      if FCount[I] > 0 then
        Color := FData[I] / FCount[I]
      else
        Color.Create(0, 0, 0);

      Result.Pixel[X, Y] := GammaCorrection(Color, Gamma).GetFlat;
    end;
end;

function TImageBuffer2D.GetAsBitmap(Gamma: Single): TBitmap;
var
  I, X, Y: Integer;
  Color: TColorVec;
  Line: Pointer;
begin
  Result := TBitmap.Create;
  Result.SetSize(Width, Height);
  Result.PixelFormat := pf32bit;
  for Y := 0 to Height - 1 do
  begin
    Line := Result.ScanLine[Y];
    for X := 0 to Width - 1 do
    begin
      I := GetIndex(X, Y);
      if FCount[I] > 0 then
        Color := FData[I] / FCount[I]
      else
        Color.Create(0, 0, 0);

      PInteger(Line)^ := GammaCorrection(Color, Gamma).GetFlat;
      Inc(PInteger(Line));
    end;
  end;
end;

procedure TImageBuffer2D.AddColor(X, Y: Integer; const Color: TColorVec; Count: Integer);
var
  Idx: Integer;
begin
  Idx := GetIndex(X, Y);
  if ValidIndex(Idx) then
  begin
    FData[Idx] := FData[Idx] + Color;
    FCount[Idx] := FCount[Idx] + Count;
  end;
end;

procedure TImageBuffer2D.Clear;
begin
  FillChar(FData, Length(FData) * SizeOf(TColorVec), 0);
  FillChar(FCount, Length(FCount) * SizeOf(Integer), 0);
end;

end.
