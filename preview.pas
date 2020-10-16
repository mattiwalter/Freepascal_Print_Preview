unit Preview;

{$mode delphi}

interface

uses
  Windows, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, Menus, ExtCtrls, Printers, IntfGraphics,

  Print_Preview, PatchImageDPI;

type

  { TPreviewfm }

  TPreviewfm = class(TForm)
    CopyButton: TToolButton;
    CutButton: TToolButton;
    FindDialog1: TFindDialog;
    Memo1: TMemo;
    PasteButton: TToolButton;
    PrintButton: TToolButton;
    Radiobutton1: Tradiobutton;
    RadioButton3: Tradiobutton;
    RadioButton2: Tradiobutton;
    SaveButton: TToolButton;
    StandardToolBar: TToolBar;
    StatusBar: TStatusBar;
    Exitbtn: TToolButton;
    ToolbarImages: TImageList;
    Toolbutton1: Ttoolbutton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    Toolbutton5: Ttoolbutton;
    Toolbutton6: Ttoolbutton;
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
    Procedure SetBMP_DPI(fn: String; NEW_DPI_X, NEW_DPI_Y: Integer);

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

procedure ChangeBitmapDPI(const InputFileName: string; DPI: Integer);
var
  PelsPerMeter: Integer;
  fs: TFileStream;
begin
  if DPI = 0
    then DPI:= 96; // normal screen resolution, in lack of better value.
  PelsPerMeter:= Round(DPI / 2.54 * 100); // convert DPI to DPM (dots/inch -> dots per meter)
  fs:= TFileStream.Create(InputFileName, fmOpenReadWrite or fmShareDenyNone);
  try
    fs.Position:= 38; // biXPelsPerMeter, 4 bytes, X-resolution, Pixels/meter
    fs.WriteBuffer(PelsPerMeter, 4);
    fs.Position:= 42; // biYPelsPerMeter, 4 bytes, Y-resolution, Pixels/meter
    fs.WriteBuffer(PelsPerMeter, 4);
  finally
    fs.Free;
  end;
end;

procedure TPreviewfm.PrintButtonClick(Sender: TObject);
var
  jp: TJpegImage;
  BM: TBitmap;
const
  ImgFile = 'Pic1100x1100';
  //ImgFile = '800x1130.jpg';
begin
  Screen.Cursor:= crHourGlass;
  try
    Print_Previewfm:= TPrint_Previewfm.Create(nil);
    jp:= TJpegImage.Create;
    try
      if RadioButton1.Checked
      then Print_Previewfm.Memo1.Lines.Assign(Memo1.Lines)
      else if RadioButton2.Checked
        then Print_Previewfm.MemoFileName:= TestFileName
        else   //RadioButto3.checked
        begin
          (*
          // ------ Image Quality is miserable. To be improved -------

          //A Delphi Bitmap has no DPI Info, use JPG instead
          jp:= TJpegImage.Create;
          Jp.CompressionQuality:= 100;
          BM:= TBitmap.Create;
          try
            BM.LoadFromResourceName(hinstance, ImgFile);
            jp.Assign(BM);
          Finally
            BM.Free;
          End;
          Print_Previewfm.SrcImage.Picture.Bitmap.Assign(jp);
          Print_Previewfm.SrcImage.Width:= jp.width;
          Print_Previewfm.SrcImage.Height:= jp.height;
          *)

          //Use this method for the time beeing
          BM:= TBitmap.Create;
          try
            BM.LoadFromResourceName(hinstance, ImgFile);
            BM.SaveToFile(ImgFile + '.bmp');
          Finally
            BM.Free;
          End;
          ShellExecute(0, 'open', PChar(ImgFile + '.bmp'), nil, nil, SW_SHOW);
        End;

      if RadioButton1.Checked or RadioButton2.Checked
        then Print_Previewfm.ShowModal;
    finally
      jp.Free;
    end;
  finally
    Screen.Cursor:= crDefault;
  End;
end;

Procedure TPreviewfm.SetBMP_DPI(fn: String; NEW_DPI_X, NEW_DPI_Y: Integer);
var
  imgStream: TMemoryStream;
  ext      : String;
  ok       : Boolean;
begin
  ext:= ExtractFileExt(Fn);
  imgStream:= TMemoryStream.Create;
  try
    ok:= false;
    imgStream.LoadFromFile(fn);
    ext := Lowercase(ext);
    if ext = '.bmp' then
      ok := SetDPI_BMP(imgStream, NEW_DPI_X, NEW_DPI_Y)
    else if (ext = '.tiff') or (ext = '.tif') then
      ok := SetDPI_TIF(imgStream, NEW_DPI_X, NEW_DPI_Y)
    else if (ext ='.jpg') or (ext='jpeg') then
      ok := SetDPI_JPG(imgStream, NEW_DPI_X, NEW_DPI_Y)
    else if (ext = '.png') then
      ok := SetDPI_PNG(imgStream, NEW_DPI_X, NEW_DPI_Y)
    else if (ext = '.pcx') then
      ok := SetDPI_PCX(imgStream, NEW_DPI_X, NEW_DPI_Y)
    else begin
      ShowMessage('Image type not supported');
      exit;
    end;
    if ok then
    begin
      imgStream.SaveToFile(fn);
    end else
      ShowMessage('File could not find file: ' + fn);
  finally
    imgStream.Free;
  end;
end;

end.

