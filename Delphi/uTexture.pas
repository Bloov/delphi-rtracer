unit uTexture;

interface

uses
  uVectors, uColor;

type
  TTexture = class
  public
    function Value(U, V: Single; var Point: TVec3F): TColorVec; virtual; abstract;
  end;

  TConstantTexture = class(TTexture)
  private
    FColor: TColorVec;
  public
    constructor Create(const AColor: TColorVec);

    function Value(U, V: Single; var Point: TVec3F): TColorVec; override;

    property Color: TColorVec read FColor;
  end;

  TCheckerTexture = class(TTexture)
  private
    FOwnTexture: Boolean;
    FOdd, FEven: TTexture;
  public
    constructor Create(AOdd, AEven: TTexture; OwnTexture: Boolean = True);
    destructor Destroy; override;

    function Value(U, V: Single; var Point: TVec3F): TColorVec; override;

    property Odd: TTexture read FOdd;
    property Even: TTexture read FEven;
  end;

implementation

uses
  SysUtils;

{ TConstantTexture }
constructor TConstantTexture.Create(const AColor: TColorVec);
begin
  FColor := AColor;
end;

function TConstantTexture.Value(U, V: Single; var Point: TVec3F): TColorVec;
begin
  Result := FColor;
end;

{ TCheckerTexture }
constructor TCheckerTexture.Create(AOdd, AEven: TTexture; OwnTexture: Boolean = True);
begin
  FOwnTexture := OwnTexture;
  FOdd := AOdd;
  FEven := AEven;
end;

destructor TCheckerTexture.Destroy;
begin
  if FOwnTexture then
  begin
    FreeAndNil(FOdd);
    FreeAndNil(FEven);
  end;
  inherited;
end;

function TCheckerTexture.Value(U, V: Single; var Point: TVec3F): TColorVec;
var
  Sines: Single;
begin
  Sines := Sin(10 * Point.X) * Sin(10 * Point.Y) * Sin(10 * Point.Z);
  if Sines < 0 then
    Result := Odd.Value(U, V, Point)
  else
    Result := Even.Value(U, V, Point);
end;

end.
