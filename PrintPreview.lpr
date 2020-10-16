program PrintPreview;

{$mode objfpc}{$H+}

uses
  Interfaces,
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

