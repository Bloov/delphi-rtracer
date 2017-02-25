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
  uRenderer, uScene, uHitable;

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
    Renderer.Scene.Add(TSphere.Create(TVec3F.Create(0, 0, -1), 0.5));
    Renderer.Scene.Add(TSphere.Create(TVec3F.Create(0, -100.5, -1), 100));

    QueryPerformanceCounter(StartTime);
      Image := Renderer.Render(imgRender.ClientWidth div 2, imgRender.ClientHeight div 2);
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
