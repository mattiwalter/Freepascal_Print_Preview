unit Print_Preview;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, PrintersDlgs, Printers, Buttons, Math, Types,
  LCLType;

type

  { TPrint_Previewfm }

  TPrint_Previewfm = class(TForm)
    Bottomlbl1: TLabel;
    Combobox2: Tcombobox;
    GroupBox3: TGroupBox;
    Groupbox4: Tgroupbox;
    Headerimage: Timage;
    Label8: Tlabel;
    Label7: Tlabel;
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    Memo1: Tmemo;
    Pageimg: Timage;
    PrintDialog1: TPrintDialog;
    PrinterSetupDialog: TPrinterSetupDialog;
    Progressbar1: Tprogressbar;
    Scrollbox1: Tscrollbox;
    ShowPrintBordercb: TCheckBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label5: TLabel;
    Label6: TLabel;
    Leftlbl: TLabel;
    Leftlbl1: TLabel;
    PrinterSetup: TBitBtn;
    CheckBox_header: TCheckBox;
    CheckBox_Footer: TCheckBox;
    ComboBox1: TComboBox;
    Edit1: TEdit;
    Exitbtn: TToolButton;
    Label3: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Panel1: TPanel;
    PrintButton: TToolButton;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    Rightlbl1: TLabel;
    ScrollBarBottom: TScrollBar;
    ScrollBarLeft: TScrollBar;
    ScrollBarRight: TScrollBar;
    ScrollBarTop: TScrollBar;
    PrintAllcb: TCheckBox;
    StandardToolBar: TToolBar;
    TabControl1: TTabControl;
    Timer1: TTimer;
    ToolbarImages: TImageList;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    Toplbl: TLabel;
    Toplbl1: TLabel;

    Procedure Combobox1select(Sender: Tobject);
    Procedure Combobox2select(Sender: Tobject);
    procedure LabeledEdit1KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure LabeledEdit2KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PrintAllcbClick(Sender: TObject);
    procedure PrinterSetupClick(Sender: TObject);
    procedure CheckBox_FooterChange(Sender: TObject);
    procedure CheckBox_headerChange(Sender: TObject);
    procedure ExitbtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure PrintButtonClick(Sender: TObject);
    procedure RadioButton1Change(Sender: TObject);
    procedure RadioButton2Change(Sender: TObject);
    procedure ScrollBarBottomChange(Sender: TObject);
    procedure ScrollBarLeftChange(Sender: TObject);
    procedure ScrollBarRightChange(Sender: TObject);
    procedure ScrollBarTopChange(Sender: TObject);
    procedure ShowPrintBordercb1Click(Sender: TObject);
    procedure ShowPrintBordercbChange(Sender: TObject);
    procedure TabControl1Change(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);

  private
    papermmX,
    papermmY        : Single;
    InitRun,
    InCreatePages   : Boolean;
    BM              : TBitmap;
    BMLeftmargin,
    BMTopMargin,
    BMRightMargin,
    BMBottomMargin,
    PrLeft_Margin,
    PrTop_Margin,
    PrRight_Margin,
    PrBottom_Margin,
    YPos,
    Bot             : Int64;
    DispScaleX,
    DispScaleY      : Single;
    PageStartLine   : Array of Integer;                                         //Page 1 is in PageStartLine[0]

    procedure CreatePages;
    procedure GetPaperData;
    Function BuildPage(PageNum: Integer): INteger;
    procedure PrintHeader(ToPrinter: Boolean);
    procedure PrintFooter(ToPrinter: Boolean; PgNum: Integer);
    Procedure ProgBar1(i: Integer);

  public
    MemoFileName: String;
  end;

var
  Print_Previewfm: TPrint_Previewfm;

const
  mmScale = 25.4;                                                               //mm per inch

  HeaderLine1 = 'Your Company Name Ltd.';                                       //your company name
  FooterLine1 = 'My company name';                                              //My comany name
  Footerline2 = 'Great stuff...';                                               //Supplementary text

implementation

{$R *.lfm}


Procedure Tprint_previewfm.Combobox1select(Sender: Tobject);
begin
  Printer.SetPrinter(ComboBox1.Items[ComboBox1.ItemIndex]);
  ComboBox1.Hint:= ComboBox1.Items[ComboBox1.ItemIndex];
  GetPaperData;
  CreatePages;
end;

Procedure Tprint_previewfm.Combobox2select(Sender: Tobject);
Begin
  CreatePages;
End;

procedure TPrint_Previewfm.CheckBox_FooterChange(Sender: TObject);
begin
  CreatePages;
end;

procedure TPrint_Previewfm.PrinterSetupClick(Sender: TObject);
begin
  if PrinterSetupDialog.Execute then
  begin
    If Printer.Orientation = poPortrait
      then RadioButton1.checked:= true
      else RadioButton2.checked:= true;
    ComboBox1.ItemIndex:= Printer.PrinterIndex;
    ComboBox1.Hint:= ComboBox1.Items[ComboBox1.ItemIndex];
    CreatePages;
  end;
end;

procedure TPrint_Previewfm.PrintAllcbClick(Sender: TObject);
begin
  If PrintAllcb.Checked
    then LabelEdEdit2.Text:= IntToStr(TabControl1.Tabs.Count);
end;

procedure TPrint_Previewfm.LabeledEdit1KeyUp(Sender : TObject;
                                             var Key: Word;
                                             Shift  : TShiftState);
var
  ed1, ed2: Integer;
begin
  ed1:= StrToInt(LabeledEdit1.Text);
  ed2:= StrToInt(LabeledEdit2.Text);
  Case Ord(Key) of
    VK_0..VK_9:
      begin
        if ed1 > TabControl1.Tabs.Count
          then LabeledEdit1.Text:= IntToStr(TabControl1.Tabs.Count);
        if ed1 < 1
          then LabeledEdit1.Text:= '1';
        If ed1 > ed2
          then LabeledEdit2.Text:= LabeledEdit1.Text;
      end;

    VK_Back, VK_Return, VK_Delete:
      begin
        //OK
      end

    else
      Key:= 0;
  end;
end;

procedure TPrint_Previewfm.LabeledEdit2KeyUp(Sender : TObject;
                                             var Key: Word;
                                             Shift  : TShiftState);
var
  ed1, ed2: Integer;
begin
  ed1:= StrToInt(LabeledEdit1.Text);
  ed2:= StrToInt(LabeledEdit2.Text);

  Case Ord(Key) of
    VK_0..VK_9:
      begin
        if ed2 > TabControl1.Tabs.Count
          then LabeledEdit2.Text:= IntToStr(TabControl1.Tabs.Count);
        if ed2 < ed1
          then LabeledEdit2.Text:= LabeledEdit1.Text;
      end;
  VK_Back, VK_Return, VK_Delete:
      begin
        //OK
      end

    else
      Key:= 0;
  end;
end;

procedure TPrint_Previewfm.CheckBox_headerChange(Sender: TObject);
begin
  CreatePages;
end;

procedure TPrint_Previewfm.ExitbtnClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TPrint_Previewfm.FormClose(Sender: TObject;
                                     var CloseAction: TCloseAction);
begin
  BM.Free;
end;

procedure TPrint_Previewfm.FormCreate(Sender: TObject);
var
  x: Integer;
begin
  InitRun:= true;
  Memo1.Clear;
  InCreatePages:= false;
  ScrollBarLeftChange(nil);
  ScrollBarTopChange(nil);
  ScrollBarRightChange(nil);
  ScrollBarBottomChange(nil);
  ProgBar1(0);
  BM := TBitmap.Create;

  if (Printer <> nil) and (Printer.Printers.Count > 0) then
  begin
    ComboBox1.Items:= Printer.Printers;
    Printer.PrinterIndex := -1;                                                 //-1 has the default printer
    for x:= 0 to (ComboBox1.Items.Count - 1) do
      If Printer.Printers[Printer.PrinterIndex] = ComboBox1.Items[x] then
      begin
        ComboBox1.ItemIndex:= x;
        ComboBox1.Hint:= ComboBox1.Items[ComboBox1.ItemIndex];
        Break;
      end;
  end;
  PageImg.Left:= 0;
  PageImg.Top:= 0;
  GetPaperData;
  Screen.Cursor:= crDefault;
  InitRun:= false;
end;

procedure TPrint_Previewfm.FormShow(Sender: TObject);
begin
  if MemoFileName > '' then Memo1.Lines.Loadfromfile(MemoFileName);
end;

procedure TPrint_Previewfm.FormResize(Sender: TObject);
begin
  If InitRun then Exit;
  Timer1.enabled:= true;
end;

procedure TPrint_Previewfm.Timer1Timer(Sender: TObject);
begin
  Timer1.enabled:= false;
  CreatePages;
end;

Procedure TPrint_Previewfm.ProgBar1(i: Integer);
begin
  Progressbar1.Position:= i;
  Label8.Caption:= IntToStr(i);
end;

procedure TPrint_Previewfm.PrintButtonClick(Sender: TObject);
var
  n, Pg,
  MaxLine,
  Ti, Tb, i : Integer;
  S         : String;
  ProgStep  : Single;
begin
  PrLeft_Margin:= Round((ScrollBarLeft.Position / mmScale) * Printer.XDPI);     //Twips
  PrTop_Margin:= Round((ScrollBarTop.Position / mmScale) * Printer.YDPI);
  PrRight_Margin:= Round((ScrollBarRight.Position / mmScale) * Printer.XDPI);
  PrBottom_Margin:= Round((ScrollBarBottom.Position / mmScale) * Printer.YDPI);

  Ti:= Printer.PageWidth - PrLeft_Margin - PrRight_Margin;                      //Twips
  Printer.Title:= Application.Title;  //Print job MUST have a title, otherwise will not print!!

  If PrintAllcb.Checked then
  begin
    Pg:= 1;
    n:= 0;
    MaxLine:= Memo1.Lines.Count;                                                //last line number
  end
  else
  begin
    Pg:= StrToInt(LabeledEdit1.Text);
    n:= PageStartLine[StrToInt(LabeledEdit1.Text) - 1];
    If TabControl1.Tabs.Count < 2
      then MaxLine:= Memo1.Lines.Count
      else
      begin
        MaxLine:= PageStartLine[StrToInt(LabeledEdit2.Text) - 1] +              //last line number
                  (PageStartLine[1] - PageStartLine[0]);
        if MaxLine > Memo1.Lines.Count then MaxLine:= Memo1.Lines.Count;
      end;
  end;
  Screen.Cursor:= crHourglass;
  try
    ProgStep:= 100.0 / TabControl1.Tabs.Count;
  except
    //
  end;
  ProgBar1(0);   //%
  Printer.BeginDoc;
  try
    Printer.Canvas.Font.Name:= Memo1.Font.Name;
    Printer.Canvas.Font.Size:= Memo1.Font.Size;
    Printer.Canvas.Font.Color:= clBlack;
    While n < MaxLine do
    begin
      If CheckBox_Header.Checked
        then PrintHeader(true)
        else YPos:= PrTop_Margin;

      If CheckBox_Footer.Checked
        then PrintFooter(true, Pg)
        else Bot:= Printer.PageHeight - prBottom_Margin;

      While (YPos - Printer.Canvas.Font.Height) < Bot do
      begin
        If n >= Memo1.Lines.Count then Break;
        S:= Memo1.Lines[n];
        Tb:= Printer.Canvas.TextWidth(S);

        If Ti < Tb then                                                         //If line is longer than page width
        begin
          i:= Length(S);
          Repeat
            While (Tb > Ti) and (i > 0) do                                      //try to shorten it
              if S[i] = ' ' then Break else Dec(i);                             //find space character startting at line end

            if i > 0 then                                                       //space char found
            begin
              Tb:= Printer.Canvas.TextWidth(Copy(S, 1, i));
              If Tb > Ti
              then                                                              //line is still too long
                Dec(i)
              else
              begin
                Printer.Canvas.TextOut(PrLeft_Margin, YPos, Copy(S, 1, i));
                Inc(Ypos, Abs(Round(1.2 * Printer. Canvas.Font.Height)));       //Increase the line position to next line
                S:= Copy(S, i + 1, Length(S));                                  //cut off printed portion of string
                if (S > '') and (S[length(S)] = ' ')
                  then  S:= Copy(S, 1, Length(S)-1);                            //cut off trailing blank

                i:= Length(S);
                Tb:= Printer.Canvas.TextWidth(S);
              end;
            end;
          until i = 0;
        end
        else
        begin
          Printer.Canvas.TextOut(PrLeft_Margin, YPos, S);
          Inc(Ypos, Abs(Round(1.2 * Printer.Canvas.Font.Height)));              //Increase the line position to next line
        end;
        Inc(n);
      end;
      if n < MaxLine then
      begin
        printer.NewPage;
        Inc(Pg);
        ProgBar1(Round(Pg * ProgStep));
      end;
    end;
  finally
    Printer.EndDoc;
  end;
  Screen.Cursor:= crDefault;
  ProgBar1(0);
end;

procedure TPrint_Previewfm.GetPaperData;
begin
  papermmX := Round((Printer.PageWidth div Printer.XDPI) * mmScale);            //page width in mm
  papermmY := Round((Printer.PageHeight div Printer.YDPI) * mmScale);           //page height in mm
  Label3.Caption:= Format('%0.0fmm x %0.0fmm',[papermmX, papermmY]);
  Edit1.Text:= printer.PaperSize.PaperName;
end;

procedure TPrint_Previewfm.RadioButton1Change(Sender: TObject);
begin
  Printer.Orientation:= poPortrait;
  If InitRun then Exit;
  GetPaperData;
  CreatePages;
end;

procedure TPrint_Previewfm.RadioButton2Change(Sender: TObject);
begin
  Printer.Orientation:= poLandscape;
  If InitRun then Exit;
  GetPaperData;
  CreatePages;
end;

procedure TPrint_Previewfm.PrintHeader(ToPrinter: Boolean);
var
  w, h,
  y      : Integer;
  k,
  ZoomPct: Single;
begin
  if ToPrinter
    then
    begin
      Y:= PrTop_Margin;
      Printer.Canvas.Font.Size:= 14;

      ZoomPct:= HeaderImage.Picture.Bitmap.Width /
                (BM.Width - BMLeftMargin - BMRightMargin);
      //right aligned Image
      k  := HeaderImage.Picture.Bitmap.Height / HeaderImage.Picture.Bitmap.Width;
      w := Round(Printer.PageWidth * ZoomPct);
      h := Round(w * k);
      if h > Printer.PageHeight then
      begin
        k := 1.0 / k;
        h := Round(Printer.PageHeight * ZoomPct);
        w := Round(h * k);
      end;
      Printer.Canvas.StretchDraw(Rect(PrLeft_Margin,
                                      PrTop_Margin,
                                      PrLeft_Margin + w,
                                      PrTop_Margin + h),
                                      HeaderImage.Picture.Graphic);
      //Header Text Line 1
      Printer.Canvas.TextOut(PrLeft_Margin + Trunc(1.05 * w), y, HeaderLine1);

      //Goto next line
      Inc(y, Abs(Round(1.2 * Printer.Canvas.Font.Height)));
      Printer.Canvas.Font.Size:= Memo1.Font.Size;
      //Print Text line 2
      Printer.Canvas.TextOut(PrLeft_Margin + Trunc(1.05 * w), y,
                             ExtractFileName(MemoFileName));
      //print separator line a bit below text line 2 or graphic
      Inc(y, Abs(Round(1.3 * Printer.Canvas.Font.Height)));
      //which is larger??
      y:= Max(y, PrTop_Margin + h +
                 Trunc(Abs(0.1 * Printer.Canvas.Font.Height)));
      Printer.Canvas.Line(PrLeft_Margin, y,
                          Printer.PageWidth - PrRight_Margin, y);
      //Starting Y-position of Body text
      YPos:= y + Trunc(0.1 * Printer.Canvas.Font.Height);
    end
    else
    begin
      Y:= BMTopMargin;

      //Print logo
      BM.Canvas.Draw(BMLeftMargin, BMTopMargin, HeaderImage.Picture.Graphic);

      //Header Text Line 1
      BM.Canvas.Font.Size:= 14;
      Bm.Canvas.TextOut(BMLeftMargin + HeaderImage.Picture.Bitmap.Width + 5,
                        y, HeaderLine1);
      //Goto next line
      Inc(y, Abs(Round(1.2 * Bm.Canvas.Font.Height)));
      BM.Canvas.Font.Size:= Memo1.Font.Size;
      //Print file name
      Bm.Canvas.TextOut(BMLeftMargin + HeaderImage.Picture.Bitmap.Width + 5, y,
                        ExtractFileName(MemoFileName));
      //print separator line a bit below Text line 2
      Inc(y, Abs(Round(1.3 * BM.Canvas.Font.Height)));
      //which position is larger??
      y:= Max(y, BMTopMargin + HeaderImage.Picture.Graphic.Height +
                 Trunc(Abs(0.1 * BM.Canvas.Font.Height)));
      BM.Canvas.Line(BMLeftMargin, y, BM.Width - BMRightMargin, y);
      //Starting Y-position of Body text
      YPos:= y + Trunc(Abs(0.1 * BM.Canvas.Font.Height));
    end;
end;

procedure TPrint_Previewfm.PrintFooter(ToPrinter: Boolean; PgNum: Integer);
var
  S   : String;
  y   : Int64;
  PixY: Single;
begin
  if ToPrinter
    then
    begin
      PixY:= Printer.PageHeight / BM.Height;

      y:= Printer.PageHeight - PrBottom_Margin;
      Dec(y, Trunc(5 * PixY));

      //"Great stuff" right aligned on second line
      Dec(y, Abs(Round(1.2 * Printer.Canvas.Font.Height)));
      Printer.Canvas.TextOut(Printer.PageWidth - PrRight_Margin -
                             Printer.Canvas.TextWidth(FooterLine2), y,
                             FooterLine2);

      //Page number in center of first line
      Dec(y, Abs(Round(1.2 * Printer.Canvas.Font.Height)));
      S:= '-' + IntToStr(PgNum + 1) + '-';
      Printer.Canvas.TextOut((Printer.PageWidth - PrRight_Margin -
                              Printer.Canvas.TextWidth(S)) div 2, y, S);

      //CompanyName right aligned on first line
      Printer.Canvas.TextOut(Printer.PageWidth - PrRight_Margin -
                             Printer.Canvas.TextWidth(FooterLine1), y,
                             FooterLine1);
      //Horizontal line
      Dec(y, Trunc(5 * PixY));
      Printer.Canvas.Line(PrLeft_Margin, y, Printer.PageWidth -
                          PrRight_Margin, y);

      Dec(y, Trunc(5 * PixY));
      Bot:= y;
    end
    else
    begin
      y:= Bm.Height - BMBottomMargin;

      //"Great stuff" right aligned on second line
      Dec(y, Abs(Round(1.2 * Bm.Canvas.Font.Height)));
      Bm.Canvas.TextOut(BM.Width - BMRightMargin -
                        Bm.Canvas.TextWidth(FooterLine2), y, FooterLine2);

      //Page number in center of first line
      Dec(y, Abs(Round(1.2 * Bm.Canvas.Font.Height)));
      S:= '-' + IntToStr(PgNum + 1) + '-';
      Bm.Canvas.TextOut((BM.Width - BMRightMargin -
                         Bm.Canvas.TextWidth(S)) div 2, y, S);

      //CompanyName right aligned on first line
      Bm.Canvas.TextOut(BM.Width - BMRightMargin -
                        Bm.Canvas.TextWidth(FooterLine1), y, FooterLine1);

      //Horizontal line
      Dec(y, 5);
      BM.Canvas.Line(BMLeftMargin, y, BM.Width - BMRightMargin, y);

      Dec(y, 5);
      Bot:= y;
    end;
end;

procedure TPrint_Previewfm.CreatePages;
var
  n, Pg,
  OldTabIdx: Integer;
begin
  if InCreatePages then Exit;

  BMLeftMargin:= Round((ScrollBarLeft.Position / mmScale) *
                       Screen.PixelsPerInch);                                   //Pixel
  BMTopMargin:= Round((ScrollBarTop.Position / mmScale) *
                      Screen.PixelsPerInch);
  BMRightMargin:= Round((ScrollBarRight.Position / mmScale) *
                        Screen.PixelsPerInch);
  BMBottomMargin:= Round((ScrollBarBottom.Position / mmScale) *
                         Screen.PixelsPerInch);

  if TabControl1.Tabs.Count > 0 then OldTabIdx:= TabControl1.TabIndex;          //Remember current tab

  TabControl1.Tabs.Clear;
  Pg:= 0;
  Setlength(PageStartLine, 1);
  n:= 0;
  PageStartLine[Pg]:= n;
  try
    BM.Width:= Round((papermmX / mmscale) * Screen.PixelsPerInch);              //Pixel
    BM.Height:= Round((papermmY / mmScale) * Screen.PixelsPerInch);

    While n < Memo1.Lines.Count do                                              //While not bottom of page...
    begin
      n:= BuildPage(Pg);
      TabControl1.Tabs.Add('Page ' + IntToStr(Pg + 1));
      Inc(Pg);
      Setlength(PageStartLine, Pg + 1);
      PageStartLine[length(PageStartLine) - 1]:= n;
    end;
  finally
    if TabControl1.Tabs.Count > 0 then
    begin
      TabControl1.TabIndex:= OldTabIdx;
      BuildPage(TabControl1.TabIndex);                                          //display first page
    end;
    LabeledEdit1.Text:= '1';
    LabeledEdit2.Text:= IntToStr(Pg);

    InCreatePages:= false;
  end;
  PrintButton.enabled:= (Memo1.Lines.Count > 0);                                //Print Text
end;

Function TPrint_Previewfm.BuildPage(PageNum: Integer): Integer;
var
  n, Ti, Tb: Int64;
  i        : Integer;
  S        : String;
begin
  try
    BM.Canvas.Brush.Color := clwhite;                                           //Background color
    BM.Canvas.Brush.Style := bsSolid;
    BM.Canvas.Pen.width:= 1;
    BM.Canvas.Pen.Color:= clBlack;
    BM.Canvas.Pen.Style:= psSolid;

    BM.Canvas.Rectangle(Rect(0, 0, BM.Width, BM.Height));                       //draw bitmap background

    Ti:= BM.Width - BMLeftMargin - BMRightMargin;                               //Pixel

    BM.canvas.Font.Color:= clblack;

    Case ComboBox2.ItemIndex of
       0: begin  //25%
            PageImg.Height:= BM.Height div 4;
            PageImg.Width:= BM.Width div 4;

            PageImg.Picture.Bitmap.Width:= PageImg.Width;
            PageImg.Picture.Bitmap.Height:= PageImg.Height;
          end;

       1: begin  //50%
            PageImg.Height:= BM.Height div 2;
            PageImg.Width:= BM.Width div 2;

            PageImg.Picture.Bitmap.Width:= PageImg.Width;
            PageImg.Picture.Bitmap.Height:= PageImg.Height;
            (*
            If PageImg.Width > ScrollBox1.ClientWidth
              then ScrollBox1.ClientWidth:= PageImg.Width;
            If PageImg.Height > ScrollBox1.ClientHeight
              then ScrollBox1.ClientHeight:= PageImg.Height;
            *)
          end;

       2: begin  //75%
            PageImg.Height:= (BM.Height div 4) * 3;
            PageImg.Width:= (BM.Width div 4) * 3;

            PageImg.Picture.Bitmap.Width:= PageImg.Width;
            PageImg.Picture.Bitmap.Height:= PageImg.Height;
          end;

       3: begin  //Original
             PageImg.Height:= BM.Height;
            PageImg.Width:= BM.Width;

            PageImg.Picture.Bitmap.Width:= PageImg.Width;
            PageImg.Picture.Bitmap.Height:= PageImg.Height;
          end;

       else
          begin  //Einpassen
            PageImg.Height:= ScrollBox1.ClientHeight;
            PageImg.Width:= Round(PageImg.Height * (Bm.Width / BM.Height));

            PageImg.Picture.Bitmap.Width:= PageImg.Width;
            PageImg.Picture.Bitmap.Height:= PageImg.Height;

            If PageImg.Width > ScrollBox1.ClientWidth
              then ScrollBox1.ClientWidth:= PageImg.Width;
            If PageImg.Height > ScrollBox1.ClientHeight
              then ScrollBox1.ClientHeight:= PageImg.Height;
          end;
    end;

    DispScaleX:= PageImg.Width/ BM.Width;
    DispScaleY:= PageImg.Height / BM.Height;

    n:= PageStartLine[PageNum];
    i:= Memo1.Lines.Count;

    While n < Memo1.Lines.Count do
    begin
      If CheckBox_Header.Checked
        then PrintHeader(false)
        else YPos:= BMTopMargin;

      If CheckBox_Footer.Checked
        then PrintFooter(false, TabControl1.TabIndex)
        else Bot:= Bm.Height - BMBottomMargin;

      While (YPos - Bm.Canvas.Font.Height) < Bot do
      begin
        If n >= Memo1.Lines.Count then Break;
        S:= Memo1.Lines[n];
        Tb:= Bm.Canvas.TextWidth(S);

        If Ti < Tb then                                                         //If line is longer than page width
        begin
          i:= Length(S);
          Repeat
            While (Tb > Ti) and (i > 0) do                                      //try to shorten it
              if S[i] = ' ' then Break else Dec(i);                             //find space character startting at line end

            if i > 0 then                                                       //space char found
            begin
              Tb:= Bm.Canvas.TextWidth(Copy(S, 1, i));
              If Tb > Ti
              then                                                              //line is still too long
                Dec(i)
              else
              begin
                Bm.Canvas.TextOut(BMLeftMargin, YPos, Copy(S, 1, i));
                Inc(Ypos, Abs(Round(1.2 * Bm.Canvas.Font.Height)));             //Increase the line position to next line
                S:= Copy(S, i + 1, Length(S));                                  //cut off printed portion of string
                if (S > '') and (S[length(S)] = ' ')
                  then  S:= Copy(S, 1, Length(S)-1);                            //cut off trailing blank

                i:= Length(S);
                Tb:= Bm.Canvas.TextWidth(S);
              end;
            end;
          until i = 0;
        end
        else
        begin
          Bm.Canvas.TextOut(BMLeftMargin, YPos, S);
          Inc(Ypos, Abs(Round(1.2 * Bm.Canvas.Font.Height)));                   //Increase the line position to next line
        end;
        Inc(n);
      end;
      Break;
    end;
  finally
    PageImg.Picture.Bitmap.Canvas.StretchDraw(
                                Rect(0, 0, PageImg.Width, PageImg.Height), BM); //Scale BM to PageImg size

    if ShowPrintBordercb.checked then
    begin
      PageImg.Canvas.Pen.Mode := pmCopy;                                        //Draw print border
      PageImg.Canvas.Pen.Color:= clRed;
      PageImg.Canvas.Pen.Style:= psDot;
      PageImg.Canvas.Brush.Style := bsClear;
      PageImg.Canvas.Rectangle(
                       Rect(Round(BMLeftmargin * DispScaleX),
                       Round(BMTopmargin * DispScaleY),
                       PageImg.Width - Round(BMRightmargin * DispScaleX),
                       PageImg.Height - Round(BMBottommargin * DispScaleY)));
    end;
  end;
  Result:= n;
end;

procedure TPrint_Previewfm.ScrollBarBottomChange(Sender: TObject);
begin
  Bottomlbl1.caption:= IntToStr(ScrollBarBottom.Position) + 'mm';
  Timer1.Enabled:= true;
end;

procedure TPrint_Previewfm.ScrollBarLeftChange(Sender: TObject);
begin
  Leftlbl1.caption:= IntToStr(ScrollBarLeft.Position) + 'mm';
  Timer1.Enabled:= true;
end;

procedure TPrint_Previewfm.ScrollBarRightChange(Sender: TObject);
begin
  Rightlbl1.caption:= IntToStr(ScrollBarRight.Position) + 'mm';
  Timer1.Enabled:= true;
end;

procedure TPrint_Previewfm.ScrollBarTopChange(Sender: TObject);
begin
  Toplbl1.caption:= IntToStr(ScrollBarTop.Position) + 'mm';
  Timer1.Enabled:= true;
end;

procedure TPrint_Previewfm.ShowPrintBordercb1Click(Sender: TObject);
begin

end;

procedure TPrint_Previewfm.ShowPrintBordercbChange(Sender: TObject);
begin
  BuildPage(TabControl1.TabIndex);
end;

procedure TPrint_Previewfm.TabControl1Change(Sender: TObject);
begin
  BuildPage(TabControl1.TabIndex);
end;

end.

