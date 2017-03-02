object MainForm: TMainForm
  Left = 0
  Top = 0
  Anchors = [akLeft, akTop, akBottom]
  Caption = 'RayTracer'
  ClientHeight = 548
  ClientWidth = 922
  Color = clBtnFace
  Constraints.MinHeight = 400
  Constraints.MinWidth = 600
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object pControls: TPanel
    Left = 0
    Top = 0
    Width = 265
    Height = 548
    Align = alLeft
    Alignment = taLeftJustify
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 72
      Width = 88
      Height = 13
      Caption = 'Render Time (ms):'
    end
    object lblRenderTime: TLabel
      Left = 102
      Top = 72
      Width = 3
      Height = 13
    end
    object btnRender: TButton
      Left = 8
      Top = 16
      Width = 113
      Height = 33
      Caption = 'Render'
      TabOrder = 0
      OnClick = btnRenderClick
    end
    object btnSaveImage: TButton
      Left = 146
      Top = 16
      Width = 113
      Height = 33
      Caption = 'Save Image'
      TabOrder = 1
      OnClick = btnSaveImageClick
    end
    object btnBenchmarkCamera: TButton
      Left = 8
      Top = 104
      Width = 113
      Height = 33
      Caption = 'Benchmark Camera'
      TabOrder = 2
      OnClick = btnBenchmarkCameraClick
    end
    object lbText: TListBox
      Left = 8
      Top = 368
      Width = 251
      Height = 169
      ItemHeight = 13
      TabOrder = 5
    end
    object btnClearText: TButton
      Left = 176
      Top = 337
      Width = 75
      Height = 25
      Caption = 'Clear'
      TabOrder = 4
      OnClick = btnClearTextClick
    end
    object btnBenchmarkScene: TButton
      Left = 8
      Top = 143
      Width = 113
      Height = 33
      Caption = 'Benchmark Scene'
      TabOrder = 3
      OnClick = btnBenchmarkSceneClick
    end
  end
  object pRender: TPanel
    Left = 265
    Top = 0
    Width = 657
    Height = 548
    Align = alClient
    TabOrder = 1
    object imgRender: TImage
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 649
      Height = 540
      Align = alClient
      Proportional = True
      Stretch = True
      ExplicitLeft = 48
      ExplicitTop = 40
      ExplicitWidth = 105
      ExplicitHeight = 105
    end
  end
  object dlgSaveImage: TSaveDialog
    DefaultExt = '*.png'
    Filter = 'PNG Image|*.png'
    Left = 224
    Top = 56
  end
end
