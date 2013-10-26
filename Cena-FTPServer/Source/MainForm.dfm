object FTPServer: TFTPServer
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'Cena2 - FTP Server '
  ClientHeight = 433
  ClientWidth = 514
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lbl1: TLabel
    Left = 24
    Top = 27
    Width = 112
    Height = 13
    Caption = 'FTP'#26381#21153#22120#26681#30446#24405#65306
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
  end
  object lbl2: TLabel
    Left = 24
    Top = 62
    Width = 99
    Height = 13
    Caption = 'FTP'#26381#21153#22120#31471#21475#65306
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
  end
  object lbl7: TLabel
    Left = 224
    Top = 61
    Width = 106
    Height = 13
    Caption = #24403#21069#26381#21153#22120'IP'#22320#22336#65306
  end
  object lbl8: TLabel
    Left = 24
    Top = 405
    Width = 180
    Height = 13
    Caption = #24403#21069#29366#24577#65306#20934#22791#23601#32490#12290#31561#24453#25351#20196#12290
  end
  object edt1: TEdit
    Left = 142
    Top = 24
    Width = 243
    Height = 21
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object btn1: TButton
    Left = 391
    Top = 22
    Width = 75
    Height = 25
    Caption = #36873#25321
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = btn1Click
  end
  object edt2: TEdit
    Left = 142
    Top = 58
    Width = 57
    Height = 21
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    Text = '21'
    OnKeyPress = edt2KeyPress
  end
  object grp1: TGroupBox
    Left = 24
    Top = 104
    Width = 465
    Height = 273
    Caption = #27169#24335#36873#25321' ['#21487#22312#36816#34892#29366#24577#19979#21363#26102#20462#25913#27169#24335#65292#26080#38656#37325#21551'Server]'
    TabOrder = 3
    object lbl3: TLabel
      Left = 16
      Top = 47
      Width = 420
      Height = 26
      Caption = 
        #35828#26126#65306#29992#25143#20165#21487#35265#26412#22320#26381#21153#22120#19978#30340'*.PDF'#12289'*.DOC'#12289'*.DOCX'#12289'*.ZIP'#12289'*.RAR'#25991#20214#65292#13#10#20854#20182#25991#20214#22343#19981#21487#35265#12290#21516#26102#19981#25317#26377 +
        #21024#38500#12289#26032#24314#12289#20462#25913#26435#38480#65292#20165#25317#26377#19979#36733#26435#38480#12290
    end
    object lbl4: TLabel
      Left = 16
      Top = 104
      Width = 444
      Height = 52
      Caption = 
        #35828#26126#65306#29992#25143#21487#35265#20219#20309#38500'*.PDF'#12289'*.DOC'#12289'*.DOCX'#12289'*.IN'#12289'*.OUT'#12289'*.ZIP'#12289'*.RAR'#13#10#20043#22806#30340#20219#20309#25991#20214#12290#25317#26377#19978 +
        #20256#12289#26032#24314#25991#20214#25110#25991#20214#22841#26435#38480#65292#19981#25317#26377#21024#38500#12289#19979#36733#12289#37325#21629#21517#12289#13#10#20462#25913#26435#12290' '#65288#22312#27492#29366#24577#19979#26032#24314#25991#20214#22841#38656#35201#29992#25143#20174#26412#22320#26032#24314#21518#37325#21629#21517#32467#26463#21518#20877#19978#20256#65292 +
        #13#10' '#19981#21487#22312'FTP'#19978#26032#24314#25991#20214#22841#21518#37325#21629#21517#65292#21516#26102#20250#33258#21160#31105#27490#26597#30475#12289#20462#25913#24050#19978#20256#30340#28304#20195#30721#65289
    end
    object lbl5: TLabel
      Left = 16
      Top = 194
      Width = 360
      Height = 13
      Caption = #35828#26126#65306#29992#25143#25317#26377#23436#20840#21487#35265#12289#19979#36733#26435#38480#12290#26080#20462#25913#12289#21024#38500#12289#37325#21629#21517#26435#38480#12290
    end
    object lbl6: TLabel
      Left = 16
      Top = 248
      Width = 228
      Height = 13
      Caption = #35828#26126#65306#29992#25143#25317#26377#23436#20840#30340#35835#12289#20889#26435#38480#12290#24910#29992#12290
    end
    object rb1: TRadioButton
      Left = 16
      Top = 24
      Width = 97
      Height = 17
      Caption = #35797#39064#20998#21457#27169#24335
      TabOrder = 0
    end
    object rb2: TRadioButton
      Left = 16
      Top = 82
      Width = 96
      Height = 17
      Caption = #23398#29983#25552#20132#27169#24335
      TabOrder = 1
    end
    object rb3: TRadioButton
      Left = 16
      Top = 171
      Width = 113
      Height = 17
      Caption = #32467#26524#20998#20139#27169#24335
      TabOrder = 2
    end
    object rb4: TRadioButton
      Left = 16
      Top = 225
      Width = 83
      Height = 17
      Caption = #23436#20840#27169#24335
      TabOrder = 3
    end
  end
  object btn2: TButton
    Left = 310
    Top = 400
    Width = 75
    Height = 25
    Caption = #36816#34892#26381#21153
    TabOrder = 4
    OnClick = btn2Click
  end
  object btn3: TButton
    Left = 391
    Top = 400
    Width = 75
    Height = 25
    Caption = #36864#20986
    TabOrder = 5
    OnClick = btn3Click
  end
  object idftpsrvr1: TIdFTPServer
    Bindings = <>
    DefaultPort = 21
    CommandHandlers = <>
    ExceptionReply.Code = '500'
    ExceptionReply.Text.Strings = (
      'Unknown Internal Error')
    Greeting.Code = '220'
    Greeting.Text.Strings = (
      'Indy FTP Server ready.')
    MaxConnectionReply.Code = '300'
    MaxConnectionReply.Text.Strings = (
      'Too many connections. Try again later.')
    ReplyTexts = <>
    ReplyUnknownCommand.Code = '500'
    ReplyUnknownCommand.Text.Strings = (
      'Unknown Command')
    AnonymousAccounts.Strings = (
      'anonymous'
      'ftp'
      'guest')
    OnChangeDirectory = idftpsrvr1ChangeDirectory
    OnUserLogin = idftpsrvr1UserLogin
    OnListDirectory = idftpsrvr1ListDirectory
    OnRenameFile = idftpsrvr1RenameFile
    OnDeleteFile = idftpsrvr1DeleteFile
    OnRetrieveFile = idftpsrvr1RetrieveFile
    OnStoreFile = idftpsrvr1StoreFile
    OnMakeDirectory = idftpsrvr1MakeDirectory
    OnRemoveDirectory = idftpsrvr1RemoveDirectory
    SITECommands = <>
    MLSDFacts = []
    ReplyUnknownSITCommand.Code = '500'
    ReplyUnknownSITCommand.Text.Strings = (
      'Invalid SITE command.')
    Left = 456
    Top = 64
  end
  object idpwtch1: TIdIPWatch
    Active = False
    HistoryFilename = 'iphist.dat'
    Left = 416
    Top = 64
  end
end
