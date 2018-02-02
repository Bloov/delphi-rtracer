object SetupRender: TSetupRender
  Left = 0
  Top = 0
  Margins.Left = 4
  Margins.Top = 4
  Margins.Right = 4
  Margins.Bottom = 4
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Setup Render'
  ClientHeight = 358
  ClientWidth = 353
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  DesignSize = (
    353
    358)
  PixelsPerInch = 96
  TextHeight = 13
  object btnCancel: TButton
    Left = 244
    Top = 319
    Width = 100
    Height = 30
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Anchors = [akRight, akBottom]
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
    ExplicitTop = 338
  end
  object btnOk: TButton
    Left = 136
    Top = 319
    Width = 100
    Height = 30
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Anchors = [akRight, akBottom]
    Caption = 'Ok'
    ModalResult = 1
    TabOrder = 1
    OnClick = btnOkClick
    ExplicitTop = 338
  end
  object GroupBox1: TGroupBox
    Left = 9
    Top = 9
    Width = 335
    Height = 303
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Anchors = [akLeft, akTop, akRight, akBottom]
    Padding.Left = 4
    Padding.Top = 4
    Padding.Right = 4
    Padding.Bottom = 4
    TabOrder = 0
    ExplicitHeight = 322
    object Label1: TLabel
      Left = 7
      Top = 13
      Width = 74
      Height = 13
      Caption = 'Rendert Target'
    end
    object Label2: TLabel
      Left = 175
      Top = 13
      Width = 52
      Height = 13
      Caption = 'Max Depth'
    end
    object Label3: TLabel
      Left = 254
      Top = 13
      Width = 64
      Height = 13
      Caption = 'Target Depth'
    end
    object Label4: TLabel
      Left = 254
      Top = 69
      Width = 35
      Height = 13
      Caption = 'Gamma'
    end
    object Label5: TLabel
      Left = 7
      Top = 69
      Width = 28
      Height = 13
      Caption = 'Width'
    end
    object Label6: TLabel
      Left = 124
      Top = 92
      Width = 6
      Height = 13
      Caption = 'X'
    end
    object Label7: TLabel
      Left = 138
      Top = 69
      Width = 31
      Height = 13
      Caption = 'Height'
    end
    object Label8: TLabel
      Left = 6
      Top = 117
      Width = 118
      Height = 13
      Caption = 'Target Samples Per Pixel'
    end
    object Label9: TLabel
      Left = 6
      Top = 245
      Width = 145
      Height = 13
      Caption = 'Target Block Samples Per Pixel'
    end
    object Label10: TLabel
      Left = 7
      Top = 197
      Width = 55
      Height = 13
      Caption = 'Block Width'
    end
    object Label11: TLabel
      Left = 138
      Top = 197
      Width = 58
      Height = 13
      Caption = 'Block Height'
    end
    object Label12: TLabel
      Left = 124
      Top = 220
      Width = 6
      Height = 13
      Caption = 'X'
    end
    object cbRenderTarget: TComboBox
      Left = 8
      Top = 33
      Width = 159
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Style = csDropDownList
      TabOrder = 0
      Items.Strings = (
        'Color'
        'Normal'
        'Depth'
        'Color at Depth'
        'Scattered at Depth')
    end
    object edtDepthLimit: TEdit
      Left = 175
      Top = 33
      Width = 72
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 1
      Text = '50'
    end
    object edtTargetDepth: TEdit
      Left = 255
      Top = 33
      Width = 72
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 2
      Text = '0'
    end
    object edtGamma: TEdit
      Left = 254
      Top = 89
      Width = 73
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 5
      Text = '2'
    end
    object edtCustomWidth: TEdit
      Left = 7
      Top = 89
      Width = 110
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 3
      Text = '1024'
    end
    object edtCustomHeight: TEdit
      Left = 138
      Top = 89
      Width = 108
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 4
      Text = '1024'
    end
    object edtTargetSPP: TEdit
      Left = 7
      Top = 137
      Width = 110
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 6
      Text = '10'
    end
    object edtTargetBlockSPP: TEdit
      Left = 7
      Top = 265
      Width = 110
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 10
      Text = '10'
    end
    object edtBlockWidth: TEdit
      Left = 7
      Top = 217
      Width = 110
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 8
      Text = '16'
    end
    object edtBlockHeight: TEdit
      Left = 137
      Top = 217
      Width = 108
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 9
      Text = '16'
    end
    object cbUseBlockRender: TCheckBox
      Left = 6
      Top = 172
      Width = 201
      Height = 17
      Caption = 'Use Block Render'
      TabOrder = 7
    end
  end
end
