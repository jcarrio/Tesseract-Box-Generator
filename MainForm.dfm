object frmMain: TfrmMain
  Left = 376
  Top = 150
  Width = 1024
  Height = 678
  Caption = 'Tesseract Box Gen'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object ScrollBox1: TScrollBox
    Left = 0
    Top = 0
    Width = 806
    Height = 510
    Align = alClient
    TabOrder = 0
    object Image1: TImage
      Left = 0
      Top = 0
      Width = 780
      Height = 376
      OnClick = Image1Click
      OnMouseDown = Image1MouseDown
      OnMouseMove = Image1MouseMove
      OnMouseUp = Image1MouseUp
    end
  end
  object Panel1: TPanel
    Left = 806
    Top = 0
    Width = 202
    Height = 510
    Align = alRight
    TabOrder = 1
    DesignSize = (
      202
      510)
    object ListBox1: TListBox
      Left = 13
      Top = 56
      Width = 177
      Height = 441
      Anchors = [akLeft, akTop, akBottom]
      ItemHeight = 13
      TabOrder = 1
      OnClick = ListBox1Click
    end
    object btnPasta: TButton
      Left = 64
      Top = 16
      Width = 75
      Height = 25
      Caption = 'Pasta .TIF'
      TabOrder = 0
      OnClick = btnPastaClick
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 510
    Width = 1008
    Height = 129
    Align = alBottom
    TabOrder = 2
    DesignSize = (
      1008
      129)
    object Label1: TLabel
      Left = 24
      Top = 15
      Width = 49
      Height = 13
      Caption = 'Inclina'#231#227'o'
    end
    object Memo1: TMemo
      Left = 112
      Top = 8
      Width = 449
      Height = 113
      ReadOnly = True
      TabOrder = 3
    end
    object btnIncrease: TButton
      Left = 920
      Top = 16
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Aumentar'
      TabOrder = 5
      OnClick = btnIncreaseClick
    end
    object btnDecrease: TButton
      Left = 920
      Top = 48
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Diminuir'
      TabOrder = 6
      OnClick = btnDecreaseClick
    end
    object btnSaveBox: TButton
      Left = 574
      Top = 16
      Width = 75
      Height = 25
      Caption = 'Salvar Box'
      TabOrder = 4
      OnClick = btnSaveBoxClick
    end
    object edtInclinacao: TEdit
      Left = 24
      Top = 31
      Width = 65
      Height = 21
      TabOrder = 0
      OnKeyPress = edtInclinacaoKeyPress
    end
    object btnProcessar: TButton
      Left = 24
      Top = 55
      Width = 75
      Height = 25
      Caption = 'Processar'
      TabOrder = 1
      OnClick = btnProcessarClick
    end
    object btnSalvaTif: TButton
      Left = 24
      Top = 87
      Width = 75
      Height = 25
      Caption = 'Salvar TIF'
      TabOrder = 2
      OnClick = btnSalvaTifClick
    end
  end
  object SaveDialog1: TSaveDialog
    Filter = 'Arquivos .box|*.box'
    InitialDir = 'D:\Treinamento\arquivos'
    Left = 830
    Top = 16
  end
end
