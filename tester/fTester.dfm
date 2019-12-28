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
  object M_Log: TMemo
    Left = 8
    Top = 8
    Width = 619
    Height = 169
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
    OnDblClick = M_LogDblClick
  end
  object E_Path: TEdit
    Left = 8
    Top = 183
    Width = 257
    Height = 21
    TabOrder = 1
    Text = 'd:\UsersData\vlak\KMZ\xn-lib\build\debug\xn1.dll'
  end
  object B_Load: TButton
    Left = 271
    Top = 183
    Width = 75
    Height = 25
    Caption = 'Load'
    TabOrder = 2
    OnClick = B_LoadClick
  end
  object B_Unload: TButton
    Left = 352
    Top = 183
    Width = 75
    Height = 25
    Caption = 'Unload'
    TabOrder = 3
    OnClick = B_UnloadClick
  end
end
