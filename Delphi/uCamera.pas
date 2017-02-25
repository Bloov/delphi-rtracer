unit uCamera;

interface

uses
  uVectors, uRay;

type
  TCamera = class abstract
  private
    FWidth, FHeight: Integer;
    FAspectRatio: Single;
  public
    procedure SetupView(AWidth, AHeight: Integer); virtual;

    function GetRay(U, V: Single): TRay; virtual; abstract;

    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property AspectRatio: Single read FAspectRatio;
  end;

  TSimpleCamera = class(TCamera)
  private
    FOrigin: TVec3F;
    FCorner: TVec3F;
    FHorz, FVert: TVec3F;
  public
    procedure SetupView(AWidth, AHeight: Integer); override;

    function GetRay(U, V: Single): TRay; override;
  end;

implementation

{ TCamera }
procedure TCamera.SetupView(AWidth, AHeight: Integer);
begin
  if (AWidth = 0) or (AHeight = 0) then
    Exit;

  FWidth := AWidth;
  FHeight := AHeight;
  FAspectRatio := FWidth / FHeight;
end;

{ TSimpleCamera }
procedure TSimpleCamera.SetupView(AWidth, AHeight: Integer);
begin
  inherited SetupView(AWidth, AHeight);
  FOrigin := TVec3F.Create(0, 0, 0);
  FCorner := TVec3F.Create(-AspectRatio, 1, -1);
  FHorz := AspectRatio * TVec3F.Create(2, 0, 0);
  FVert := TVec3F.Create(0, 2, 0);
end;

function TSimpleCamera.GetRay(U, V: Single): TRay;
begin
  Result := TRay.Create(FOrigin, FCorner + U * FHorz - V * FVert);
end;

end.
