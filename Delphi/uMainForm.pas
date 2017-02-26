unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  uImage2D, uVectors;

type
  TMainForm = class(TForm)
    pControls: TPanel;
    pRender: TPanel;
    imgRender: TImage;
    btnRender: TButton;
    Label1: TLabel;
    lblRenderTime: TLabel;
    procedure btnRenderClick(Sender: TObject);
  private
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  uRenderer, uScene, uHitable, uMaterial, uColor;

procedure TMainForm.AfterConstruction;
begin
  Randomize;
end;

procedure TMainForm.BeforeDestruction;
begin
end;

procedure TMainForm.btnRenderClick(Sender: TObject);
var
  Renderer: TRenderer;
  Image: TImage2D;
  StartTime, EndTime, Freq: Int64;
begin
  Image := nil;
  Renderer := TRenderer.Create(TScene.Create);
  try
    Renderer.Scene.Add(TSphere.Create(TVec3F.Create(0, 0, -1), 0.5, TLambertian.Create(TColorVec.Create(0.8, 0.3, 0.3))));
    Renderer.Scene.Add(TSphere.Create(TVec3F.Create(0, -100.5, -1), 100, TLambertian.Create(TColorVec.Create(0.8, 0.8, 0.0))));
    Renderer.Scene.Add(TSphere.Create(TVec3F.Create(1, 0, -1), 0.5, TMetal.Create(TColorVec.Create(0.8, 0.6, 0.2), 0.5)));
    Renderer.Scene.Add(TSphere.Create(TVec3F.Create(-1, 0, -1), 0.5, TMetal.Create(TColorVec.Create(0.8, 0.8, 0.8))));

    QueryPerformanceCounter(StartTime);
      Image := Renderer.Render(imgRender.ClientWidth div 1, imgRender.ClientHeight div 1);
    QueryPerformanceCounter(EndTime);
    QueryPerformanceFrequency(Freq);

    lblRenderTime.Caption := Format('%.3f', [1000 * (EndTime - StartTime) / Freq]);
    imgRender.Picture.Bitmap := Image.GetAsBitmap;
  finally
    FreeAndNil(Image);
    FreeAndNil(Renderer);
  end;
end;

end.
