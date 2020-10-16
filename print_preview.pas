unit Print_Preview;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, PrintersDlgs, Printers, Buttons, Math, Types, LCLType;

type

  { TPrint_Previewfm }

  TPrint_Previewfm = class(TForm)
    Bitbtn1: Tbitbtn;
    Bitbtn2: Tbitbtn;
    Bottomlbl1: TLabel;
    Combobox2: Tcombobox;
    GroupBox3: TGroupBox;
    Groupbox4: Tgroupbox;
    Groupbox5: Tgroupbox;
    Groupbox6: Tgroupbox;
    Headerimage: Timage;
    Label8: Tlabel;
    Labelededit1: Tlabelededit;
    Labelededit2: Tlabelededit;
    Memo1: Tmemo;
    Pageimg: Timage;
    Printallcb: Tcheckbox;
    SrcImage: Timage;
    PrintDialog1: TPrintDialog;
    PrinterSetupDialog: TPrinterSetupDialog;
    Progressbar1: Tprogressbar;
    Scrollbox1: Tscrollbox;
    Scrollbox2: Tscrollbox;
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
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    Rightlbl1: TLabel;
    ScrollBarBottom: TScrollBar;
    ScrollBarLeft: TScrollBar;
    ScrollBarRight: TScrollBar;
    ScrollBarTop: TScrollBar;
    Splitter1: Tsplitter;
    StandardToolBar: TToolBar;
    TabControl1: TTabControl;
    Timer1: TTimer;
    ToolbarImages: TImageList;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    Toplbl: TLabel;
    Toplbl1: TLabel;

    Procedure Bitbtn2click(Sender: Tobject);
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
    Procedure Splitter1moved(Sender: Tobject);
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
    YPos,
    Bot, Pg         : Int64;
    PageStartLine   : Array of Integer;                                         //Page 1 is in PageStartLine[0]
    PreviewGrBox    : Array of TGroupBox;
    img             : Array of TImage;

    procedure CreatePages;
    procedure GetPaperData;
    Function BuildPage(PageNum: Integer): Integer;
    procedure PrintHeader;
    procedure PrintFooter(PgNum: Integer);
    procedure PreviewGrBoxClick(Sender: TObject);
    procedure HighlightPrvBox(Idx: Integer);

  public
    MemoFileName: String;
  end;

var
  Print_Previewfm: TPrint_Previewfm;

const
  mmScale = 25.4;                                                               //mm per inch

  HeaderLine1 = 'Header Line 1';
  //Header Line 2 is the file name
  FooterLine1 = 'Footer Line 1';
  Footerline2 = 'Footer Line 1';
  ScrBarWidth = 25;

implementation

{$R *.lfm}

Procedure Tprint_previewfm.Combobox1select(Sender: Tobject);
begin
  Printer.SetPrinter(ComboBox1.Items[ComboBox1.ItemIndex]);
  ComboBox1.Hint:= ComboBox1.Items[ComboBox1.ItemIndex];
  GetPaperData;
  CreatePages;
end;

Procedure Tprint_previewfm.Bitbtn2click(Sender: Tobject);
Begin   //Print current page
  LabelEdEdit1.Text:= IntToStr(TabControl1.TabIndex + 1);
  LabelEdEdit2.Text:= LabelEdEdit1.Text;
  PrintButtonClick(Sender);
  If PrintAllcb.Checked then PrintAllcbClick(Sender);                           //Reset print from page to page to setting before "print current"
End;

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
  LabeledEdit1.Enabled:= not PrintAllcb.Checked;
  LabeledEdit2.Enabled:= not PrintAllcb.Checked;

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
  MemoFileName:= '';
  SrcImage.width:= 0;

  InCreatePages:= false;
  ScrollBarLeftChange(nil);
  ScrollBarTopChange(nil);
  ScrollBarRightChange(nil);
  ScrollBarBottomChange(nil);

  BM := TBitmap.Create;
  BM.Canvas.Font.Name:= Memo1.Font.Name;
  Printer.Canvas.Font.Name:= Memo1.Font.Name;

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

procedure TPrint_Previewfm.PrintButtonClick(Sender: TObject);
var
  n, a, e,
  OldTab   : Integer;
  ProgStep : Single;
  OldBorder: Boolean;
begin
  OldTab:= TabControl1.TabIndex;
  OldBorder:= ShowPrintBordercb.Checked;
  //Print job MUST have a title, otherwise will not print
  Printer.Title:= Application.Title;
  try
    ProgStep:= 100.0 / TabControl1.Tabs.Count;
  except
    //
  end;
  GroupBox5.Visible:= true;
  Screen.Cursor:= crHourglass;
  Printer.BeginDoc;
  try
    a:= (StrToInt(LabeledEdit1.Text) -1);
    e:= (StrToInt(LabeledEdit2.Text) -1);
    For n:= a to e do
    begin
      Progressbar1.Position:= Round((n + 1) * ProgStep);
      Label8.Caption:= IntToStr(n + 1);
      Application.ProcessMessages;
      BuildPage(n);
      Printer.Canvas.StretchDraw(Rect(0, 0,
                                      Printer.PageWidth,
                                      Printer.PageHeight), BM);
      if n < e then Printer.NewPage;
      if Printer.Aborted then Break;
    End;
  finally
    Printer.EndDoc;
    GroupBox5.Visible:= false;
    ShowPrintBordercb.Checked:= OldBorder;
    TabControl1.TabIndex:= OldTab;
    BuildPage(TabControl1.TabIndex);
  end;
  Screen.Cursor:= crDefault;
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

procedure TPrint_Previewfm.PrintHeader;
var
  y, n: Integer;
begin
  Y:= BMTopMargin;

  BM.Canvas.Draw(BMLeftMargin, BMTopMargin, HeaderImage.Picture.Graphic);       //logo

  BM.Canvas.Font.Size:= 14;                                                     //Large
  n:= BMLeftMargin + HeaderImage.Width + BM.Canvas.TextWidth('H');
  Bm.Canvas.TextOut(n, y, HeaderLine1);

  Inc(y, Abs(Round(1.2 * Bm.Canvas.Font.Height)));                              //next line
  BM.Canvas.Font.Size:= Memo1.Font.Size;                                        //Standard size

  Bm.Canvas.TextOut(n, y, ExtractFileName(MemoFileName));

  //which position is further down ?
  y:= Max(y + Abs(BM.Canvas.Font.Height),                                       //next line                                                                //next line
          Round(BMTopMargin + HeaderImage.Height));                             //graphic bottom

  //print horizontal line
  Inc(y, Abs(Round(0.5 * BM.Canvas.Font.Height)));
  BM.Canvas.Line(BMLeftMargin, y, BM.Width - BMRightMargin, y);                 //horizontal line

  YPos:= y + Abs(BM.Canvas.Font.Height);                                        //Starting position of Body text
end;

procedure TPrint_Previewfm.PrintFooter(PgNum: Integer);
var
  S: String;
  y: Int64;
begin
  y:= Bm.Height - BMBottomMargin +
      Round(1.2 * Bm.Canvas.Font.Height);                                       //Height is negative

  Bm.Canvas.TextOut(BM.Width - BMRightMargin -
                    Bm.Canvas.TextWidth(FooterLine2), y, FooterLine2);          //right aligned

  Dec(y, Abs(Round(1.2 * Bm.Canvas.Font.Height)));

  Bm.Canvas.TextOut(BM.Width - BMRightMargin -
                    Bm.Canvas.TextWidth(FooterLine1), y, FooterLine1);          //right aligned

  //Page number centered on Footer line 1
  S:= '-' + IntToStr(PgNum + 1) + '-';
  Bm.Canvas.TextOut((BM.Width - BMRightMargin -
                     Bm.Canvas.TextWidth(S)) div 2, y, S);

  Dec(y, Abs(Round(0.5 * Bm.Canvas.Font.Height)));
  BM.Canvas.Line(BMLeftMargin, y, BM.Width - BMRightMargin, y);                 //Horizontal line

  Bot:= y + Round(0.5 * Bm.Canvas.Font.Height);                                 //height is negative
end;

procedure TPrint_Previewfm.HighlightPrvBox(Idx: Integer);
var
  n: Integer;
begin
  for n:= 0 to high(PreviewGrBox) do PreviewGrBox[n].Color:= clBtnFace;         //clear highlight color
  PreviewGrBox[Idx].Color:= clMoneygreen;
end;

procedure TPrint_Previewfm.PreviewGrBoxClick(Sender: TObject);
var
  p: Integer;
begin
  if (Sender is TImage) then
  begin
    p:= TImage(Sender).Tag;
    BuildPage(p);
    TabControl1.TabIndex:= p;
    HighlightPrvBox(p);
  End;
end;

procedure TPrint_Previewfm.TabControl1Change(Sender: TObject);
begin
  BuildPage(TabControl1.TabIndex);
  HighlightPrvBox(TabControl1.TabIndex);
end;

procedure TPrint_Previewfm.CreatePages;
var
  Factor, n, OldTabIdx: Integer;

  Procedure AdjPreviewGrBox;
  begin
    Factor:= Trunc((Splitter1.Left - ScrBarWidth) *
                           (papermmY / papermmX));
    SetLength(PreviewGrBox, Pg + 1);
    PreviewGrBox[Pg]:= TGroupBox.Create(nil);
    PreviewGrBox[Pg].Parent:= ScrollBox2;
    PreviewGrBox[Pg].ParentColor:= false;

    SetLength(Img, Pg + 1);
    Img[Pg]:= TImage.Create(nil);
    Img[Pg].Parent:= PreviewGrBox[Pg];
    Img[Pg].Align:= alClient;
    Img[Pg].OnClick:= @PreviewGrBoxClick;
    Img[Pg].Tag:= Pg;

    PreviewGrBox[Pg].Caption:= IntToStr(Pg + 1);
    PreviewGrBox[Pg].ClientHeight:= Factor;
    PreviewGrBox[Pg].ClientWidth:= Splitter1.Left - ScrBarWidth;
    PreviewGrBox[Pg].Top:= Pg * PreviewGrBox[Pg].Height;
    PreviewGrBox[Pg].Color:= clBtnFace;
    PreviewGrBox[Pg].Font.Size:= 10;
    PreviewGrBox[Pg].Font.Style:= [];
    PreviewGrBox[Pg].Tag:= Pg;

    Img[Pg].Canvas.StretchDraw(Rect(0, 0, Img[Pg].ClientWidth,
                                    Img[Pg].ClientHeight),
                               PageImg.Picture.Bitmap);
    Inc(Pg);
    TabControl1.Tabs.Add('Page ' + IntToStr(Pg));
  End;

begin
  if InCreatePages then Exit;

  try
    BMLeftMargin:= Round((ScrollBarLeft.Position / mmScale) *
                          Screen.PixelsPerInch);                                //Pixel
    BMTopMargin:= Round((ScrollBarTop.Position / mmScale) *
                         Screen.PixelsPerInch);
    BMRightMargin:= Round((ScrollBarRight.Position / mmScale) *
                           Screen.PixelsPerInch);
    BMBottomMargin:= Round((ScrollBarBottom.Position / mmScale) *
                            Screen.PixelsPerInch);

    if TabControl1.Tabs.Count > 0 then OldTabIdx:= TabControl1.TabIndex;        //Remember current tab

    TabControl1.Tabs.Clear;
    for n := Scrollbox2.ControlCount - 1 downto 0
      do ScrollBox2.Controls[n].Free;

    Pg:= 0;
    Setlength(PageStartLine, 1);
    n:= 0;
    PageStartLine[Pg]:= n;
    try
      BM.Width:= Round((papermmX / mmscale) * Screen.PixelsPerInch);            //Pixel
      BM.Height:= Round((papermmY / mmScale) * Screen.PixelsPerInch);

      if SrcImage.Width > 0
        then
        begin
          BuildPage(Pg);
          AdjPreviewGrBox;
        End
        else
          While n < Memo1.Lines.Count do                                        //While not bottom of page...
          begin
            n:= BuildPage(Pg);
            AdjPreviewGrBox;
            Setlength(PageStartLine, Pg + 1);
            PageStartLine[length(PageStartLine) - 1]:= n;
          end;                                                                  //remember first line number of page
    finally
      if TabControl1.Tabs.Count > 0 then
      begin
        TabControl1.TabIndex:= OldTabIdx;
        TabControl1change(nil);
      end;
      LabeledEdit1.Text:= '1';                                                  //print from this page
      LabeledEdit2.Text:= IntToStr(Pg);                                         //print to this page

      InCreatePages:= false;
    end;
  Finally
    Bitbtn1.Enabled:= (Memo1.Lines.Count > 0) or (SrcImage.Width > 0);
    Bitbtn2.Enabled:= Bitbtn1.Enabled;
  End;
end;

Function TPrint_Previewfm.BuildPage(PageNum: Integer): Integer;
var
  n, Ti, Tb   : Int64;
  i           : Integer;
  S           : String;
  Si, S1,
  DispScaleX,
  DispScaleY  : Single;

begin
  try
    BM.Canvas.Brush.Color:= clwhite;                                            //Background color
    BM.Canvas.Brush.Style:= bsSolid;
    BM.Canvas.Pen.width:= 1;
    BM.Canvas.Pen.Color:= clWhite;

    BM.Canvas.Rectangle(Rect(0, 0, BM.Width, BM.Height));                       //clear bitmap background

    BM.Canvas.Pen.Color:= clBlack;
    BM.canvas.Font.Color:= clblack;

    Ti:= BM.Width - BMLeftMargin - BMRightMargin;                               //Nutzbare Breite in Pixel

    Case ComboBox2.ItemIndex of
       0: begin                                                                 //25%
            PageImg.Height:= BM.Height div 4;
            PageImg.Width:= BM.Width div 4;

            PageImg.Picture.Bitmap.Width:= PageImg.Width;
            PageImg.Picture.Bitmap.Height:= PageImg.Height;
          end;

       1: begin                                                                 //50%
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

       2: begin                                                                 //75%
            PageImg.Height:= (BM.Height div 4) * 3;
            PageImg.Width:= (BM.Width div 4) * 3;

            PageImg.Picture.Bitmap.Width:= PageImg.Width;
            PageImg.Picture.Bitmap.Height:= PageImg.Height;
          end;

       3: begin                                                                 //Original
            PageImg.Height:= BM.Height;
            PageImg.Width:= BM.Width;

            PageImg.Picture.Bitmap.Width:= PageImg.Width;
            PageImg.Picture.Bitmap.Height:= PageImg.Height;
          end;

       else
          begin                                                                 //Fit
            PageImg.Height:= ScrollBox1.ClientHeight;
            PageImg.Width:= Round(PageImg.Height * (Bm.Width / BM.Height) - ScrBarWidth);

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

    if SrcImage.Width > 0
      then
      begin
        If CheckBox_Header.Checked
          then PrintHeader
          else YPos:= BMTopMargin;

        If CheckBox_Footer.Checked
          then PrintFooter(PageNum)
          else Bot:= Bm.Height - BMBottomMargin - BMTopMargin;

        if (SrcImage.Picture.Bitmap.Width > Ti) and
           (SrcImage.Picture.Bitmap.Height > Bot)
          then
            begin
              Si:= Ti / SrcImage.Picture.Bitmap.Width;
              S1:= Bot / SrcImage.Picture.Bitmap.Height;
              if S1 < Si             //Height > Width
                then
                  BM.Canvas.StretchDraw(
                        Rect(BMLeftMargin, YPos,
                             BMLeftMargin + Round(SrcImage.Picture.Bitmap.Width * S1),
                             YPos + Bot),
                        SrcImage.Picture.Graphic)
                else                //Width > Height
                  BM.Canvas.StretchDraw(
                        Rect(BMLeftMargin, YPos,
                             BMLeftMargin + Ti,
                             Round(SrcImage.Picture.Bitmap.Height * Si)),
                        SrcImage.Picture.Graphic);
            end
          else if SrcImage.Picture.Bitmap.Width > Ti
            then
             begin
               Si:= Ti / SrcImage.Picture.Bitmap.Width;
               BM.Canvas.StretchDraw(
                        Rect(BMLeftMargin, YPos,
                             BMLeftMargin + Ti,
                             YPos + Round(SrcImage.Picture.Bitmap.Height * Si)),
                        SrcImage.Picture.Graphic);
             End
            else if SrcImage.Picture.Bitmap.Height > Bot
              then
               begin
                 Si:= Bot / SrcImage.Picture.Bitmap.Height;
                 BM.Canvas.StretchDraw(
                        Rect(BMLeftMargin, YPos,
                             BMLeftMargin +
                             Round(SrcImage.Picture.Bitmap.Width * Si),
                             Bot),
                        SrcImage.Picture.Graphic);
               End
              else
                 BM.Canvas.StretchDraw(
                        Rect(BMLeftMargin, YPos,
                             BMLeftMargin + SrcImage.Picture.Bitmap.Width,
                             SrcImage.Picture.Bitmap.Height),
                        SrcImage.Picture.Graphic);
      End
      else
      begin
        n:= PageStartLine[PageNum];
        i:= Memo1.Lines.Count;

        While n < Memo1.Lines.Count do
        begin
          If CheckBox_Header.Checked
            then PrintHeader
            else YPos:= BMTopMargin;

          If CheckBox_Footer.Checked
            then PrintFooter(PageNum)
            else Bot:= Bm.Height - BMBottomMargin;

          While (YPos - Bm.Canvas.Font.Height) < Bot do                             //Font.Height is negative
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
                    Ypos:= Ypos - Round(1.2 * Bm.Canvas.Font.Height);              //Increase the line position to next line
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
              Ypos:= Ypos - Round(1.2 * Bm.Canvas.Font.Height);                    //Increase the line position to next line
            end;
            Inc(n);
          end;
          Break;
        end;
      End;
  finally
    PageImg.Picture.Bitmap.Canvas.StretchDraw(
                                Rect(0, 0, PageImg.Width, PageImg.Height), BM); //Scale BM to PageImg size

    if ShowPrintBordercb.checked then
    begin
      PageImg.Canvas.Pen.Mode := pmCopy;                                        //Draw print border
      PageImg.Canvas.Pen.Color:= clRed;
      PageImg.Canvas.Pen.Style:= psDot;
      PageImg.Canvas.Brush.Style:= bsClear;
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
  If not InitRun then BuildPage(TabControl1.TabIndex);
end;

procedure TPrint_Previewfm.ShowPrintBordercbChange(Sender: TObject);
begin
  BuildPage(TabControl1.TabIndex);
end;

Procedure Tprint_previewfm.Splitter1moved(Sender: Tobject);
Begin
  ScrollBox2.Width:= Splitter1.Left;
  CreatePages;
End;

end.

