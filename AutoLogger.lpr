program AutoLogger;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Main, laz_synapse;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.ShowMainForm:=false;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

