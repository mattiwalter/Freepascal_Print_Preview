unit patchimagedpi;

{$mode objfpc}{$H+}

interface

uses
  Classes;

function SetDpi_BMP(AStream: TStream; dpiX, dpiY: Double): Boolean;
function SetDpi_JPG(AStream: TStream; dpiX, dpiY: Double): Boolean;
function SetDpi_PCX(AStream: TStream; dpiX, dpiY: Double): Boolean;
function SetDpi_PNG(AStream: TStream; dpiX, dpiY: Double): Boolean;
function SetDPI_TIF(AStream: TStream; dpiX, dpiY: Double): Boolean;
function SetDPI_WMF(AStream: TStream; dpi: Double): Boolean;


implementation

uses
  FpImgCmn, SysUtils, Math;

type
  TByteOrder = (boLE, boBE);  // little edian, or big endian

{ Makes sure that the byte order of w is as specified by the parameter. the
  function is for reading. }
function FixByteOrderR(w: Word; AByteOrder: TByteOrder): Word; overload;
begin
  Result := IfThen(AByteOrder = boLE, LEToN(w), BEToN(w));
end;

{ Makes sure that the byte order of dw is as specified by the parameter.
  The function is for reading. }
function FixByteOrderR(dw: DWord; AByteOrder: TByteOrder): DWord; overload;
begin
  Result := IfThen(AByteOrder = boLE, LEToN(dw), BEToN(dw));
end;

function FixByteOrderW(w: Word; AByteOrder: TByteOrder): Word; overload;
begin
  Result := IfThen(AByteOrder = boLE, NToLE(w), NToBE(w));
end;

function FixByteOrderW(dw: DWord; AByteOrder: TByteorder): DWord; overload;
begin
  Result := IfThen(AByteOrder = boLE, NToLE(dw), NToBE(dw));
end;


{ BMP files }

function SetDpi_BMP(AStream: TStream; dpiX, dpiY: Double): Boolean;
type
  TBitMapFileHeader = packed record
     bfType: word;
     bfSize: longint;
     bfReserved: longint;
     bfOffset: longint;
  end;
  TBitMapInfoHeader = packed record
     Size: longint;
     Width: longint;
     Height: longint;
     Planes: word;
     BitCount: word;
     Compression: longint;
     SizeImage: longint;
     XPelsPerMeter: Longint;
     YPelsPerMeter: Longint;
     ClrUsed: longint;
     ClrImportant: longint;
  end;
const
  BMP_MAGIC_WORD = ord('M') shl 8 or ord('B');
var
  header: TBitmapFileHeader;
  info: TBitmapInfoHeader;
  p: Int64;
begin
  result := False;
  if AStream.Read(header{%H-}, SizeOf(header)) <> SizeOf(header) then Exit;
  if LEToN(header.bfType) <> BMP_MAGIC_WORD then Exit;
  p := AStream.Position;
  if AStream.Read(info{%H-}, SizeOf(info)) <> SizeOf(info) then Exit;
  if info.Size < 40 then
    exit;
  dpiX := dpiX / 0.0254;  // convert to pixels per meter
  dpiY := dpiY / 0.0254;
  info.XPelsPerMeter := NToLE(round(dpiX));
  info.YPelsPerMeter := NToLE(round(dpiY));
  AStream.Position := p;
  AStream.WriteBuffer(info, Sizeof(info));
  AStream.Position := 0;
  Result := true;
end;


{ TIF }

function SetDPI_TIF(AStream: TStream; dpiX, dpiY: Double): Boolean;
type
  TTifHeader = packed record
     BOM: word;     // 'II' for little endian, 'MM' for big endian
     Sig: word;     // Signature (42)
     IFD: DWORD;    // Offset where image data begin
  end;
  TIFD_Field = packed record
    Tag: word;
    FieldType: word;
    ValCount: DWord;
    ValOffset: DWord;
  end;
var
  header: TTifHeader = (BOM:0; Sig:0; IFD:0);
  dirEntries: Word;
  field: TIFD_Field = (Tag:0; FieldType:0; ValCount:0; ValOffset:0);
  p, pStart: Int64;
  bo: TByteOrder;
  i: Integer;
  done: Integer;
  num, denom: LongInt;
begin
  Result := false;
  pStart := AStream.Position;
  if AStream.Read(header, SizeOf(TTifHeader)) < SizeOf(TTifHeader) then exit;
  if header.BOM = $4949 then
    bo := boLE
  else if header.BOM = $4D4D then
    bo := boBE
  else
    exit;
  if FixByteOrderR(header.Sig, bo) <> 42 then exit;

  done := 0;
  AStream.Position := pStart + FixByteOrderR(header.IFD, bo);
  dirEntries := FixByteOrderR(AStream.ReadWord, bo);
  for i:= 1 to dirEntries do
  begin
    AStream.Read(field, SizeOf(field));
    field.Tag := FixByteOrderR(field.Tag, bo);
    field.ValOffset := FixByteOrderR(field.ValOffset, bo);
    field.FieldType := FixByteOrderR(field.FieldType, bo);
    p := AStream.Position;
    case field.Tag of
      $011A: begin   // dpix as rational number
               AStream.Position := pStart + field.ValOffset;
               num := Round(dpiX*100);
               num := FixByteOrderW(DWord(num), bo);
               denom := 100;
               denom := FixByteOrderW(DWord(denom), bo);
               AStream.WriteDWord(num);
               AStream.WriteDWord(denom);
               inc(done);
             end;
      $011B: begin  // dpiy as rational number
               AStream.Position := pStart + field.ValOffset;
               num := round(dpiY*100);
               num := FixByteOrderW(DWord(num), bo);
               denom := 100;
               denom := FixByteOrderW(DWord(denom), bo);
               AStream.WriteDWord(num);
               AStream.WriteDWord(denom);
               inc(done);
             end;
      $0128: begin
               AStream.WriteWord(FixByteOrderW(Word(2), bo));  // 2 = per inch
               inc(done);
             end;
    end;
    if (done = 3) then break;
    AStream.Position := p;
  end;
  AStream.Position := 0;
  Result := true;
end;


{ JPG files }

function SetDpi_JPG(AStream: TStream; dpiX, dpiY: Double): Boolean;
type
  TJPGHeader = array[0..1] of Byte; //FFD8 = StartOfImage (SOI)
  TJPGRecord = packed record
    Marker: Byte;
    RecType: Byte;
    RecSize: Word;
  end;
  TAPP0Record = packed record
    JFIF: Array[0..4] of AnsiChar;  // zero-terminated "JFIF" string
    Version: Word;     // JFIF format revision
    Units: Byte;       // Units used for resolution: 1->inch, 2->cm, 0-> aspect ratio (1, 1)
    XDensity: Word;    // Horizontal resolution
    YDensity: Word;    // Vertical resolution
    // thumbnail follows
  end;
var
  hdr: TJPGHeader;
  rec: TJPGRecord = (Marker: $FF; RecType: 0; RecSize: 0);
  app0: TAPP0Record;
  u: Integer;
  p: Int64;
  n: Integer;
  exifSig: Array[0..5] of AnsiChar;
begin
  Result := false;

  // Check for SOI (start of image) record
  n := AStream.Read(hdr{%H-}, SizeOf(hdr));
  if (n < SizeOf(hdr)) or (hdr[0] <> $FF) or (hdr[1] <> $D8) then
    exit;

  while (AStream.Position < AStream.Size) and (rec.Marker = $FF) do begin
    if AStream.Read(rec, SizeOf(rec)) < SizeOf(rec) then exit;
    rec.RecSize := BEToN(rec.RecSize);
    p := AStream.Position - 2;
    case rec.RecType of
      $E0:  // APP0 record
        if (rec.RecSize >= SizeOf(TAPP0Record)) then
        begin
          p := AStream.Position;
          AStream.Read(app0{%H-}, SizeOf(app0));
          if stricomp(pchar(app0.JFIF), 'JFIF') <> 0 then break;
          app0.XDensity := NToBE(Word(round(dpiX)));
          app0.YDensity := NToBE(Word(round(dpiY)));
          app0.Units := 1;  // 1 = per inch
          AStream.Position := p;
          AStream.WriteBuffer(app0, SizeOf(app0));
          AStream.Position := 0;
          Result := true;
          exit;
        end;
      $E1:   // APP1 record (EXIF)
        begin
          AStream.Read(exifSig{%H-}, Sizeof(exifSig));
          // to do: compare signature.
          Result := SetDPI_TIF(AStream, dpix, dpiY);
          if Result then begin
            AStream.Position := 0;
            exit;
          end;
        end;
    end;
    AStream.Position := p + rec.RecSize;
  end;
end;


{ PNG files }

function SetDPI_PNG(AStream: TStream; dpiX, dpiY: Double): Boolean;
// https://www.w3.org/TR/PNG/
type
  TPngSig = array[0..7] of byte;
  TPngChunk = packed record
    chLength: LongInt;
    chType: array[0..3] of AnsiChar;
    // follwoing: Data and CRC
  end;
  (*
  TPngPHYSChunk = packed record
    chType: array[0..3] of AnsiChar;
    dpiX: DWord;
    dpiY: DWord;
    unit: Byte;
  end;
   *)
const
  ValidSig: TPNGSig = (137, 80, 78, 71, 13, 10, 26, 10);
var
  Sig: TPNGSig;
  x: integer;
  chunk: TPngChunk;
  physChunkForCRC: array[0..12] of byte;
  xdpm: LongInt;
  ydpm: LongInt;
  units: Byte;
  p, p1: Int64;
  dw: DWord;
  crc: DWord;
begin
  Result := false;
  AStream.Position := 0;
  AStream.Read(Sig[0], SizeOf(Sig));
  for x := Low(Sig) to High(Sig) do
    if Sig[x] <> ValidSig[x] then
      exit;
  AStream.Position := SizeOf(TPngSig);
  while AStream.Position < AStream.Size do
  begin
    AStream.Read(chunk, SizeOf(TPngChunk));
    chunk.chLength := BEToN(chunk.chLength);
    p := AStream.Position;
    if strlcomp(PChar(chunk.chType), 'pHYs', 4) = 0 then
    begin
      dw := Round(dpix / 0.0254); // pixels per meter
      dw := NToBE(DWord(dw));
      AStream.WriteDWord(dw);
      dw := Round(dpiy / 0.0254);
      dw := NToBE(DWord(dw));
      AStream.WriteDWord(dw);
      AStream.WriteByte(1);  // Unit: per meter
      p1 := AStream.Position;
      AStream.Position := p - 4;
      AStream.ReadBuffer(physChunkForCRC[0], Length(physChunkForCRC));
      crc := CalculateCRC(physChunkForCRC[0], Length(physChunkForCRC));
      crc := NToBE(DWord(crc));
      AStream.Position := p1;
      AStream.WriteDWord(crc);
      AStream.Position := 0;
      Result := true;
      exit;
    end;
    AStream.Position := p + chunk.chLength + 4;
  end;
end;


{ PCX files }

function SetDPI_PCX(AStream: TStream; dpiX, dpiY: Double): Boolean;
type
  TPCXHeader = packed record
    FileID: Byte;                      // $0A for PCX files, $CD for SCR files
    Version: Byte;                     // 0: version 2.5; 2: 2.8 with palette; 3: 2.8 w/o palette; 5: version 3
    Encoding: Byte;                    // 0: uncompressed; 1: RLE encoded
    BitsPerPixel: Byte;
    XMin,
    YMin,
    XMax,
    YMax,                              // coordinates of the corners of the image
    HRes,                              // horizontal resolution in dpi
    VRes: Word;                        // vertical resolution in dpi
    ColorMap: array[0..15*3] of byte;  // color table
    Reserved,
    ColorPlanes: Byte;                 // color planes (at most 4)
    BytesPerLine,                      // number of bytes of one line of one plane
    PaletteType: Word;                 // 1: color or b&w; 2: gray scale
    Fill: array[0..57] of Byte;
  end;
var
  hdr: TPCXHeader;
  n: Int64;
begin
  Result := false;

  AStream.Position := 0;
  n := AStream.Read(hdr{%H-}, SizeOf(hdr));
  if n < SizeOf(hdr) then exit;
  if not (hdr.FileID in [$0A, $CD]) then exit;

  hdr.HRes := round(dpix);
  hdr.VRes := round(dpiy);
  AStream.Position := 0;
  AStream.WriteBuffer(hdr, Sizeof(hdr));
  AStream.Position := 0;
  Result := true;
end;


{ WMF files }

function SetDPI_WMF(AStream: TStream; dpi: Double): Boolean;
type
  TWMFSpecialHeader = packed record
    Key: DWord;       // Magic number (always $9AC6CDD7)
    Handle: Word;     // Metafile HANDLE number (always 0)
    Left: SmallInt;   // Left coordinate in metafile units (twips)
    Top: SmallInt;    // Top coordinate in metafile units
    Right: SmallInt;  // Right coordinate in metafile units
    Bottom: SmallInt; // Bottom coordinate in metafile units
    Inch: Word;       // Number of metafile units per inch
    Reserved: DWord;  // Reserved (always 0)
    Checksum: Word;   // Checksum value for previous 10 words
  end;
var
  hdr: TWMFSpecialHeader;
  n: Int64;
begin
  Result := false;

  AStream.Position := 0;
  n := AStream.Read(hdr{%H-}, SizeOf(hdr));
  if n < SizeOf(hdr) then exit;
  if hdr.Key <> $9AC6CDD7 then exit;

  hdr.Inch := Round(dpi);
  AStream.Position := 0;
  AStream.WriteBuffer(hdr, SizeOf(hdr));
  AStream.Position := 0;
  Result := true;
end;

end.
