object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsToolWindow
  Caption = 'MainForm'
  ClientHeight = 208
  ClientWidth = 564
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object btn1: TButton
    Left = 72
    Top = 40
    Width = 401
    Height = 33
    Caption = 'WinAPI-QueryPerformanceCounter '#32435#31186#32423#21035'Sleep(1000)'#35745#26102' '
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = btn1Click
  end
  object btn2: TButton
    Left = 72
    Top = 120
    Width = 401
    Height = 33
    Caption = #27719#32534' - CPU'#26102#38047#21608#26399' Sleep(1000)'#35745#26102' '
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = btn2Click
  end
end
