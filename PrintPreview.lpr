program PrintPreview;

{$mode objfpc}{$H+}

uses
  Interfaces,     // this includes the LCL widgetset
  Forms,

  Preview;

{$R *.res}

begin
  RequireDerivedFormResource:= True;
  Application.Scaled:= True;
  Application.Initialize;
  Application.CreateForm(TPreviewfm, Previewfm);
  Application.Run;
end.

