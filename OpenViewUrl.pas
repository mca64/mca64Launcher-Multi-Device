unit OpenViewUrl;

// Znalezione na http://delphi.org/2013/10/sending-a-url-to-another-app-on-android-and-ios-with-delphi-xe5/
// Posted by Jim McKeeth on 15-Oct-2013
// plus dodanie wsparcia dla Windowsa
interface

// URLEncode is performed on the URL
// so you need to format it   protocol://path
function OpenURL(const URL: string; const DisplayError: Boolean = False): Boolean;

implementation

uses
  IdURI, SysUtils, Classes, FMX.Dialogs,
{$IFDEF ANDROID}
  FMX.Helpers.Android, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Net, Androidapi.JNI.JavaTypes, Androidapi.Helpers;
{$ELSE}
{$IFDEF IOS}
iOSapi.Foundation, FMX.Helpers.iOS,
{$ELSE}
{$IFDEF MSWINDOWS}
  ShellAPI, Windows;
{$ENDIF MSWINDOWS}
{$ENDIF IOS}
{$ENDIF ANDROID}

function OpenURL(const URL: string; const DisplayError: Boolean = False): Boolean;

{$IFDEF MSWINDOWS}
begin
  if ShellExecute(0, PChar('open'), PChar(URL), nil, nil, SW_SHOWNORMAL) >= 32 then Exit(True)
  else
  begin
    if DisplayError then showmessage('Error: Opening "' + URL + '" not supported.');
    Exit(False);
  end;
end;

{$ELSE}
{$IFDEF ANDROID}

var
  intent: JIntent;
begin
  // There may be an issue with the geo: prefix and URLEncode.
  // will need to research
  intent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW, TJnet_Uri.JavaClass.parse(StringToJString(TIdURI.URLEncode(URL))));
  try
    SharedActivity.startActivity(intent);
    Exit(True);
  except
    on e: Exception do
    begin
      if DisplayError then showmessage('Error: ' + e.Message);
      Exit(False);
    end;
  end;
end;
{$ELSE}
{$IFDEF IOS}

var
  NSU: NSUrl;
begin
  // iOS doesn't like spaces, so URL encode is important.
  NSU := StrToNSUrl(TIdURI.URLEncode(URL));
  if SharedApplication.canOpenURL(NSU) then Exit(SharedApplication.OpenURL(NSU))
  else
  begin
    if DisplayError then showmessage('Error: Opening "' + URL + '" not supported.');
    Exit(False);
  end;
end;
{$ELSE}

begin
  raise Exception.Create('Not supported!');
end;
{$ENDIF MSWINDOWS}
{$ENDIF IOS}
{$ENDIF ANDROID}

end.
