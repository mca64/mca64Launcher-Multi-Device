unit ListaStrumieni;

interface

uses
  System.Classes, IdHTTP, IdSSLOpenSSL, System.JSON, System.SysUtils, StrUtils,
  System.DateUtils, System.TimeSpan, FMX.ListView, FMX.StdCtrls,
  Diagnostics, System.Types;

type
  TStringiTablica = array [0 .. 1] of string;

  TListaStrumieni = class(TThread)
  private
    fLiczbaWidzow, fDataUtworzeniaKonta, fLiczbaSledzacych, fNazwaKanalu, fDataAktualizacjiKanalu, fURL, fOpisKanalu, fLiczbaOdwiedzin,
      fWyswietlanaNazwaKanalu, fCzasStrumieniowania, fID, fProgram, fUplyneloKonto, fUplyneloStrumien, fKanalGra: array of String;
    fListView: TlistView;
    fBazaDanych: TStringList;
    fProgressBar: TProgressBar;
    fPomiarCzasuPobrania, fPomiarCzasuReszty: TStopWatch;
    fRozmiar: String;
    fSortujWgProgramu: boolean;
    fJezyk: integer;
    // fHinty : array of string;
    // function PobierzHinty(indeks: integer): string;
    fGra: string;
    function PobierzInformacjeTwitchAPI: boolean;
    procedure AktualizaujListView;
    function SnipealotRasaGracza(const bonjwa: string): integer;
    function ModyfikacjaInfa(const kanal: string; const j: integer): TStringiTablica;
  protected
    procedure Execute; override;
  public
    // property pHinty [indeks: integer]: string read PobierzHinty;
    constructor Create(const lv: TlistView; const bazaDanych: TStringList; const sortujWgProgramu: boolean; const jezyk: integer;
      const gra: string; const pb: TProgressBar);
  end;

implementation

uses mca64Launcher;

{ function TListaStrumieni.PobierzHinty(indeks: integer):string;
  begin
  result := fHinty[indeks];
  end; }
function TListaStrumieni.PobierzInformacjeTwitchAPI: boolean;
var
  IdHTTP: TIdHTTP;
  IdSSL: TIdSSLIOHandlerSocketOpenSSL;
  JSONv3, JSONv2: string;
  jsonObiekt: TJSONObject;
  streams: TJSONArray;
  strumien: TJSONObject;
  channel: TJSONObject;
  created_atKonto: TJSONString;
  created_atStrumien: TJSONString;
  followers: TJSONString;
  _id: TJSONString;
  name: TJSONString;
  updated_at: TJSONString;
  url: TJSONString;
  status: TJSONString;
  views: TJSONString;
  viewers: TJSONString;
  display_name: TJSONString;
  liczbaStrumieni: integer;
  i, j: integer;
  fu: TFormatSettings;
  t1, t2, t3: TDate;
  d: integer;
  game: TJSONString;
begin
  Queue(
    procedure
    begin
      fProgressBar.Visible := true;
    end);
  fPomiarCzasuPobrania.Start;
  Result := false;
  IdHTTP := TIdHTTP.Create;
  try
    IdSSL := TIdSSLIOHandlerSocketOpenSSL.Create(IdHTTP);
    IdHTTP.IOHandler := IdSSL;
    IdHTTP.Request.Accept := 'application/vnd.twitchtv.v3+json';
    IdHTTP.Request.CustomHeaders.AddValue('Client-ID', 'smb61nyd0vxmqdn9d3k735qbx41cdyg');
    JSONv3 := IdHTTP.Get('https://api.twitch.tv/kraken/streams?game=' + fGra); // StarCraft:%20Brood%20War');
    Queue(
      procedure
      begin
        fProgressBar.Value := 1;
      end);
    IdHTTP.Request.Accept := 'application/vnd.twitchtv.v2+json';
    JSONv2 := IdHTTP.Get('https://api.twitch.tv/kraken/streams?game=' + fGra); // StarCraft:%20Brood%20War');
    Queue(
      procedure
      begin
        fProgressBar.Value := 2;
      end);
    fRozmiar := (IntToStr(Round((Length(JSONv3) / 1024) + (Length(JSONv2) / 1024))) + ' kB');
  finally
    IdHTTP.Free;
    fPomiarCzasuPobrania.Stop;
    fPomiarCzasuReszty.Start;
  end;
  jsonObiekt := TJSONObject.ParseJSONValue(JSONv3) as TJSONObject;
  try
    streams := jsonObiekt.Get('streams').JsonValue as TJSONArray;
    liczbaStrumieni := streams.Count;
    SetLength(fLiczbaWidzow, liczbaStrumieni);
    SetLength(fDataUtworzeniaKonta, liczbaStrumieni);
    SetLength(fCzasStrumieniowania, liczbaStrumieni);
    SetLength(fLiczbaSledzacych, liczbaStrumieni);
    SetLength(fNazwaKanalu, liczbaStrumieni);
    SetLength(fDataAktualizacjiKanalu, liczbaStrumieni);
    SetLength(fURL, liczbaStrumieni);
    SetLength(fOpisKanalu, liczbaStrumieni);
    SetLength(fLiczbaOdwiedzin, liczbaStrumieni);
    SetLength(fWyswietlanaNazwaKanalu, liczbaStrumieni);
    SetLength(fID, liczbaStrumieni);
    SetLength(fProgram, liczbaStrumieni);
    SetLength(fUplyneloKonto, liczbaStrumieni);
    SetLength(fUplyneloStrumien, liczbaStrumieni);
    SetLength(fKanalGra, liczbaStrumieni);
    fu := TFormatSettings.Create;
    fu.ShortDateFormat := 'yyyy-MM-dd';
    fu.DateSeparator := '-';
    fu.TimeSeparator := ':';
    for i := 0 to liczbaStrumieni - 1 do
    begin
      strumien := streams.Items[i] as TJSONObject;
      viewers := strumien.Get('viewers').JsonValue as TJSONString;
      try
        game := strumien.Get('game').JsonValue as TJSONString;
        fKanalGra[i] := game.Value;
      except
        fKanalGra[i] := '';
      end;
      _id := strumien.Get('_id').JsonValue as TJSONString;
      created_atStrumien := strumien.Get('created_at').JsonValue as TJSONString;
      channel := strumien.Get('channel').JsonValue as TJSONObject;
      created_atKonto := channel.Get('created_at').JsonValue as TJSONString;
      followers := channel.Get('followers').JsonValue as TJSONString;
      name := channel.Get('name').JsonValue as TJSONString;
      updated_at := channel.Get('updated_at').JsonValue as TJSONString;
      url := channel.Get('url').JsonValue as TJSONString;
      try
        status := channel.Get('status').JsonValue as TJSONString;
        fOpisKanalu[i] := status.Value;
      except
        fOpisKanalu[i] := '';
      end;
      views := channel.Get('views').JsonValue as TJSONString;
      display_name := channel.Get('display_name').JsonValue as TJSONString;
      fLiczbaWidzow[i] := viewers.Value;
      fCzasStrumieniowania[i] := created_atStrumien.Value;
      fDataUtworzeniaKonta[i] := created_atKonto.Value;
      fLiczbaSledzacych[i] := followers.Value;
      fNazwaKanalu[i] := name.Value;
      fDataAktualizacjiKanalu[i] := updated_at.Value;
      fURL[i] := url.Value;
      fLiczbaOdwiedzin[i] := views.Value;
      fWyswietlanaNazwaKanalu[i] := display_name.Value;
      fID[i] := _id.Value;
      t1 := StrToDateTime(fDataAktualizacjiKanalu[i], fu);
      t2 := TTimeZone.Local.ToUniversalTime(Now);
      d := trunc(t2 - t1);
      if d > 0 then fUplyneloKonto[i] := (Format('%dd, %s', [d, FormatDateTime('hh''h'' nn''min'' ss''s''', Frac(t2 - t1))]))
      else fUplyneloKonto[i] := (Format('%s', [FormatDateTime('hh''h'' nn''min'' ss''s''', Frac(t2 - t1))]));
      t3 := StrToDateTime(fCzasStrumieniowania[i], fu);
      d := trunc(t2 - t3);
      if d > 0 then fUplyneloStrumien[i] := (Format('%dd, %s', [d, FormatDateTime('hh''h'' nn''min'' ss''s''', Frac(t2 - t3))]))
      else fUplyneloStrumien[i] := (Format('%s', [FormatDateTime('hh''h'' nn''min'' ss''s''', Frac(t2 - t3))]));
    end;
    // Twitch API V2 (program do strumieniowania)
    jsonObiekt.Free;
    jsonObiekt := TJSONObject.ParseJSONValue(JSONv2) as TJSONObject;
    streams := jsonObiekt.Get('streams').JsonValue as TJSONArray;
    liczbaStrumieni := streams.Count;
    for i := 0 to liczbaStrumieni - 1 do
    begin
      strumien := streams.Items[i] as TJSONObject;
      _id := strumien.Get('_id').JsonValue as TJSONString;
      for j := 0 to Length(fID) - 1 do
        if _id.Value = fID[j] then
        begin
          _id := strumien.Get('broadcaster').JsonValue as TJSONString;
          fProgram[j] := _id.Value;
        end;
    end;
    if (liczbaStrumieni > 0) and (Length(fLiczbaWidzow) > 0) then Result := true;
  except
    Result := false;
  end;
  jsonObiekt.Free;
end;

procedure TListaStrumieni.AktualizaujListView;
var
  listItem: TListViewItem;
  afreeca: boolean;
begin
  Synchronize(
    procedure
    var
      i: integer;
      temp: TStringiTablica;
      listaKanalowPrzed, listaKanalowPo: array of string;
      // nowyStrumien: boolean;
      // tekstChmurka: string;
      // strumien: TResourceStream;
    begin
      if Form1.Timer1.Enabled = false then exit;
      if Form1.ListBox1.Visible then
      begin
        fProgressBar.Value := 0;
        exit;
      end;
      Form1.fAdresy.Clear;
      fListView.Items.BeginUpdate;
      // strumien := TResourceStream.Create(hInstance, 'Bitmap_1', RT_RCDATA);
      try
        SetLength(listaKanalowPrzed, fListView.Items.Count);
        for i := 0 to fListView.Items.Count - 1 do listaKanalowPrzed[i] := fListView.Items[i].Text;
        fListView.ClearItems;
        SetLength(listaKanalowPo, Length(fNazwaKanalu));
        for i := 0 to Length(fNazwaKanalu) - 1 do
        begin
          Form1.fAdresy.Add(fURL[i]);
          // fProgressBar.Position := i;
          listItem := fListView.Items.Add;
          if fGra = 'StarCraft:%20Brood%20War' then
          begin
            if (fNazwaKanalu[i] = 'snipealot1') or (fNazwaKanalu[i] = 'snipealot2') or (fNazwaKanalu[i] = 'snipealot3') or
              (fNazwaKanalu[i] = 'snipealot4') or (fNazwaKanalu[i] = 'bgvrtc') then
            begin
              case SnipealotRasaGracza(fOpisKanalu[i]) of
                0: listItem.Bitmap.LoadFromStream(Form1.fZerg);
                1: listItem.Bitmap.LoadFromStream(Form1.fTerran);
                2: listItem.Bitmap.LoadFromStream(Form1.fToss);
                4: listItem.Bitmap.LoadFromStream(Form1.fSonic);
              end;
              listItem.Text := fOpisKanalu[i];
              afreeca := true;
            end
            else
            begin
              afreeca := false;
              temp := ModyfikacjaInfa(fNazwaKanalu[i], i);
              case StrToInt(temp[1]) of
                0: listItem.Bitmap.LoadFromStream(Form1.fZerg);
                1: listItem.Bitmap.LoadFromStream(Form1.fTerran);
                2: listItem.Bitmap.LoadFromStream(Form1.fToss);
                4: listItem.Bitmap.LoadFromStream(Form1.fSonic);
              end;
              listItem.Text := temp[0];
            end;
          end
          else
          begin
            listItem.Text := fWyswietlanaNazwaKanalu[i];
            // strumien := TResourceStream.Create(hInstance, 'Bitmap_1', RT_RCDATA);
            // try
            // listItem.Bitmap.LoadFromStream(strumien);
            // finally
            // strumien.Free;
            // end;
          end;
          listItem.Detail := fLiczbaWidzow[i] + #13#10 + fUplyneloStrumien[i];
          if afreeca then listItem.Detail := listItem.Detail + '   afreeca'
          else if fProgram[i] = 'unknown_rtmp' then listItem.Detail := listItem.Detail + '   mca64Launcher'
          else if fProgram[i] = 'obs' then listItem.Detail := listItem.Detail + '   OBS'
          else if fProgram[i] = 'xsplit' then listItem.Detail := listItem.Detail + '   XSplit'
          else if fProgram[i] = 'fme' then listItem.Detail := listItem.Detail + #13#10 + '   Adobe'
          else listItem.Detail := listItem.Detail + '   ' + fProgram[i];
          if fGra <> 'StarCraft:%20Brood%20War' then
          begin
            if fProgram[i] = 'unknown_rtmp' then listItem.Bitmap.LoadFromStream(Form1.fmca64Launcher)
            else if fProgram[i] = 'obs' then listItem.Bitmap.LoadFromStream(Form1.fOBS)
            else if fProgram[i] = 'xsplit' then listItem.Bitmap.LoadFromStream(Form1.fXSplit)
            else if fProgram[i] = 'fme' then listItem.Bitmap.LoadFromStream(Form1.fAdobe)
            else listItem.Bitmap.LoadFromStream(Form1.fSonic)
          end;

          if fGra <> '' then listItem.Detail := listItem.Detail + #13#10 + fOpisKanalu[i]
          else listItem.Detail := listItem.Detail + #13#10 + fKanalGra[i];
          // listItem.Text := listItem.Text + ' [' + fLiczbaWidzow[i] + '] ' + fUplyneloStrumien[i];
          // listItem.SubItems.Add(fLiczbaWidzow[i]);
          // listItem.SubItems.Add('');
          { if afreeca then listItem.SubItemImages[1] := 8
            else if fProgram[i] = 'unknown_rtmp' then listItem.SubItemImages[1] := 9
            else if fProgram[i] = 'obs' then listItem.SubItemImages[1] := 7
            else if fProgram[i] = 'xsplit' then listItem.SubItemImages[1] := 6
            else if fProgram[i] = 'fme' then listItem.SubItemImages[1] := 5
            else listItem.SubItemImages[1] := 4;
            listItem.SubItems.Add(IntToStr(i + 1));
            listItem.SubItems.Add(fNazwaKanalu[i]); }
          // listaKanalowPo[i] := fListView.Items[i].Text;  }
        end;
        fListView.Visible := true;
      finally
        fListView.Items.EndUpdate;
        // strumien.Free;
      end;
      // fProgressBar.Value := 0;
      // fProgressBar.Visible := false;
    end)
end;

constructor TListaStrumieni.Create(const lv: TlistView; const bazaDanych: TStringList; const sortujWgProgramu: boolean;
const jezyk: integer; const gra: string; const pb: TProgressBar);
begin
  inherited Create(false);
  FreeOnTerminate := true;
  fListView := lv;
  fBazaDanych := bazaDanych;
  fProgressBar := pb;
  fSortujWgProgramu := sortujWgProgramu;
  fJezyk := jezyk;
  if gra = 'Twitch Top 25' then fGra := ''
  else fGra := StringReplace(gra, ' ', '%20', [rfReplaceAll]);
end;

procedure TListaStrumieni.Execute;
begin
  if PobierzInformacjeTwitchAPI then AktualizaujListView;
  fPomiarCzasuReszty.Stop;
  Synchronize(
    procedure
    begin
      fProgressBar.Value := 0;
      fProgressBar.Visible := false;
      Form1.Edit1.Text := IntToStr(fPomiarCzasuPobrania.ElapsedMilliseconds) + ' + ' + IntToStr(fPomiarCzasuReszty.ElapsedMilliseconds) +
        ' ms, ' + fRozmiar + ' ' + TimeToStr(Time)
    end)
end;

function TListaStrumieni.SnipealotRasaGracza(

  const bonjwa: string): integer;
var
  gracz: string;
begin
  gracz := LowerCase(bonjwa);
  if (gracz = 'larva') or (gracz = 'killer') or (gracz = 'hero') or (gracz = 'zergman') or (gracz = 'terror') or (gracz = 'beast') or
    (gracz = 's2') or (gracz = 'zero') or (gracz = 'starcue') or (gracz = 'modesty') or (gracz = 'kwanro') or (gracz = 'cola') or
    (gracz = 'hyuk') or (gracz = 'jat.tv') or (gracz = 'saber') then Result := 0
  else if (gracz = 'hiya') or (gracz = 'mong') or (gracz = 'ssak') or (gracz = 'sea') or (gracz = 'ample') or (gracz = 'mind') or
    (gracz = 'shinee') or (gracz = 'light') or (gracz = 'dove') or (gracz = 'kkong') or (gracz = 'piano') or (gracz = 'midas') or
    (gracz = 'firebathero') or (gracz = 'icarus') or (gracz = 'boxer') then Result := 1
  else if (gracz = 'bisu') or (gracz = 'shuttle') or (gracz = 'pusan') or (gracz = 'pure') or (gracz = 'jaehoon') or (gracz = 'hint') or
    (gracz = 'eagle') or (gracz = 'mini') or (gracz = 'britney') or (gracz = 'lazy') or (gracz = 'brave') or (gracz = 'tyson') or
    (gracz = 'sky') or (gracz = 'zeus') or (gracz = 'leto') or (gracz = 'air') or (gracz = 'jangbi') or (gracz = 'tamoo') or
    (gracz = 'snow') or (gracz = 'free') or (gracz = 'hwan') or (gracz = 'yongsu') then Result := 2
  else Result := 4
end;

function TListaStrumieni.ModyfikacjaInfa(const kanal: string; const j: integer): TStringiTablica;
var
  i: integer;
  poczatekKanalu: integer;
  temp: string;
begin
  try
    for i := 0 to fBazaDanych.Count - 1 do
    begin
      poczatekKanalu := PosEx(' ', fBazaDanych.Strings[i], 4);
      temp := LowerCase(copy(fBazaDanych.Strings[i], poczatekKanalu + 1, Length(fBazaDanych.Strings[i]) - poczatekKanalu + 1));
      if temp = kanal then
      begin
        Result[0] := copy(fBazaDanych.Strings[i], 4, poczatekKanalu - 4);
        if temp = LowerCase(Result[0]) then Result[0] := fWyswietlanaNazwaKanalu[j];
        Result[1] := copy(fBazaDanych.Strings[i], 1, 1);
        exit;
      end;
    end;
    Result[0] := fWyswietlanaNazwaKanalu[j]; // + ' Dodaj mnie ';
    Result[1] := '4';
  except

  end;
end;

end.
