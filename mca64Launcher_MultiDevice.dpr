program mca64Launcher_MultiDevice;

{$R *.dres}

uses
  System.StartUpCopy,
  FMX.Forms,
  mca64Launcher in 'mca64Launcher.pas' {Form1} ,
  ListaStrumieni in 'ListaStrumieni.pas';

{$R *.res}

begin
  czasUruchomienia.Start;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;

end.
