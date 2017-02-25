unit uImage2D;

interface

uses
  Vcl.Graphics;

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

end.
