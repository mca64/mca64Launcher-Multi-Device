unit mca64Launcher;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.TabControl,
  FMX.StdCtrls, FMX.Gestures, FMX.ListView.Types, FMX.ListView, ListaStrumieni,
  FMX.Layouts, FMX.Memo, OpenViewUrl, FMX.Controls.Presentation, FMX.Edit,
  FMX.ComboEdit, FMX.Platform, FMX.Notification, IdContext, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, IdCmdTCPClient, IdIRC, IdGlobal,
  FMX.ListBox, System.IOUtils, System.Diagnostics
{$IFDEF ANDROID}, Androidapi.JNI.GraphicsContentViewText, FMX.Helpers.Android,
  Androidapi.JNI.JavaTypes, FMX.Platform.Android, Androidapi.JniBridge, Androidapi.JNI.App,
  Androidapi.JNI.OS, Androidapi.JNI.Provider, Androidapi.Helpers
{$ENDIF ANDROID}
    ;

type
  TCzatTwitcha = class
  private
    fIdIRC: TIdIRC;
    fLogin: string;
    fHaslo: string;
    fKanal: string;
    fBlad: boolean;
    function Polacz: boolean;
    procedure NowaWiadomosc(ASender: TIdContext; const ANickname, AHost, ATarget, AMessage: string);
    procedure WyslijWiadomosc(const tresc: string);
  public
    property pLogin: string read fLogin;
    property pWyslijWiadomosc: string write WyslijWiadomosc;
    property pBlad: boolean read fBlad;
    constructor Create(const login, haslo, kanal: string);
    destructor Destroy; override;
  end;

  TForm1 = class(TForm)
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    TabItem3: TTabItem;
    GestureManager1: TGestureManager;
    ListView1: TListView;
    Memo1: TMemo;
    Timer1: TTimer;
    Panel1: TPanel;
    Edit1: TEdit;
    Memo2: TMemo;
    NotificationCenter1: TNotificationCenter;
    HeaderToolBar: TToolBar;
    ToolBarLabel: TLabel;
    Edit2: TEdit;
    SpeedButton1: TSpeedButton;
    ListBox1: TListBox;
    ProgressBar1: TProgressBar;
    ToolBar1: TToolBar;
    Edit3: TEdit;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: boolean);
    procedure Timer1Timer(Sender: TObject);
    procedure ListView1ItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SpeedButton1Click(Sender: TObject);
    procedure ListBox1ItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
    procedure Button1Click(Sender: TObject);
    procedure TabControl1Change(Sender: TObject);

  private
    modyfikacjaInfaStreamy: TStringList;
    fLicznikPowiadomienia: integer;
    fCzatTwitcha: TCzatTwitcha;
    fAktywnaAplikacja: boolean;
    fCzatTwitchaBufor: TStringList;
    fPoprzedniStanAktywnaAplikacja: boolean;
    procedure WczytanieListyGier;
    function Zdarzenia(AAppEvent: TApplicationEvent; AContext: TObject): boolean;
    procedure UtworzenieSkrotu;
  public
    fAdresy: TStringList;
    fZerg: TResourceStream;
    fTerran: TResourceStream;
    fToss: TResourceStream;
    fSonic: TResourceStream;
    fAdobe, fmca64Launcher, fOBS, fXSplit: TResourceStream;
    mojePowiadomienie: TNotification;
    procedure Powiadomienie(const tekst: string);

    property pAktywnaAplikacja: boolean read fAktywnaAplikacja;
    property pCzatTwitchaBufor: TStringList read fCzatTwitchaBufor;
    { Public declarations }
  end;

var
  Form1: TForm1;
  czasUruchomienia: TStopWatch;

implementation

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}

procedure TForm1.Button1Click(Sender: TObject);
begin
  if Button1.Text = 'Rozłącz' then
  begin
    try
      if fCzatTwitcha <> nil then FreeAndNil(fCzatTwitcha);
      Button1.Text := 'Połącz';
    except
    end;
  end
  else
  begin
    try
      if fCzatTwitcha <> nil then FreeAndNil(fCzatTwitcha);
      fCzatTwitcha := TCzatTwitcha.Create('justinfan64', '', Edit3.Text);
      Button1.Text := 'Rozłącz';
    except
    end;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  try
    // Memo2.Lines.SaveToFile(TPath.Combine(TPath.GetSharedDocumentsPath, 'StrumienieGry.txt'));
    if fCzatTwitcha <> nil then FreeAndNil(fCzatTwitcha);
    fZerg.Free;
    fTerran.Free;
    fToss.Free;
    fSonic.Free;
    fAdobe.Free;
    fmca64Launcher.Free;
    fOBS.Free;
    fXSplit.Free;
  except
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  AppEventSvc: IFMXApplicationEventService;
  plik: TStringList;
begin
{$IFDEF MSWINDOWS}
  Button1.Position.y := 8;
  // SpeedButton1.Position.y := 8;
{$ENDIF MSWINDOWS}
  if TPlatformServices.Current.SupportsPlatformService(IFMXApplicationEventService, IInterface(AppEventSvc)) then
      AppEventSvc.SetApplicationEventHandler(Zdarzenia);
  { This defines the default active tab at runtime }
  TabControl1.ActiveTab := TabItem2;
  fZerg := TResourceStream.Create(hInstance, 'rasa0', RT_RCDATA);
  fTerran := TResourceStream.Create(hInstance, 'rasa1', RT_RCDATA);
  fToss := TResourceStream.Create(hInstance, 'rasa2', RT_RCDATA);
  // fSonic := TResourceStream.Create(hInstance, 'rasa4', RT_RCDATA);
  fSonic := TResourceStream.Create(hInstance, 'PngImage_5', RT_RCDATA);
  fAdobe := TResourceStream.Create(hInstance, 'PngImage_1', RT_RCDATA);
  fmca64Launcher := TResourceStream.Create(hInstance, 'PngImage_2', RT_RCDATA);
  fOBS := TResourceStream.Create(hInstance, 'PngImage_3', RT_RCDATA);
  fXSplit := TResourceStream.Create(hInstance, 'PngImage_4', RT_RCDATA);
  modyfikacjaInfaStreamy := TStringList.Create;
  fAdresy := TStringList.Create;
  modyfikacjaInfaStreamy.Assign(Memo1.Lines);
  modyfikacjaInfaStreamy.Delete(Form1.modyfikacjaInfaStreamy.Count - 1);
  TListaStrumieni.Create(ListView1, modyfikacjaInfaStreamy, false, 0, Edit2.Text, ProgressBar1);
  Powiadomienie('mca64Launcher is here to stay!');
  ListBox1.Visible := false;
  fCzatTwitchaBufor := TStringList.Create;
  fAktywnaAplikacja := true;
  WczytanieListyGier;
  czasUruchomienia.Stop;
  if not fileExists(TPath.Combine(TPath.GetSharedDocumentsPath, 'Skrot.txt')) then
  begin
    UtworzenieSkrotu;
    plik := TStringList.Create;
    try
      plik.SaveToFile(TPath.Combine(TPath.GetSharedDocumentsPath, 'Skrot.txt'));
    finally
      plik.Free;
    end;
  end;
  Memo2.Lines.Add('Czas uruchomienia: ' + IntToStr(czasUruchomienia.ElapsedMilliseconds) + ' ms');
end;

procedure TForm1.FormGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: boolean);
begin
{$IFDEF ANDROID}
  case EventInfo.GestureID of
    sgiLeft:
      begin
        if TabControl1.ActiveTab <> TabControl1.Tabs[TabControl1.TabCount - 1] then
            TabControl1.ActiveTab := TabControl1.Tabs[TabControl1.TabIndex + 1];
        Handled := true;
      end;
    sgiRight:
      begin
        if TabControl1.ActiveTab <> TabControl1.Tabs[0] then TabControl1.ActiveTab := TabControl1.Tabs[TabControl1.TabIndex - 1];
        Handled := true;
      end;
  end;
{$ENDIF}
end;

procedure TForm1.ListBox1ItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
begin
  Edit2.Text := ListBox1.Items[Item.Index];
  ListBox1.Visible := false;
  TListaStrumieni.Create(ListView1, modyfikacjaInfaStreamy, false, 0, Edit2.Text, ProgressBar1);
end;

procedure TForm1.ListView1ItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  if fAdresy.Count > 0 then OpenURL(fAdresy[AItem.Index], true);
end;

procedure TForm1.TabControl1Change(Sender: TObject);
var
  i: integer;
begin
  if TabControl1.ActiveTab = TabItem1 then
    if fCzatTwitchaBufor.Count > 0 then
    begin
      Memo2.Lines.BeginUpdate;
      for i := 0 to fCzatTwitchaBufor.Count - 1 do Memo2.Lines.Add(fCzatTwitchaBufor.Strings[i]);
      Form1.Memo2.GoToTextEnd;
      Memo2.Lines.EndUpdate;
      fCzatTwitchaBufor.Clear;
    end;
  {
    if TabControl1.ActiveTab = TabItem2 then
    begin
    Edit2.SetFocus;
    Edit2.SelStart := Length(Edit2.Text);
    end
    else if TabControl1.ActiveTab = TabItem1 then
    begin
    Edit3.SetFocus;
    Edit3.SelStart := Length(Edit3.Text);
    end;
  }
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if not ListBox1.Visible then TListaStrumieni.Create(ListView1, modyfikacjaInfaStreamy, false, 0, Edit2.Text, ProgressBar1);
end;

procedure TForm1.Powiadomienie(const tekst: string);
var
  mojePowiadomienie: TNotification;
begin
  mojePowiadomienie := NotificationCenter1.CreateNotification;
  try
    Inc(fLicznikPowiadomienia);
    mojePowiadomienie.Number := fLicznikPowiadomienia;
    mojePowiadomienie.AlertBody := tekst;
    mojePowiadomienie.EnableSound := false;
    NotificationCenter1.PresentNotification(mojePowiadomienie);
  finally
    mojePowiadomienie.DisposeOf;
  end;
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  ListBox1.Visible := not ListBox1.Visible;
  if ListBox1.Visible then
  begin
    ListBox1.ApplyStyleLookup;
    ListBox1.RealignContent;
  end;
end;

function TForm1.Zdarzenia(AAppEvent: TApplicationEvent; AContext: TObject): boolean;
var
  i: integer;
begin
  case AAppEvent of
    TApplicationEvent.BecameActive:
      begin
        // Powiadomienie('mca64Launcher "aktywny"');
        fAktywnaAplikacja := true;
        Timer1.Enabled := true;
      end;
    TApplicationEvent.WillBecomeInactive:
      begin
        // Powiadomienie('mca64Launcher "nieaktywny"');
        fAktywnaAplikacja := false;
        Timer1.Enabled := false;
      end;
    TApplicationEvent.EnteredBackground:
      begin
        // Powiadomienie('mca64Launcher "w tle"');
        fAktywnaAplikacja := false;
        Timer1.Enabled := false;
      end;
    TApplicationEvent.WillBecomeForeground:
      begin
        fAktywnaAplikacja := true;
        // Powiadomienie('mca64Launcher "foreground"');
        Timer1.Enabled := true;
      end;
    TApplicationEvent.WillTerminate:
      begin
        fAktywnaAplikacja := false;
        Powiadomienie('Zakończenie programu')
      end;
    // TApplicationEvent.LowMemory:
    // TApplicationEvent.TimeChange:
    // TApplicationEvent.OpenURL:
  end;

  case AAppEvent of
    TApplicationEvent.BecameActive, TApplicationEvent.WillBecomeInactive, TApplicationEvent.EnteredBackground,
      TApplicationEvent.WillBecomeForeground, TApplicationEvent.WillTerminate:
      begin
        if (fAktywnaAplikacja) and (not fPoprzedniStanAktywnaAplikacja) then
          if fCzatTwitchaBufor.Count > 0 then
          begin
            Memo2.Lines.BeginUpdate;
            for i := 0 to fCzatTwitchaBufor.Count - 1 do Memo2.Lines.Add(fCzatTwitchaBufor.Strings[i]);
            Form1.Memo2.GoToTextEnd;
            Memo2.Lines.EndUpdate;
            fCzatTwitchaBufor.Clear;
          end;
        fPoprzedniStanAktywnaAplikacja := fAktywnaAplikacja;
      end;
  end;
  Result := true;
end;

function TCzatTwitcha.Polacz: boolean;
begin
  fIdIRC := TIdIRC.Create(nil);
  fIdIRC.OnPrivateMessage := NowaWiadomosc;
  fIdIRC.UserMode := [];
  fIdIRC.Host := 'irc.twitch.tv';
  fIdIRC.Nickname := fLogin;
  fIdIRC.Password := fHaslo;
  try
    fIdIRC.Connect;
    fIdIRC.Join('#' + fKanal);
    fIdIRC.IOHandler.DefStringEncoding := IndyTextEncoding_UTF8();
    Result := true;
  except
    fIdIRC.Host := '199.9.250.229';
    fIdIRC.Connect;
    fIdIRC.Join('#' + fKanal);
    fIdIRC.IOHandler.DefStringEncoding := IndyTextEncoding_UTF8();
    Result := true;
  end;
end;

procedure TCzatTwitcha.NowaWiadomosc(ASender: TIdContext; const ANickname, AHost, ATarget, AMessage: string);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      if (Form1.pAktywnaAplikacja) and (Form1.TabControl1.ActiveTab = Form1.TabItem1) then
      begin
        Form1.Memo2.Lines.BeginUpdate;
        Form1.Memo2.Lines.Add('<' + TimeToStr(Time) + '> ' + ANickname + ':  ' + AMessage);
        Form1.Memo2.GoToTextEnd;
        // Form1.Memo2.ScrollTo(Max,0);
        Form1.Memo2.Lines.EndUpdate;
      end
      else
      begin
        Form1.pCzatTwitchaBufor.Add('<' + TimeToStr(Time) + '> ' + ANickname + ':  ' + AMessage)
      end;
    end);
end;

procedure TCzatTwitcha.WyslijWiadomosc(const tresc: String);
begin
  fIdIRC.Say('#' + fKanal, tresc);
end;

constructor TCzatTwitcha.Create(const login, haslo, kanal: string);
begin
  inherited Create;
  fBlad := true;
  fLogin := login;
  fHaslo := haslo;
  fKanal := kanal;
  if (fLogin <> '') { and (fHaslo <> '') } and (fKanal <> '') then fBlad := not Polacz
end;

destructor TCzatTwitcha.Destroy;
begin
  try
    fIdIRC.Free;
  except
  end;
  inherited;
end;

procedure TForm1.WczytanieListyGier;
var
  listBoxItem: TListBoxItem;
  listaGier: TStringList;
  wczytano: boolean;
  i: integer;
begin
  wczytano := false;
  listaGier := TStringList.Create;
  try
    if fileExists(TPath.Combine(TPath.GetSharedDocumentsPath, 'StrumienieGry.txt')) then
      try
        listaGier.LoadFromFile(TPath.Combine(TPath.GetSharedDocumentsPath, 'StrumienieGry.txt'));
        wczytano := true;
      except
      end;
    if not wczytano then
    begin
      listaGier.Add('StarCraft: Brood War');
      listaGier.Add('StarCraft II: Heart of the Swarm');
      // listaGier.Add('League of Legends');
      // listaGier.Add('Dota 2');
      listaGier.Add('Counter-Strike: Global Offensive');
      listaGier.Add('Hearthstone: Heroes of Warcraft');
      listaGier.Add('GoldenEye 007');
      listaGier.Add('Super Mario 64');
      listaGier.Add('The Legend of Zelda: Ocarina of Time');
      listaGier.Add('Turok 2: Seeds of Evil');
      listaGier.Add('Twitch Top 25');
    end;
    ListBox1.BeginUpdate;
    for i := 0 to listaGier.Count - 1 do
    begin
      listBoxItem := TListBoxItem.Create(ListBox1);
      listBoxItem.Text := listaGier.Strings[i];
      // (aNone=0, aMore=1, aDetail=2, aCheckmark=3)
      // listBoxItem.ItemData.Accessory := TListBoxItemData.TAccessory(3);
      listBoxItem.Height := 44;
      ListBox1.AddObject(listBoxItem);
    end;
    ListBox1.EndUpdate;
  finally
    listaGier.Free;
  end;
end;

procedure TForm1.UtworzenieSkrotu;
{$IFDEF ANDROID}
var
  ShortcutIntent: JIntent;
  addIntent: JIntent;
  wIconIdentifier: integer;
  wIconResource: JIntent_ShortcutIconResource;
{$ENDIF}
begin
{$IFDEF ANDROID}
  ShortcutIntent := TJIntent.JavaClass.init(SharedActivityContext, SharedActivityContext.getClass);
  ShortcutIntent.setAction(TJIntent.JavaClass.ACTION_MAIN);
  addIntent := TJIntent.Create;
  addIntent.putExtra(TJIntent.JavaClass.EXTRA_SHORTCUT_INTENT, TJParcelable.Wrap((ShortcutIntent as ILocalObject).GetObjectID));
  addIntent.putExtra(TJIntent.JavaClass.EXTRA_SHORTCUT_NAME, StringToJString(Application.Title));
  addIntent.setAction(StringToJString('com.android.launcher.action.INSTALL_SHORTCUT'));
  wIconIdentifier := SharedActivity.getResources.getIdentifier(StringToJString('ic_launcher'), StringToJString('drawable'),
    StringToJString('com.mca64.mca64Launcher_MultiDevice'));
  wIconResource := TJIntent_ShortcutIconResource.JavaClass.fromContext(SharedActivityContext, wIconIdentifier);
  addIntent.putExtra(TJIntent.JavaClass.EXTRA_SHORTCUT_ICON_RESOURCE, TJParcelable.Wrap((wIconResource as ILocalObject).GetObjectID));
  SharedActivityContext.sendBroadcast(addIntent);
{$ENDIF}
end;

end.
