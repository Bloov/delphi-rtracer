unit uRenderSetup;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, uRenderer;

type
  TSetupRender = class(TForm)
    btnCancel: TButton;
    btnOk: TButton;
    GroupBox1: TGroupBox;
    cbRenderTarget: TComboBox;
    edtDepthLimit: TEdit;
    edtTargetDepth: TEdit;
    edtGamma: TEdit;
    edtCustomWidth: TEdit;
    edtCustomHeight: TEdit;
    edtTargetSPP: TEdit;
    edtTargetBlockSPP: TEdit;
    edtBlockWidth: TEdit;
    edtBlockHeight: TEdit;
    cbUseBlockRender: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;

    procedure btnOkClick(Sender: TObject);
  private
    FOptions: TRenderOptions;

    function CanClose(): Boolean;

    {procedure EnableControls;}
    procedure TransferData(ToControls: Boolean);
    procedure UpdateData();
    procedure SaveData();

  public
    constructor Create(AOwner: TComponent; AOptions: TRenderOptions); reintroduce;

    function ShowModal(): Integer; override;
  end;

var
  SetupRender: TSetupRender;

implementation

{$R *.dfm}

constructor TSetupRender.Create(AOwner: TComponent; AOptions: TRenderOptions);
begin
  inherited Create(AOwner);
  FOptions := AOptions;
end;

function TSetupRender.ShowModal(): Integer;
begin
  TransferData(True);
  Result := inherited ShowModal;
end;

procedure TSetupRender.btnOkClick(Sender: TObject);
begin
  if CanClose then
    TransferData(False);
end;

function TSetupRender.CanClose(): Boolean;
begin
  Result := True;
end;

{procedure TSetupRender.EnableControls;
begin
end;}

procedure TSetupRender.TransferData(ToControls: Boolean);
begin
  if ToControls then
    UpdateData
  else
    SaveData;
end;

procedure TSetupRender.UpdateData();
begin
  cbRenderTarget.ItemIndex := Ord(FOptions.RenderTarget);
  edtDepthLimit.Text := IntToStr(FOptions.DepthLimit);
  edtTargetDepth.Text := IntToStr(FOptions.TargetDepth);
  edtCustomWidth.Text := IntToStr(FOptions.Width);
  edtCustomHeight.Text := IntToStr(FOptions.Height);
  edtTargetSPP.Text := IntToStr(FOptions.SamplesPerPixel);
  edtGamma.Text := FloatToStr(FOptions.Gamma);
  cbUseBlockRender.Checked := FOptions.UseBlocks;
  edtBlockWidth.Text := IntToStr(FOptions.BlockWidth);
  edtBlockHeight.Text := IntToStr(FOptions.BlockHeight);
  edtTargetBlockSPP.Text := IntToStr(FOptions.BlockSamplesPerPixel);
end;

procedure TSetupRender.SaveData();
begin
  FOptions.RenderTarget := TRenderTarget(cbRenderTarget.ItemIndex);
  FOptions.DepthLimit := StrToInt(edtDepthLimit.Text);
  FOptions.TargetDepth := StrToInt(edtTargetDepth.Text);
  FOptions.Width := StrToInt(edtCustomWidth.Text);
  FOptions.Height := StrToInt(edtCustomHeight.Text);
  FOptions.SamplesPerPixel := StrToInt(edtTargetSPP.Text);
  FOptions.Gamma := StrToFloat(edtGamma.Text);
  FOptions.UseBlocks := cbUseBlockRender.Checked;
  FOptions.BlockWidth := StrToInt(edtBlockWidth.Text);
  FOptions.BlockHeight := StrToInt(edtBlockHeight.Text);
  FOptions.BlockSamplesPerPixel := StrToInt(edtTargetBlockSPP.Text);
end;

end.
