unit Preview;

{$mode delphi}

interface

uses
  Windows, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, Menus, ExtCtrls, Printers,

  Print_Preview;

type

  { TPreviewfm }

  TPreviewfm = class(TForm)
    CopyButton: TToolButton;
    CutButton: TToolButton;
    FindDialog1: TFindDialog;
    Memo1: TMemo;
    PasteButton: TToolButton;
    PrintButton: TToolButton;
    SaveButton: TToolButton;
    StandardToolBar: TToolBar;
    StatusBar: TStatusBar;
    Exitbtn: TToolButton;
    ToolbarImages: TImageList;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    UndoButton: TToolButton;

    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
    procedure Memo1Click(Sender: TObject);
    procedure Memo1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ExitbtnClick(Sender: TObject);
    procedure PrintButtonClick(Sender: TObject);

  private
    procedure ShowCursorPos;

  public

  end;

var
  Previewfm: TPreviewfm;

const
  TestFileName = 'Testdocument.txt';

implementation

{$R *.lfm}

{ TPreviewfm }

procedure TPreviewfm.ShowCursorPos;
begin
  StatusBar.Panels[1].Text:= IntToStr(Memo1.CaretPos.y) + ':' +
                             IntToStr(Memo1.CaretPos.x);
end;

procedure TPreviewfm.Memo1Change(Sender: TObject);
begin
  ShowCursorPos;
end;

procedure TPreviewfm.FormCreate(Sender: TObject);
begin
  Memo1.Lines.LoadFromFile(TestFileName);
  StatusBar.Panels[2].Text:= TestFileName;
  ShowCursorPos;
end;

procedure TPreviewfm.FormActivate(Sender: TObject);
begin
  PrintButton.enabled:= Printer.Printers.Count > 0;
end;

procedure TPreviewfm.Memo1Click(Sender: TObject);
begin
  ShowCursorPos;
end;

procedure TPreviewfm.Memo1KeyDown(Sender : TObject;
                                  var Key: Word;
                                  Shift  : TShiftState);
begin
  ShowCursorPos;
end;

procedure TPreviewfm.ExitbtnClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TPreviewfm.PrintButtonClick(Sender: TObject);
begin
  Screen.Cursor:= crHourGlass;
  try
    Print_Previewfm:= TPrint_Previewfm.Create(nil);
    try
      (* Method 1:
            Print_Previewfm.Memo1.Lines.Assign(Memo1.Lines);

         Method 2:
            Print_Previewfm.MemoFileName:= <yourfilename>.txt';
      *)
      Print_Previewfm.MemoFileName:= TestFileName;
      Print_Previewfm.ShowModal;
    finally
      //
    end;
  finally
    Screen.Cursor:= crDefault;
  End;
end;

end.

