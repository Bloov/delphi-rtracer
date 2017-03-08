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
    ExplicitLeft = -24
    ExplicitTop = -8
    DesignSize = (
      265
      548)
    object Label1: TLabel
      Left = 8
      Top = 72
      Width = 91
      Height = 13
      Caption = 'Render Time (sec):'
    end
    object lblRenderTime: TLabel
      Left = 102
      Top = 72
      Width = 3
      Height = 13
    end
    object Label2: TLabel
      Left = 8
      Top = 91
      Width = 172
      Height = 13
      Caption = 'Render Performance (MRays / sec):'
    end
    object lblRenderPerformance: TLabel
      Left = 186
      Top = 91
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
      Top = 132
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
      Anchors = [akLeft, akBottom]
      ItemHeight = 13
      TabOrder = 5
    end
    object btnClearText: TButton
      Left = 176
      Top = 337
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = 'Clear'
      TabOrder = 4
      OnClick = btnClearTextClick
    end
    object btnBenchmarkScene: TButton
      Left = 8
      Top = 171
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
    Left = 136
    Top = 136
  end
end
