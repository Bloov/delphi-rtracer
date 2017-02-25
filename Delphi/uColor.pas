unit uColor;

interface

type
  TColorVec = packed record
    constructor Create(Red, Green, Blue: Single); overload;
    constructor Create(Red, Green, Blue: Integer); overload;

    {class operator Negative(const Vec: TVec3F): TVec3F; inline;
    class operator Positive(const Vec: TVec3F): TVec3F; inline;
    class operator Equal(const A, B: TVec3F): Boolean; inline;
    class operator NotEqual(const A, B: TVec3F): Boolean; inline;}
    class operator Add(const C1, C2: TColorVec): TColorVec; inline;
    {class operator Subtract(const A, B: TVec3F): TVec3F; inline;}
    class operator Multiply(const C: TColorVec; F: Single): TColorVec; overload; inline;
    class operator Multiply(F: Single; const C: TColorVec): TColorVec; overload; inline;
    class operator Multiply(const C1, C2: TColorVec): TColorVec; overload; inline;
    class operator Divide(const C: TColorVec; B: Single): TColorVec; overload; inline;
    class operator Divide(A: Single; const C: TColorVec): TColorVec; overload; inline;
    class operator Divide(const C1, C2: TColorVec): TColorVec; overload; inline;

    function GetFlat(): Cardinal;

    case Boolean of
      True: (Arr: array [0..2] of Single);
      False: (R, G, B: Single);
  end;

{ Flat color }
function GetColorFromRGB(R, G, B: Integer): Cardinal;
procedure GetRGBFromColor(AColor: Cardinal; out R, G, B: Integer);

implementation

uses
  uMathUtils;

{ Flat color }
function GetColorFromRGB(R, G, B: Integer): Cardinal;
begin
  R := Clamp(R, 0, 255);
  G := Clamp(G, 0, 255);
  B := Clamp(B, 0, 255);
  Result := R shl 16 + G shl 8 + B;
end;

procedure GetRGBFromColor(AColor: Cardinal; out R, G, B: Integer);
begin
  B := AColor and $FF;
  G := (AColor shr 8) and $FF;
  R := (AColor shr 16) and $FF;
end;

{ TColorVec }
constructor TColorVec.Create(Red, Green, Blue: Single);
begin
  R := Red;
  G := Green;
  B := Blue;
end;

constructor TColorVec.Create(Red, Green, Blue: Integer);
var
  Norm: Single;
begin
  Norm := 1 / 255;
  R := Red * Norm;
  G := Green * Norm;
  B := Blue * Norm;
end;

class operator TColorVec.Add(const C1, C2: TColorVec): TColorVec;
begin
  Result.R := C1.R + C2.R;
  Result.G := C1.G + C2.G;
  Result.B := C1.B + C2.B;
end;

class operator TColorVec.Multiply(const C: TColorVec; F: Single): TColorVec;
begin
  Result.R := C.R * F;
  Result.G := C.G * F;
  Result.B := C.B * F;
end;

class operator TColorVec.Multiply(F: Single; const C: TColorVec): TColorVec;
begin
  Result.R := F * C.R;
  Result.G := F * C.G;
  Result.B := F * C.B;
end;

class operator TColorVec.Multiply(const C1, C2: TColorVec): TColorVec;
begin
  Result.R := C1.R * C2.R;
  Result.G := C1.G * C2.G;
  Result.B := C1.B * C2.B;
end;

class operator TColorVec.Divide(const C: TColorVec; B: Single): TColorVec;
var
  Norm: Single;
begin
  Norm := 1 / B;
  Result.R := C.R * Norm;
  Result.G := C.G * Norm;
  Result.B := C.B * Norm;
end;

class operator TColorVec.Divide(A: Single; const C: TColorVec): TColorVec;
begin
  Result.R := A / C.R;
  Result.G := A / C.G;
  Result.B := A / C.B;
end;

class operator TColorVec.Divide(const C1, C2: TColorVec): TColorVec;
begin
  Result.R := C1.R / C2.R;
  Result.G := C1.G / C2.G;
  Result.B := C1.B / C2.B;
end;

function TColorVec.GetFlat(): Cardinal;
var
  Norm: Single;
  Red, Green, Blue: Integer;
begin
  Norm := 255 / Max(R, Max(G, B));
  Red := Round(R * Norm);
  Green := Round(G * Norm);
  Blue := Round(B * Norm);
  Result := GetColorFromRGB(Red, Green, Blue);
end;

end.
