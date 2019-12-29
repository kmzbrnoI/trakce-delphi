object F_Tester: TF_Tester
  Left = 0
  Top = 0
  ActiveControl = B_Load
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Tester trakce'
  ClientHeight = 538
  ClientWidth = 634
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 448
    Top = 359
    Width = 43
    Height = 13
    Caption = 'Loglevel:'
  end
  object Label2: TLabel
    Left = 8
    Top = 480
    Width = 51
    Height = 13
    Caption = 'Loco addr:'
  end
  object M_Log: TMemo
    Left = 7
    Top = 8
    Width = 619
    Height = 345
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
    OnDblClick = M_LogDblClick
  end
  object E_Path: TEdit
    Left = 8
    Top = 359
    Width = 257
    Height = 21
    TabOrder = 1
    Text = 'd:\UsersData\vlak\KMZ\xn-lib\build\debug\xn1.dll'
  end
  object B_Load: TButton
    Left = 271
    Top = 359
    Width = 75
    Height = 25
    Caption = 'Load'
    TabOrder = 2
    OnClick = B_LoadClick
  end
  object B_Unload: TButton
    Left = 352
    Top = 359
    Width = 75
    Height = 25
    Caption = 'Unload'
    TabOrder = 3
    OnClick = B_UnloadClick
  end
  object B_DCC_Go: TButton
    Left = 8
    Top = 392
    Width = 75
    Height = 25
    Caption = 'DCC Go'
    TabOrder = 4
    OnClick = B_DCC_GoClick
  end
  object B_DCC_Stop: TButton
    Left = 89
    Top = 392
    Width = 75
    Height = 25
    Caption = 'DCC Stop'
    TabOrder = 5
    OnClick = B_DCC_StopClick
  end
  object B_Show_Config: TButton
    Left = 168
    Top = 392
    Width = 75
    Height = 25
    Caption = 'Show config'
    TabOrder = 6
    OnClick = B_Show_ConfigClick
  end
  object B_Open: TButton
    Left = 8
    Top = 432
    Width = 75
    Height = 25
    Caption = 'Open'
    TabOrder = 7
    OnClick = B_OpenClick
  end
  object B_Close: TButton
    Left = 89
    Top = 432
    Width = 75
    Height = 25
    Caption = 'Close'
    TabOrder = 8
    OnClick = B_CloseClick
  end
  object CB_Loglevel: TComboBox
    Left = 497
    Top = 359
    Width = 129
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    ItemIndex = 4
    TabOrder = 9
    Text = 'Commands'
    Items.Strings = (
      'None'
      'Errors'
      'Warnings'
      'Infos'
      'Commands'
      'Data'
      'Debug')
  end
  object SE_Loco_Addr: TSpinEdit
    Left = 73
    Top = 480
    Width = 121
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 10
    Value = 42
  end
  object B_Loco_Acquire: TButton
    Left = 200
    Top = 480
    Width = 75
    Height = 25
    Caption = 'Acquire'
    TabOrder = 11
    OnClick = B_Loco_AcquireClick
  end
  object B_Loco_Release: TButton
    Left = 281
    Top = 480
    Width = 75
    Height = 25
    Caption = 'Release'
    TabOrder = 12
    OnClick = B_Loco_ReleaseClick
  end
end
