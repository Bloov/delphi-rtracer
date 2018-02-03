object MainForm: TMainForm
  Left = 0
  Top = 0
  Anchors = [akLeft, akTop, akBottom]
  Caption = 'RayTracer'
  ClientHeight = 571
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
    Width = 249
    Height = 571
    Align = alLeft
    Alignment = taLeftJustify
    TabOrder = 0
    DesignSize = (
      249
      571)
    object Label1: TLabel
      Left = 8
      Top = 126
      Width = 91
      Height = 13
      Caption = 'Render Time (sec):'
    end
    object lblRenderTime: TLabel
      Left = 105
      Top = 126
      Width = 3
      Height = 13
    end
    object Label2: TLabel
      Left = 8
      Top = 145
      Width = 166
      Height = 13
      Caption = 'Render Performance (MRays/sec):'
    end
    object lblRenderPerformance: TLabel
      Left = 180
      Top = 145
      Width = 3
      Height = 13
    end
    object btnRenderControl: TButton
      Left = 8
      Top = 16
      Width = 113
      Height = 30
      Caption = 'Render'
      TabOrder = 0
      OnClick = btnRenderClick
    end
    object btnSaveImage: TButton
      Left = 130
      Top = 16
      Width = 113
      Height = 30
      Anchors = [akTop, akRight]
      Caption = 'Save Image'
      TabOrder = 1
      OnClick = btnSaveImageClick
    end
    object btnBenchmarkCamera: TButton
      Left = 8
      Top = 172
      Width = 113
      Height = 30
      Caption = 'Benchmark Camera'
      TabOrder = 5
      OnClick = btnBenchmarkCameraClick
    end
    object lbText: TListBox
      Left = 8
      Top = 328
      Width = 235
      Height = 232
      Anchors = [akLeft, akTop, akBottom]
      ItemHeight = 13
      TabOrder = 7
    end
    object btnClearText: TButton
      Left = 168
      Top = 292
      Width = 75
      Height = 30
      Anchors = [akTop, akRight]
      Caption = 'Clear'
      TabOrder = 11
      OnClick = btnClearTextClick
    end
    object btnBenchmarkScene: TButton
      Left = 8
      Top = 208
      Width = 113
      Height = 30
      Caption = 'Benchmark Scene'
      TabOrder = 8
      OnClick = btnBenchmarkSceneClick
    end
    object btnBenchmarkAABB: TButton
      Left = 130
      Top = 172
      Width = 113
      Height = 30
      Anchors = [akTop, akRight]
      Caption = 'Benchmark AABB'
      TabOrder = 6
      OnClick = btnBenchmarkAABBClick
    end
    object btnBenchmarkRotate: TButton
      Left = 130
      Top = 208
      Width = 113
      Height = 30
      Anchors = [akTop, akRight]
      Caption = 'Benchmark Rotate'
      TabOrder = 9
      OnClick = btnBenchmarkRotateClick
    end
    object btnBenchmarkHit: TButton
      Left = 130
      Top = 244
      Width = 113
      Height = 30
      Anchors = [akTop, akRight]
      Caption = 'Benchmark Hit'
      TabOrder = 10
      OnClick = btnBenchmarkHitClick
    end
    object btnSetupRender: TButton
      Left = 8
      Top = 52
      Width = 113
      Height = 30
      Caption = 'Setup Render...'
      TabOrder = 2
      OnClick = btnSetupRenderClick
    end
    object btnSetupScene: TButton
      Left = 130
      Top = 52
      Width = 113
      Height = 30
      Anchors = [akTop, akRight]
      Caption = 'Setup Scene...'
      TabOrder = 3
    end
    object cbUseViewportSize: TCheckBox
      Left = 11
      Top = 88
      Width = 150
      Height = 17
      Caption = 'Use Viewport size'
      TabOrder = 4
    end
  end
  object pRender: TPanel
    Left = 249
    Top = 0
    Width = 673
    Height = 571
    Align = alClient
    TabOrder = 1
    object imgRender: TImage
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 665
      Height = 563
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
    Left = 8
    Top = 288
  end
end
