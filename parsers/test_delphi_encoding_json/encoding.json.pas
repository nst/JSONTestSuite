{
  encoding.json - a single-file JSON serialization library for Delphi,
  modelled on Go's encoding/json.

  SPDX-License-Identifier: Zlib

  Copyright (c) 2024-2026 Ingo Jache

  This software is provided 'as-is', without any express or implied
  warranty. In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.

  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.

  3. This notice may not be removed or altered from any source distribution.

  ---------------------------------------------------------------------------

  Support - this section is not part of the license and is not a condition
  of anything above it.

  This unit is free for any use, commercial included, and always will be.
  If it saves you time in something you sell, an acknowledgment in your
  documentation or a donation of whatever you think it is worth would be
  appreciated - but neither is required, and nothing is withheld from you
  if you do neither.

      https://github.com/sponsors/ijache
      https://ko-fi.com/ingojache
}

unit encoding.json;

{$RANGECHECKS OFF}
{$OVERFLOWCHECKS OFF}
{$STACKFRAMES OFF}
{$OPTIMIZATION ON}
{$INLINE AUTO}

interface

uses
  System.SysUtils,
  System.Classes,
  System.TypInfo,
  System.Rtti;

const
  JSON_VERSION = '1.0.0';
  JSON_DEFAULTMAXDEPTH = 64;

type
  TJSONCodec = class;

  TJSONResult = (
    JSONOK,
    JSONError,
    JSONMaxDepthReached,
    JSONUnsupportedType,
    JSONSyntax,
    JSONTypeMismatch
  );

  TJSONErrorInfo = record
    Code: TJSONResult;
    Offset: integer;
    Depth: integer;
    FailedType: PTypeInfo;
    MemberName: string;
  end;
  PJSONErrorInfo = ^TJSONErrorInfo;

  EJSONError = class(Exception) // raised only by Marshal(v) and MarshalIndent(v,indent)
  public
    Info: TJSONErrorInfo;
    constructor Create(const ainfo: TJSONErrorInfo);
  end;

  JSONAttribute = class(TCustomAttribute)
  public
    OmitEmpty: boolean;
    Name: string;
    constructor Create(const aname: string; aomitempty: boolean = false);
  end;

  TJSONValueType = (jvtString,jvtNumber,jvtTrue,jvtFalse,jvtNull);
  PJSONValueType = ^TJSONValueType;

  TJSONDateTimeFormat = (
    jdfRFC3339,     // "2024-06-09T12:30:45.123Z" - always UTC on the wire
    jdfEpoch,       // 1717936245     - seconds since 1970-01-01T00:00:00Z
    jdfEpochMillis  // 1717936245123  - milliseconds since the same epoch
  );

  TJSONConfig = record
  public
    MaxDepth: integer;
    DateTimeFormat: TJSONDateTimeFormat;
    DateTimeIsUTC: boolean; // whether a TDateTime in memory holds UTC or local time
    DetectKeyValuePairs: boolean;
    SortKeys: boolean;
    LineBreak: string;
  end;

  TJSONWriteState = (jwsNothing,jwsFirst,jwsNext);

  TJSONReader = record
  private
    Depth: integer;
    Config: TJSONConfig;

    ValuePtr: PAnsiChar;      
    ValueLen: integer;
    NumberIsReal: boolean;    

    Value: array of AnsiChar; 
    ValuePos: integer;

    Buffer: PAnsiChar;
    BufferLength: integer;
    ReadPos: integer;

    TokenStart: integer;     
  public
    function PeekNextToken: AnsiChar;
    function ConsumeToken: AnsiChar;

    function ReadValue(valueType: PJSONValueType = nil): TJSONResult; // reads one scalar of any kind and says which; the caller decides if it fits
    
    function SkipValue: TJSONResult; // consumes and validates one whole value the destination has no place for
    function ShapeError: TJSONResult;
    function LastValue: string;
    
    function LastValueRaw(out len: integer): PAnsiChar; // raw, unescaped UTF-8 without a copy - valid until the next ReadValue
  end;
  PJSONReader = ^TJSONReader;

  TJSONWriter = record
  private
    Depth: integer;
    Config: TJSONConfig;

    IndentBytes: UTF8String; 
    BreakBytes: UTF8String;
    State: TJSONWriteState;
    HasIndent: boolean;

    BufferString: UTF8String;
    Buffer: PByte;

    Capacity: integer;
    SpaceLeft: integer;

    ErrorType: PTypeInfo; 
    ErrorMember: string;
  public
    function BeginObject: TJSONResult;
    function EndObject: TJSONResult;

    function BeginArray: TJSONResult;
    function EndArray: TJSONResult;

    procedure WriteKey(const key: string);
    procedure WriteString(const s: string);          // a JSON string: quoted and escaped
    procedure WriteRaw(const jsonText: string);      // JSON text, written as it is - unchecked
    procedure WriteInteger(v: int64);
    procedure WriteBoolean(b: boolean);
    procedure WriteNull;
  end;
  PJSONWriter = ^TJSONWriter;

  TJSONParser = function(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
  TJSONFormatter = function(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;

  TJSONCodec = class
  private
    fConfig: TJSONConfig;
    Formatters: TStringList;
    Parsers: TStringList;
    ParserCache: TObject;
    FormatterCache: TObject;
    function GetHandlerForType(t: TRttiType; forWriting: boolean): Pointer;
  public
    constructor Create(const aconfig: TJSONConfig);
    destructor Destroy; override;

    procedure Configure(const aconfig: TJSONConfig); // not thread-safe, call outside of marshal/unmarshal calls
    property Config: TJSONConfig read fConfig;

    procedure RegisterParser(const qualifiedName: string; p: TJSONParser); overload;
    procedure RegisterFormatter(const qualifiedName: string; f: TJSONFormatter); overload;
    procedure RegisterParser(ti: PTypeInfo; p: TJSONParser); overload;
    procedure RegisterFormatter(ti: PTypeInfo; f: TJSONFormatter); overload;
    procedure RegisterParser<T>(p: TJSONParser); overload;
    procedure RegisterFormatter<T>(f: TJSONFormatter); overload;

    function GetFormatterForTypeInfo(ti: PTypeInfo): TJSONFormatter;
    function GetParserForTypeInfo(ti: PTypeInfo): TJSONParser;

    function Format(ti: PTypeInfo; data: Pointer; indent: string; var s: UTF8String; info: PJSONErrorInfo = nil): TJSONResult; overload;
    function Format(ti: PTypeInfo; data: Pointer; indent: string; var s: UnicodeString; info: PJSONErrorInfo = nil): TJSONResult; overload;
    function Parse(p: PAnsiChar; plen: integer; ti: PTypeInfo; data: Pointer; info: PJSONErrorInfo = nil): TJSONResult; overload;
    function Parse(const s: UTF8String; ti: PTypeInfo; data: Pointer; info: PJSONErrorInfo = nil): TJSONResult; overload;
    function Parse(const s: UnicodeString; ti: PTypeInfo; data: Pointer; info: PJSONErrorInfo = nil): TJSONResult; overload;

    function Marshal<T>(const v: T;var s: UnicodeString; info: PJSONErrorInfo = nil): TJSONResult; overload;
    function Marshal<T>(const v: T;var s: UTF8String; info: PJSONErrorInfo = nil): TJSONResult; overload;

    function MarshalIndent<T>(const v: T;indent: string; var s: UnicodeString; info: PJSONErrorInfo = nil): TJSONResult; overload;

    function Marshal<T>(const v: T): string; overload;
    function MarshalIndent<T>(const v: T; indent: string): string; overload;
    function MarshalIndent<T>(const v: T;indent: string; var s: UTF8String; info: PJSONErrorInfo = nil): TJSONResult; overload;

    function Unmarshal<T>(const p: PAnsiChar; const plen: integer; var v: T; info: PJSONErrorInfo = nil): TJSONResult; overload;
    function Unmarshal<T>(const s: UTF8String; var v: T; info: PJSONErrorInfo = nil): TJSONResult; overload;
    function Unmarshal<T>(const s: UnicodeString; var v: T; info: PJSONErrorInfo = nil): TJSONResult; overload;
  end;

const
  JSONDefaultConfig: TJSONConfig = (
    MaxDepth: JSON_DEFAULTMAXDEPTH;
    DateTimeFormat: jdfRFC3339;
    DateTimeIsUTC: true;
    DetectKeyValuePairs: true;
    SortKeys: false;
    LineBreak: #10
  );

function VarDictCreate: Variant;
function VarIsDict(const v: Variant): boolean;

var
  JSON: TJSONCodec;

implementation

uses
  System.DateUtils,
  System.Math,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SyncObjs,
  System.Variants;


var
  JSONFormatSettings: TFormatSettings;
  NullAttribute: JSONAttribute;
  RCTX: TRttiContext;


//----------------------------------------------------------------------------------------------------------------------
// Reader and writer internals
//----------------------------------------------------------------------------------------------------------------------
type
  TJSONReaderInternals = record helper for TJSONReader
    procedure SkipWhiteSpace;
    function ReadString(): TJSONResult;
    function ReadLiteral(const literal: AnsiString): TJSONResult;
    function ReadNumber(): TJSONResult;
    procedure AddChar(c: AnsiChar);
    procedure AddChars(buf: PAnsiChar; len: integer);
    procedure AddCodePoint(cp: cardinal);
    function ReadHex4(pos: integer; out value: cardinal): boolean;
  end;

  TJSONWriterInternals = record helper for TJSONWriter
    procedure GrowBuffer(atleast: integer);

    procedure PutText(const val: string; quoted: boolean);
    procedure WriteChar(const val: AnsiChar); inline;

    procedure BreakAndIndent;
    procedure Separate;
    function Open(opener: AnsiChar): TJSONResult;
    function Close(closer: AnsiChar): TJSONResult;

    procedure Reset(const indent: string);
    procedure WriteKeyDirect(ptr: Pointer; len: integer);

    procedure PutRaw(ptr: Pointer; len: integer; quoted: boolean);
    procedure WriteDigits(magnitude: UInt64; negative: boolean);
  end;


//======================================================================================================================
// What Marshal and Unmarshal do
//
// Format and Parse set up a writer or a reader, find the handler for the type
// and run it; the rest of the unit is what they call. TJSONCodec's other methods -
// handler lookup, construction and registration - close the unit.
//======================================================================================================================

function TJSONCodec.Format(ti: PTypeInfo; data: Pointer; indent: string; var s: UTF8String;
  info: PJSONErrorInfo): TJSONResult;
const
  DEFAULT_LINEBREAK = #10; 
var
  Writer: TJSONWriter;
  formatter: TJSONFormatter;
begin
  if info <> nil then info^:= Default(TJSONErrorInfo);

  Writer.Reset(indent);
  Writer.Config:= fConfig;
  if (indent <> '') and (Writer.Config.LineBreak = '') then
    Writer.Config.LineBreak:= DEFAULT_LINEBREAK;

  // none for a nil ti either
  formatter:= GetFormatterForTypeInfo(ti);
  if assigned(formatter) then
    result:= formatter(self,@Writer,ti,data)
  else
    result:= JSONUnsupportedType;

  if result = JSONOK then begin
    SetLength(Writer.BufferString,Writer.Buffer-PByte(Writer.BufferString));
    s:= Writer.BufferString;
    exit;
  end;

  if info <> nil then begin
    info.Code:= result;
    // the member FormatStruct named, or the top-level type when none was
    if Writer.ErrorMember <> '' then begin
      info.FailedType:= Writer.ErrorType;
      info.MemberName:= Writer.ErrorMember;
    end else begin
      info.FailedType:= ti;
    end;
  end;
end;

function TJSONCodec.Format(ti: PTypeInfo; data: Pointer; indent: string; var s: UnicodeString;
  info: PJSONErrorInfo): TJSONResult;
var
  us: UTF8String;
begin
  result:= Format(ti,data,indent,us,info);
  if result <> JSONOK then exit;
  s:= UnicodeString(us);
end;

function TJSONCodec.Marshal<T>(const v: T; var s: UTF8String; info: PJSONErrorInfo): TJSONResult;
begin
  result:= self.MarshalIndent(v,'',s,info);
end;

function TJSONCodec.Marshal<T>(const v: T; var s: UnicodeString; info: PJSONErrorInfo): TJSONResult;
begin
  result:= self.MarshalIndent(v,'',s,info);
end;

function TJSONCodec.MarshalIndent<T>(const v: T; indent: string; var s: UTF8String; info: PJSONErrorInfo): TJSONResult;
begin
  result:= self.Format(System.TypeInfo(T),@v,indent,s,info);
end;

function TJSONCodec.MarshalIndent<T>(const v: T; indent: string; var s: UnicodeString; info: PJSONErrorInfo): TJSONResult;
begin
  result:= self.Format(System.TypeInfo(T),@v,indent,s,info);
end;

constructor EJSONError.Create(const ainfo: TJSONErrorInfo);
var
  text: string;
begin
  Info:= ainfo;

  text:= GetEnumName(System.TypeInfo(TJSONResult),ord(ainfo.Code));
  if ainfo.MemberName <> '' then
    text:= text + ' at member "' + ainfo.MemberName + '"';

  inherited Create('encoding.json: ' + text);
end;

function TJSONCodec.MarshalIndent<T>(const v: T; indent: string): string;
var
  info: TJSONErrorInfo;
begin
  if self.Format(System.TypeInfo(T),@v,indent,result,@info) <> JSONOK then
    raise EJSONError.Create(info);
end;

function TJSONCodec.Marshal<T>(const v: T): string;
begin
  result:= self.MarshalIndent<T>(v,'');
end;

function TJSONCodec.Parse(p: PAnsiChar; plen: integer; ti: PTypeInfo; data: Pointer;info: PJSONErrorInfo): TJSONResult;
var
  parser: TJSONParser;
  reader: TJSONReader;
begin
  if info <> nil then info^:= Default(TJSONErrorInfo);

  Reader:= Default(TJSONReader);
  Reader.Config:= fConfig;
  Reader.Buffer:= p;
  Reader.BufferLength:= plen;

  if ti = nil then
    result:= JSONUnsupportedType
  else if plen <= 0 then
    result:= JSONSyntax
  else begin
    parser:= GetParserForTypeInfo(ti);
    if assigned(parser) then
      result:= parser(self,@Reader,ti,data)
    else
      result:= JSONUnsupportedType;
  end;

  // nothing but whitespace may follow the value
  if result = JSONOK then begin
    Reader.SkipWhiteSpace;
    if Reader.ReadPos < Reader.BufferLength then begin
      Reader.TokenStart:= Reader.ReadPos;
      result:= JSONSyntax;
    end;
  end;

  if (result <> JSONOK) and (info <> nil) then begin
    info.Code:= result;
    info.Offset:= Reader.TokenStart;
    info.Depth:= Reader.Depth;
    info.FailedType:= ti;
  end;
end;

function TJSONCodec.Parse(const s: UTF8String; ti: PTypeInfo; data: Pointer; info: PJSONErrorInfo): TJSONResult;
begin
  result:= Parse(Pointer(s),Length(s),ti,data,info);
end;

function TJSONCodec.Parse(const s: UnicodeString; ti: PTypeInfo; data: Pointer; info: PJSONErrorInfo): TJSONResult;
var
  x: UTF8String;
begin
  x:= UTF8String(s);
  result:= Parse(x,ti,data,info);
end;

function TJSONCodec.Unmarshal<T>(const p: PAnsiChar; const plen: integer; var v: T; info: PJSONErrorInfo): TJSONResult;
begin
  result:= Parse(p,plen,System.TypeInfo(T),@v,info);
end;

function TJSONCodec.Unmarshal<T>(const s: UTF8String; var v: T; info: PJSONErrorInfo): TJSONResult;
begin
  result:= Parse(s,System.TypeInfo(T),@v,info);
end;

function TJSONCodec.Unmarshal<T>(const s: UnicodeString; var v: T; info: PJSONErrorInfo): TJSONResult;
begin
  result:= Parse(s,System.TypeInfo(T),@v,info);
end;


//======================================================================================================================
// Writing and reading JSON
//======================================================================================================================

//----------------------------------------------------------------------------------------------------------------------
// The writer
//----------------------------------------------------------------------------------------------------------------------
const
  WRITEBUFFER_INITIALSIZE = 1024*8;

procedure TJSONWriterInternals.Reset(const indent: string);
begin
  IndentBytes:= UTF8String(indent);
  BreakBytes:= '';
  HasIndent:= indent <> '';
  State:= jwsNothing;
  Depth:= 0;

  ErrorType:= nil;
  ErrorMember:= '';

  SetLength(BufferString,WRITEBUFFER_INITIALSIZE);
  Capacity:= WRITEBUFFER_INITIALSIZE;
  SpaceLeft:= Capacity;

  Buffer:= PByte(BufferString);
end;

procedure TJSONWriterInternals.BreakAndIndent;
var
  i,len: integer;
begin
  if BreakBytes = '' then BreakBytes:= UTF8String(Config.LineBreak);

  len:= Length(BreakBytes) + Depth*Length(IndentBytes);
  if SpaceLeft <= len then GrowBuffer(len);

  Move(Pointer(BreakBytes)^,Buffer^,Length(BreakBytes));
  inc(Buffer,Length(BreakBytes));
  for i:= 1 to Depth do begin
    Move(Pointer(IndentBytes)^,Buffer^,Length(IndentBytes));
    inc(Buffer,Length(IndentBytes));
  end;
  dec(SpaceLeft,len);
end;

// what goes between elements. every value, key and opener goes through it
procedure TJSONWriterInternals.Separate;
begin
  case State of
    jwsFirst:
      if HasIndent then BreakAndIndent;
    jwsNext:
      begin
        WriteChar(',');
        if HasIndent then BreakAndIndent;
      end;
  end;
end;

function TJSONWriterInternals.Open(opener: AnsiChar): TJSONResult;
begin
  if Depth >= Config.MaxDepth then exit(JSONMaxDepthReached);

  Separate;
  WriteChar(opener);
  inc(Depth);
  State:= jwsFirst;

  result:= JSONOK;
end;

function TJSONWriterInternals.Close(closer: AnsiChar): TJSONResult;
begin
  dec(Depth);
  // still jwsFirst: nothing was written inside
  if (State = jwsNext) and HasIndent then BreakAndIndent;
  WriteChar(closer);
  State:= jwsNext;

  result:= JSONOK;
end;

function TJSONWriter.BeginArray: TJSONResult;
begin
  result:= Open('[');
end;

function TJSONWriter.BeginObject: TJSONResult;
begin
  result:= Open('{');
end;

function TJSONWriter.EndArray: TJSONResult;
begin
  result:= Close(']');
end;

function TJSONWriter.EndObject: TJSONResult;
begin
  result:= Close('}');
end;

procedure TJSONWriterInternals.GrowBuffer(atleast: integer);
var
  offset: integer;
begin
  if SpaceLeft > atleast then exit;

  repeat
    SpaceLeft:= SpaceLeft + Capacity;
    Capacity:= Capacity + Capacity;
  until SpaceLeft > atleast;

  offset:= Buffer-PByte(BufferString);
  SetLength(BufferString,Capacity);
  Buffer:= PByte(BufferString) + offset;
end;

procedure TJSONWriterInternals.WriteChar(const val: AnsiChar);
begin
  if SpaceLeft < 1 then GrowBuffer(1);
  Buffer^:= byte(val);
  inc(Buffer,1);
  SpaceLeft:= SpaceLeft-1;
end;

// one code point as UTF-8 at dst, which has room for four bytes; answers how
// many it took. the writer and the reader's unescaping both encode here
function PutUTF8(cp: cardinal; dst: PAnsiChar): integer; inline;
begin
  if cp < $80 then begin
    dst[0]:= AnsiChar(cp);
    result:= 1;
  end else if cp < $800 then begin
    dst[0]:= AnsiChar($C0 or (cp shr 6));
    dst[1]:= AnsiChar($80 or (cp and $3F));
    result:= 2;
  end else if cp < $10000 then begin
    dst[0]:= AnsiChar($E0 or (cp shr 12));
    dst[1]:= AnsiChar($80 or ((cp shr 6) and $3F));
    dst[2]:= AnsiChar($80 or (cp and $3F));
    result:= 3;
  end else begin
    dst[0]:= AnsiChar($F0 or (cp shr 18));
    dst[1]:= AnsiChar($80 or ((cp shr 12) and $3F));
    dst[2]:= AnsiChar($80 or ((cp shr 6) and $3F));
    dst[3]:= AnsiChar($80 or (cp and $3F));
    result:= 4;
  end;
end;

function IsPlainAscii(c: word): boolean; inline;
begin
  result:= (c >= $20) and (c < $80) and (c <> ord('"')) and (c <> ord('\'));
end;

// UTF-16 to UTF-8 by hand - no API call per segment. Quoted, it is a JSON
// string and escaped as it goes; unquoted, it is raw JSON text and goes out as
// it is. A surrogate pair is one code point; a surrogate on its own has none
// and becomes U+FFFD, as LocaleCharsFromUnicode made it
procedure TJSONWriterInternals.PutText(const val: string; quoted: boolean);
const
  HEXDIGITS: array[0..15] of AnsiChar = '0123456789abcdef';
  MAXBYTES_PER_CHAR = 6; // worst case a single UTF-16 code-unit can produce: 6 bytes for \u00XX.
var
  pcur,pend: PChar;
  pdst: PAnsiChar;
  sourceChars: integer;
  maxDestBytes: integer;
  c: cardinal;
  l: UInt64;
begin
  sourceChars:= Length(val);
  // the whole string is written through pdst without re-checking, so this has
  // to be a true worst case: every char escaped as \u00XX, plus both quotes
  maxDestBytes:= (sourceChars*MAXBYTES_PER_CHAR)+4;
  if SpaceLeft < maxDestBytes then GrowBuffer(maxDestBytes);

  pcur:= PChar(Pointer(val));
  pend:= pcur + sourceChars;

  pdst:= PAnsiChar(Buffer);
  if quoted then begin
    pdst^:= '"';
    inc(pdst);
  end;

  while pcur < pend do begin

    // four plain ASCII chars at once, packed into four bytes
    if pend - pcur >= 4 then begin
      l:= PUInt64(pcur)^;
      if IsPlainAscii(word(l)) and IsPlainAscii(word(l shr 16))
         and IsPlainAscii(word(l shr 32)) and IsPlainAscii(word(l shr 48)) then begin
        PCardinal(pdst)^:= cardinal(l and $FF) or cardinal((l shr 8) and $FF00)
                         or cardinal((l shr 16) and $FF0000) or cardinal((l shr 24) and $FF000000);
        inc(pdst,4);
        inc(pcur,4);
        continue;
      end;
    end;

    c:= word(pcur^);
    inc(pcur);

    if c < $80 then begin
      if IsPlainAscii(c) or not(quoted) then begin
        pdst^:= AnsiChar(c);
        inc(pdst);
        continue;
      end;

      // a quote, a backslash or a control character; the slash is not escaped
      pdst^:= '\';
      inc(pdst);
      case c of
        8:  pdst^:= 'b';
        9:  pdst^:= 't';
        10: pdst^:= 'n';
        12: pdst^:= 'f';
        13: pdst^:= 'r';
        ord('"'),ord('\'): pdst^:= AnsiChar(c);
      else
        // a control character without a short escape
        pdst[0]:= 'u';
        pdst[1]:= '0';
        pdst[2]:= '0';
        pdst[3]:= HEXDIGITS[c shr 4];
        pdst[4]:= HEXDIGITS[c and $0F];
        inc(pdst,4);
      end;
      inc(pdst);
      continue;
    end;

    if (c >= $D800) and (c <= $DFFF) then begin
      if (c <= $DBFF) and (pcur < pend) and (word(pcur^) >= $DC00) and (word(pcur^) <= $DFFF) then begin
        c:= $10000 + ((c - $D800) shl 10) + (cardinal(word(pcur^)) - $DC00);
        inc(pcur);
      end else
        c:= $FFFD;
    end;
    inc(pdst,PutUTF8(c,pdst));
  end;

  if quoted then begin
    pdst^:= '"';
    inc(pdst);
  end;
  Buffer:= PByte(pdst);

  SpaceLeft:= Capacity - (Buffer-PByte(BufferString));
end;

procedure TJSONWriter.WriteKey(const key: string);
begin
  Separate;
  PutText(key,true);
  WriteChar(':');
  if HasIndent then WriteChar(' ');
  // the value goes on the same line as its key, with nothing in between
  State:= jwsNothing;
end;

procedure TJSONWriterInternals.WriteKeyDirect(ptr: Pointer; len: integer);
begin
  Separate;

  if SpaceLeft < len then GrowBuffer(len);
  Move(ptr^,Buffer^,len);
  Buffer:= Buffer + len;
  SpaceLeft := SpaceLeft - len;

  if HasIndent then WriteChar(' ');
  State:= jwsNothing;
end;

procedure TJSONWriter.WriteString(const s: string);
begin
  Separate;
  PutText(s,true);
  State:= jwsNext;
end;

procedure TJSONWriter.WriteRaw(const jsonText: string);
begin
  Separate;
  PutText(jsonText,false);
  State:= jwsNext;
end;

// UTF-8 that needs no escaping - digits, a literal, a name from RTTI - copied
// in as it is, with no string built and no conversion
procedure TJSONWriterInternals.PutRaw(ptr: Pointer; len: integer; quoted: boolean);
begin
  Separate;

  if SpaceLeft < len+2 then GrowBuffer(len+2);
  if quoted then begin
    Buffer^:= ord('"');
    inc(Buffer);
  end;
  Move(ptr^,Buffer^,len);
  inc(Buffer,len);
  if quoted then begin
    Buffer^:= ord('"');
    inc(Buffer);
  end;
  SpaceLeft:= Capacity - (Buffer-PByte(BufferString));

  State:= jwsNext;
end;

// IntToStr without the heap string: the digits right to left into the stack
procedure TJSONWriterInternals.WriteDigits(magnitude: UInt64; negative: boolean);
var
  digits: array[0..20] of AnsiChar; // High(UInt64) has 20 digits, plus a sign
  p,stop: PAnsiChar;
  small: cardinal;
begin
  stop:= PAnsiChar(@digits) + Length(digits);
  p:= stop;

  // a 64-bit division is a library call on Win32, so only the digits that need it
  while magnitude > High(cardinal) do begin
    dec(p);
    p^:= AnsiChar(ord('0') + magnitude mod 10);
    magnitude:= magnitude div 10;
  end;

  small:= magnitude;
  repeat
    dec(p);
    p^:= AnsiChar(ord('0') + small mod 10);
    small:= small div 10;
  until small = 0;

  if negative then begin
    dec(p);
    p^:= '-';
  end;

  PutRaw(p,stop-p,false);
end;

procedure TJSONWriter.WriteInteger(v: int64);
begin
  // -(v+1)+1 rather than -v, which overflows for Low(Int64)
  if v < 0 then
    WriteDigits(UInt64(-(v+1))+1,true)
  else
    WriteDigits(v,false);
end;

procedure TJSONWriter.WriteBoolean(b: boolean);
begin
  if b then PutRaw(PAnsiChar('true'),4,false) else PutRaw(PAnsiChar('false'),5,false);
end;

procedure TJSONWriter.WriteNull;
begin
  PutRaw(PAnsiChar('null'),4,false);
end;


//----------------------------------------------------------------------------------------------------------------------
// The reader
//----------------------------------------------------------------------------------------------------------------------
function HexDigit(c: AnsiChar): integer; inline;
begin
  case c of
    '0'..'9': result:= ord(c) - ord('0');
    'a'..'f': result:= ord(c) - ord('a') + 10;
    'A'..'F': result:= ord(c) - ord('A') + 10;
  else
    result:= -1;
  end;
end;

procedure TJSONReaderInternals.SkipWhiteSpace;
begin
  while true do begin
    if ReadPos >= BufferLength then exit;
    case Buffer[ReadPos] of
    #9,#10,#13,#32: inc(ReadPos);
    else exit;
    end;
  end;
end;

function TJSONReader.PeekNextToken: AnsiChar;
begin
  SkipWhiteSpace;
  TokenStart:= ReadPos;
  if ReadPos >= BufferLength then exit(#0);
  exit(Buffer[ReadPos]);
end;

function TJSONReader.ShapeError: TJSONResult;
begin
  if TokenStart >= BufferLength then exit(JSONSyntax);

  case Buffer[TokenStart] of
    '{','[','"','t','f','n','-','0'..'9': result:= JSONTypeMismatch;
  else
    result:= JSONSyntax;
  end;
end;

function TJSONReader.ConsumeToken: AnsiChar;
begin
  result:= PeekNextToken;
  if ReadPos < BufferLength then inc(ReadPos);
end;

function TJSONReader.ReadValue(valueType: PJSONValueType): TJSONResult;
var
  vt: TJSONValueType;
begin
  // bounds checked after the whitespace, or input that ends in whitespace
  // would be read past its end
  SkipWhiteSpace;
  TokenStart:= ReadPos;
  if ReadPos >= BufferLength then exit(JSONSyntax);

  ValueLen:= 0;

  // every scalar is read in full and the caller decides whether its kind fits,
  // so a broken document is reported as broken, not as a mismatch
  case Buffer[ReadPos] of
    '"':
      begin
        vt:= jvtString;
        result:= ReadString();
      end;
    't':
      begin
        vt:= jvtTrue;
        result:= ReadLiteral('true');
      end;
    'f':
      begin
        vt:= jvtFalse;
        result:= ReadLiteral('false');
      end;
    'n':
      begin
        vt:= jvtNull;
        result:= ReadLiteral('null');
      end;
    '-','0','1','2','3','4','5','6','7','8','9':
      begin
        vt:= jvtNumber;
        result:= ReadNumber();
      end;
    '{','[':
      // an aggregate where a scalar is wanted
      exit(JSONTypeMismatch);
    else
      exit(JSONSyntax);
  end;

  if (result = JSONOK) and (valueType <> nil) then valueType^:= vt;
end;

function TJSONReaderInternals.ReadString(): TJSONResult;
var
  c: AnsiChar;
  startPos: integer;
  unicodeValue,lowSurrogate: cardinal;
  charsLeft: integer;
  escaped: boolean;
begin
  result:= JSONSyntax;

  // past the opening quote
  inc(ReadPos);

  startPos:= ReadPos;
  escaped:= false;

  while ReadPos < BufferLength do begin

    c:= Buffer[ReadPos];

    case c of
    '\':
      begin
        charsLeft:= BufferLength-ReadPos;
        if charsLeft < 2 then exit(JSONSyntax);

        // from the first escape on, the value is assembled in Value
        if not escaped then begin
          escaped:= true;
          ValuePos:= 0;
          if Length(Value) < 16 then SetLength(Value,16);
        end;
        AddChars(@Buffer[startPos],ReadPos-startPos);

        inc(ReadPos);
        c:= Buffer[ReadPos];
        case c of
          '"','\','/': AddChar(c);
          'b': AddChar(#8);
          't': AddChar(#9);
          'n': AddChar(#10);
          'f': AddChar(#12);
          'r': AddChar(#13);
          'u':
            begin
              // needs the backslash, the 'u' and 4 hex-digits
              if charsLeft < 6 then exit(JSONSyntax);
              if not(ReadHex4(ReadPos+1,unicodeValue)) then exit(JSONSyntax);
              inc(ReadPos,4);

              if (unicodeValue >= $D800) and (unicodeValue <= $DBFF) then begin
                // a high surrogate pairs only with a following low one; alone it
                // becomes U+FFFD, and a trailing escape is read on its own
                lowSurrogate:= 0;
                if (BufferLength-ReadPos >= 7)
                  and (Buffer[ReadPos+1] = '\')
                  and (Buffer[ReadPos+2] = 'u')
                  and ReadHex4(ReadPos+3,lowSurrogate)
                  and (lowSurrogate >= $DC00) and (lowSurrogate <= $DFFF) then begin
                  unicodeValue:= $10000 + ((unicodeValue-$D800) shl 10) + (lowSurrogate-$DC00);
                  inc(ReadPos,6);
                end else begin
                  unicodeValue:= $FFFD;
                end;
              end else
              if (unicodeValue >= $DC00) and (unicodeValue <= $DFFF) then begin
                // unpaired low surrogate
                unicodeValue:= $FFFD;
              end;

              AddCodePoint(unicodeValue);
            end;
          else
            exit(JSONSyntax);
        end;

        startPos:= ReadPos+1;

      end;
    '"':
      begin
        if escaped then begin
          AddChars(@Buffer[startPos],ReadPos-startPos);
          ValuePtr:= @Value[0];
          ValueLen:= ValuePos;
        end else begin
          // the common case: the value is the text between the quotes, as it is
          ValuePtr:= @Buffer[startPos];
          ValueLen:= ReadPos-startPos;
        end;
        inc(ReadPos);
        exit(JSONOK);
      end;
    #0..#31:
      begin
        exit(JSONSyntax);
      end;
    end;
    inc(ReadPos);
  end;
end;

procedure TJSONReaderInternals.AddChar(c: AnsiChar);
begin
  if ValuePos >= Length(Value) then SetLength(Value,2*Length(Value));
  Value[ValuePos]:= c;
  inc(ValuePos);
end;

procedure TJSONReaderInternals.AddChars(buf: PAnsiChar; len: integer);
begin
  if len = 0 then exit;
  while ValuePos + len > Length(Value) do SetLength(Value,2*Length(Value));
  Move(PByte(buf)^,Value[ValuePos],len);
  inc(ValuePos,len);
end;

procedure TJSONReaderInternals.AddCodePoint(cp: cardinal);
begin
  // ReadString makes Value at least 16 long, so one doubling makes room
  if ValuePos + 4 > Length(Value) then SetLength(Value,2*Length(Value));
  inc(ValuePos,PutUTF8(cp,@Value[ValuePos]));
end;

function TJSONReaderInternals.ReadHex4(pos: integer; out value: cardinal): boolean;
var
  i,hex: integer;
begin
  value:= 0;
  for i:= 0 to 3 do begin
    hex:= HexDigit(Buffer[pos+i]);
    if hex < 0 then exit(false);
    value:= (value shl 4) or cardinal(hex);
  end;
  result:= true;
end;

// ReadValue has picked the literal from its first byte; this checks the rest
function TJSONReaderInternals.ReadLiteral(const literal: AnsiString): TJSONResult;
begin
  if (BufferLength-ReadPos < Length(literal))
    or not CompareMem(@Buffer[ReadPos],Pointer(literal),Length(literal)) then
    exit(JSONSyntax);

  ValuePtr:= @Buffer[ReadPos];
  ValueLen:= Length(literal);
  inc(ReadPos,Length(literal));
  result:= JSONOK;
end;

// the JSON number grammar, each part needing a digit. it ends at the first byte
// that cannot continue it; whether that byte may follow is for the caller
function TJSONReaderInternals.ReadNumber(): TJSONResult;
var
  p: integer;

  function Digits: boolean;
  begin
    result:= (p < BufferLength) and (Buffer[p] in ['0'..'9']);
    while (p < BufferLength) and (Buffer[p] in ['0'..'9']) do inc(p);
  end;

begin
  // ReadValue has checked there is a byte here, and that it is '-' or a digit
  p:= ReadPos;
  if Buffer[p] = '-' then inc(p);
  NumberIsReal:= false;

  if (p < BufferLength) and (Buffer[p] = '0') then
    inc(p)
  else if not Digits then
    exit(JSONSyntax);

  if (p < BufferLength) and (Buffer[p] = '.') then begin
    NumberIsReal:= true;
    inc(p);
    if not Digits then exit(JSONSyntax);
  end;

  if (p < BufferLength) and (Buffer[p] in ['e','E']) then begin
    NumberIsReal:= true;
    inc(p);
    if (p < BufferLength) and (Buffer[p] in ['+','-']) then inc(p);
    if not Digits then exit(JSONSyntax);
  end;

  ValuePtr:= @Buffer[ReadPos];
  ValueLen:= p-ReadPos;
  ReadPos:= p;
  result:= JSONOK;
end;

function TJSONReader.LastValue: string;
var
  n: integer;
begin
  if ValueLen <= 0 then exit('');

  // by length: an escaped null decodes to #0. UTF-8 never yields more UTF-16 units than it has bytes, so ValueLen bounds the result
  SetLength(result,ValueLen);
  n:= System.UnicodeFromLocaleChars(
    CP_UTF8, 0,
    ValuePtr,ValueLen,
    PWideChar(result),ValueLen
  );
  if n <= 0 then exit('');
  SetLength(result,n);
end;

function TJSONReader.LastValueRaw(out len: integer): PAnsiChar;
begin
  len:= ValueLen;
  if len > 0 then result:= ValuePtr else result:= nil;
end;


//----------------------------------------------------------------------------------------------------------------------
// The aggregate walk
//
// The JSON grammar for an aggregate - opener, elements separated by commas,
// closer - lives here and nowhere else: it used to be copied eight times, and
// every drift between the copies was a bug. A handler sees one element, never
// a token, a comma or Depth. Depth only has to be right on success - nothing
// recovers from a reader error - so any path may exit.
//----------------------------------------------------------------------------------------------------------------------
type
  // four parameters, the most Win64 passes in registers: this runs once per
  // element. an object member's key is still in the reader's buffer.
  TAggregateHandler = function(ctx: Pointer; j: TJSONCodec; r: PJSONReader;
                               index: integer): TJSONResult;

function WalkAggregate(j: TJSONCodec; r: PJSONReader; opener: AnsiChar;
                       ctx: Pointer; handler: TAggregateHandler): TJSONResult;
var
  closer: AnsiChar;
  isObject: boolean;
  nextToken: AnsiChar;
  index: integer;
begin
  isObject:= (opener = '{');
  if isObject then closer:= '}' else closer:= ']';

  if r.Depth >= r.Config.MaxDepth then exit(JSONMaxDepthReached);

  nextToken:= r.ConsumeToken;
  if nextToken <> opener then exit(r.ShapeError);

  // an empty aggregate never reaches the handler
  if r.PeekNextToken = closer then begin
    r.ConsumeToken;
    exit(JSONOK);
  end;

  inc(r.Depth);
  index:= 0;

  while true do begin
    if isObject then begin
      // the grammar demands a quoted key: anything else is a syntax error
      if r.PeekNextToken <> '"' then exit(JSONSyntax);
      result:= r.ReadValue;
      if result <> JSONOK then exit;

      if r.PeekNextToken <> ':' then exit(JSONSyntax);
      r.ConsumeToken;
    end;

    result:= handler(ctx,j,r,index);
    if result <> JSONOK then exit;
    inc(index);

    nextToken:= r.ConsumeToken;
    if nextToken = closer then break;
    if nextToken <> ',' then exit(JSONSyntax);
  end;

  dec(r.Depth);
  result:= JSONOK;
end;

function SkipOneValue(ctx: Pointer; j: TJSONCodec; r: PJSONReader; index: integer): TJSONResult;
begin
  result:= r.SkipValue;
end;

function TJSONReader.SkipValue: TJSONResult;
var
  c: AnsiChar;
begin
  c:= PeekNextToken;

  if (c <> '{') and (c <> '[') then exit(ReadValue);

  result:= WalkAggregate(nil,@self,c,nil,SkipOneValue);
end;


//======================================================================================================================
// The types
//
// One kind of type after another: how it is held in memory, how it is written,
// how it is read. 
//======================================================================================================================

//----------------------------------------------------------------------------------------------------------------------
// Strings and characters
//----------------------------------------------------------------------------------------------------------------------
function LoadString(ti: PTypeInfo; data: Pointer): string;
var
  cp: word;
  raw: RawByteString;
  n: integer;
begin
  case ti.Kind of
    tkUString:
      result:= PString(data)^;
    tkWString:
      result:= PWideString(data)^;
    tkString:
      result:= string(PShortString(data)^);
    tkLString:
      begin
        n:= Length(PAnsiString(data)^);
        if n = 0 then exit('');
        SetLength(raw,n);
        Move(PPointer(data)^^,PAnsiChar(raw)^,n);
        cp:= GetTypeData(ti)^.CodePage;
        if cp = 0 then cp:= DefaultSystemCodePage;
        SetCodePage(raw,cp,false);
        result:= string(raw);
      end;
  else
    result:= '';
  end;
end;

procedure StoreString(ti: PTypeInfo; data: Pointer; const value: string);
var
  raw: RawByteString;
  cp: word;
  len: integer;
begin
  case ti.Kind of
    tkUString:
      PString(data)^:= value;
    tkWString:
      PWideString(data)^:= value;
    tkLString:
      begin
        cp:= GetTypeData(ti)^.CodePage;
        if cp = 0 then cp:= DefaultSystemCodePage;
        raw:= UTF8Encode(value);
        if cp <> CP_UTF8 then SetCodePage(raw,cp,true);
        PRawByteString(data)^:= raw;
      end;
    tkString:
      begin
        // shortstring: truncate to the declared maximum
        raw:= AnsiString(value);
        len:= Length(raw);
        if len > GetTypeData(ti)^.MaxLength then len:= GetTypeData(ti)^.MaxLength;
        PByte(data)^:= byte(len);
        if len > 0 then Move(Pointer(raw)^,PByte(data)[1],len);
      end;
  end;
end;

function FormatString(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
begin
  // the common case reads the string in place, with no copy and no refcount
  if ti.Kind = tkUString then
    w.WriteString(PString(data)^)
  else
    w.WriteString(LoadString(ti,data));
  result:= JSONOK;
end;

function ParseString(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  vt: TJSONValueType;
begin
  result:= r.ReadValue(@vt);
  if result <> JSONOK then exit;
  if vt <> jvtString then exit(JSONTypeMismatch);
  StoreString(ti,data,r.LastValue);
end;

function FormatChar(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  text: string;
begin
  case ti.Kind of
    tkChar:  text:= string(AnsiChar(PByte(data)^));
    tkWChar: text:= PWideChar(data)^;
  else
    exit(JSONUnsupportedType);
  end;

  w.WriteString(text);
  result:= JSONOK;
end;

function ParseChar(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  valueType: TJSONValueType;
  text: string;
begin
  result:= r.ReadValue(@valueType);
  if result <> JSONOK then exit;
  if valueType <> jvtString then exit(JSONTypeMismatch);

  text:= r.LastValue;
  if Length(text) <> 1 then exit(JSONTypeMismatch);

  case ti.Kind of
    tkChar:
      begin
        // an AnsiChar cannot hold anything above the single-byte range
        if ord(text[1]) > 255 then exit(JSONTypeMismatch);
        PByte(data)^:= ord(AnsiChar(text[1]));
      end;
    tkWChar:
      PWord(data)^:= ord(text[1]);
  else
    exit(JSONUnsupportedType);
  end;

  result:= JSONOK;
end;


//----------------------------------------------------------------------------------------------------------------------
// Integers
//----------------------------------------------------------------------------------------------------------------------
function LoadOrdinal(ti: PTypeInfo; data: Pointer): int64;
begin
  if ti.Kind = tkInt64 then exit(PInt64(data)^);
  case GetTypeData(ti)^.OrdType of
    otSByte: result:= PShortInt(data)^;
    otUByte: result:= PByte(data)^;
    otSWord: result:= PSmallInt(data)^;
    otUWord: result:= PWord(data)^;
    otSLong: result:= PInteger(data)^;
    otULong: result:= PCardinal(data)^;
  else
    result:= 0;
  end;
end;

procedure StoreOrdinal(ti: PTypeInfo; data: Pointer; value: int64);
begin
  if ti.Kind = tkInt64 then begin
    PInt64(data)^:= value;
    exit;
  end;
  case GetTypeData(ti)^.OrdType of
    otSByte: PShortInt(data)^:= ShortInt(value);
    otUByte: PByte(data)^:= byte(value);
    otSWord: PSmallInt(data)^:= smallint(value);
    otUWord: PWord(data)^:= word(value);
    otSLong: PInteger(data)^:= integer(value);
    otULong: PCardinal(data)^:= cardinal(value);
  end;
end;

// Cardinal and UInt64: RTTI reports their maximum as -1, because it does not
// fit the signed field it is kept in
function IsFullWidthUnsigned(ti: PTypeInfo): boolean;
var
  td: PTypeData;
begin
  result:= false;
  if ti = nil then exit;
  if not (ti.Kind in [tkInteger,tkInt64]) then exit;

  td:= GetTypeData(ti);
  if ti.Kind = tkInt64 then
    result:= (td.MinInt64Value = 0) and (td.MaxInt64Value = -1)
  else
    result:= (td.MinValue = 0) and (td.MaxValue = -1);
end;

// the destination's declared range, a subrange's included - a plain cast would
// turn 300 into a byte as 44
function InDeclaredRange(ti: PTypeInfo; v: int64): boolean;
var
  td: PTypeData;
begin
  td:= GetTypeData(ti);

  // a UInt64 never gets here: ParseInteger stores it on a path of its own
  if ti.Kind = tkInt64 then exit((v >= td.MinInt64Value) and (v <= td.MaxInt64Value));

  if IsFullWidthUnsigned(ti) then exit((v >= 0) and (v <= High(cardinal)));
  result:= (v >= td.MinValue) and (v <= td.MaxValue);
end;

function FormatInteger(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
begin
  // a UInt64 past High(Int64) would read as a negative int64
  if (ti.Kind = tkInt64) and IsFullWidthUnsigned(ti) then
    w.WriteDigits(PUInt64(data)^,false)
  else
    w.WriteInteger(LoadOrdinal(ti,data));

  exit(JSONOK);
end;

function ParseInteger(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  i: int64;
  u: UInt64;
  digit: cardinal;
  p,stop: PAnsiChar;
  len: integer;
  negative: boolean;
  vt: TJSONValueType;
begin
  result:= r.ReadValue(@vt);
  if result <> JSONOK then exit;
  if vt <> jvtNumber then exit(JSONTypeMismatch);
  // a real is refused, whole or not: the token's form decides, as in Go
  if r.NumberIsReal then exit(JSONTypeMismatch);

  // straight from the token's bytes, which the reader has checked against the
  // number grammar: an optional minus, then digits only
  p:= r.LastValueRaw(len);
  stop:= p + len;
  negative:= p^ = '-';
  if negative then inc(p);

  u:= 0;
  while p < stop do begin
    digit:= ord(p^) - ord('0');
    if (u > High(UInt64) div 10) or ((u = High(UInt64) div 10) and (digit > High(UInt64) mod 10)) then
      exit(JSONTypeMismatch);
    u:= u*10 + digit;
    inc(p);
  end;

  // the top of a UInt64's range does not fit an int64
  if (ti.Kind = tkInt64) and IsFullWidthUnsigned(ti) then begin
    if negative and (u <> 0) then exit(JSONTypeMismatch);
    PUInt64(data)^:= u;
    exit(JSONOK);
  end;

  if negative then begin
    if u > UInt64(High(int64)) + 1 then exit(JSONTypeMismatch);
    // Low(Int64) has no positive counterpart to negate
    if u = UInt64(High(int64)) + 1 then i:= Low(int64) else i:= -int64(u);
  end else begin
    if u > UInt64(High(int64)) then exit(JSONTypeMismatch);
    i:= u;
  end;

  // the destination's own range, not int64's
  if not(InDeclaredRange(ti,i)) then exit(JSONTypeMismatch);

  StoreOrdinal(ti,data,i);
end;


//----------------------------------------------------------------------------------------------------------------------
// Floats
//
// Shortest digits: Grisu2 (Loitsch, "Printing Floating-Point Numbers Quickly and
// Accurately with Integers", 2010). The digits always read back as the same
// float; now and then they are one longer than the shortest that would.
//----------------------------------------------------------------------------------------------------------------------
function LoadFloat(ti: PTypeInfo; data: Pointer): extended;
begin
  case GetTypeData(ti)^.FloatType of
    ftSingle: result:= PSingle(data)^;
    ftDouble: result:= PDouble(data)^;
    ftExtended: result:= PExtended(data)^;
    ftComp: result:= PComp(data)^;
    ftCurr: result:= PCurrency(data)^;
  else
    result:= 0;
  end;
end;

procedure StoreFloat(ti: PTypeInfo; data: Pointer; value: extended);
begin
  case GetTypeData(ti)^.FloatType of
    ftSingle: PSingle(data)^:= value;
    ftDouble: PDouble(data)^:= value;
    ftExtended: PExtended(data)^:= value;
    ftComp: PComp(data)^:= value;
    ftCurr: PCurrency(data)^:= value;
  end;
end;

type
  // a float as F * 2^E
  TDiyFp = record
    F: UInt64;
    E: integer;
  end;

  TCachedPower = record
    F: UInt64;
    E: smallint;
    K: smallint;
  end;

const
  // 10^K as F * 2^E, F rounded to 64 bits, for K = -300, -292 .. 324 - computed
  // with exact integers, and the same as the table published with the algorithm
  CACHED_POWERS: array[0..78] of TCachedPower = (
    (F: $AB70FE17C79AC6CA; E: -1060; K: -300),
    (F: $FF77B1FCBEBCDC4F; E: -1034; K: -292),
    (F: $BE5691EF416BD60C; E: -1007; K: -284),
    (F: $8DD01FAD907FFC3C; E:  -980; K: -276),
    (F: $D3515C2831559A83; E:  -954; K: -268),
    (F: $9D71AC8FADA6C9B5; E:  -927; K: -260),
    (F: $EA9C227723EE8BCB; E:  -901; K: -252),
    (F: $AECC49914078536D; E:  -874; K: -244),
    (F: $823C12795DB6CE57; E:  -847; K: -236),
    (F: $C21094364DFB5637; E:  -821; K: -228),
    (F: $9096EA6F3848984F; E:  -794; K: -220),
    (F: $D77485CB25823AC7; E:  -768; K: -212),
    (F: $A086CFCD97BF97F4; E:  -741; K: -204),
    (F: $EF340A98172AACE5; E:  -715; K: -196),
    (F: $B23867FB2A35B28E; E:  -688; K: -188),
    (F: $84C8D4DFD2C63F3B; E:  -661; K: -180),
    (F: $C5DD44271AD3CDBA; E:  -635; K: -172),
    (F: $936B9FCEBB25C996; E:  -608; K: -164),
    (F: $DBAC6C247D62A584; E:  -582; K: -156),
    (F: $A3AB66580D5FDAF6; E:  -555; K: -148),
    (F: $F3E2F893DEC3F126; E:  -529; K: -140),
    (F: $B5B5ADA8AAFF80B8; E:  -502; K: -132),
    (F: $87625F056C7C4A8B; E:  -475; K: -124),
    (F: $C9BCFF6034C13053; E:  -449; K: -116),
    (F: $964E858C91BA2655; E:  -422; K: -108),
    (F: $DFF9772470297EBD; E:  -396; K: -100),
    (F: $A6DFBD9FB8E5B88F; E:  -369; K:  -92),
    (F: $F8A95FCF88747D94; E:  -343; K:  -84),
    (F: $B94470938FA89BCF; E:  -316; K:  -76),
    (F: $8A08F0F8BF0F156B; E:  -289; K:  -68),
    (F: $CDB02555653131B6; E:  -263; K:  -60),
    (F: $993FE2C6D07B7FAC; E:  -236; K:  -52),
    (F: $E45C10C42A2B3B06; E:  -210; K:  -44),
    (F: $AA242499697392D3; E:  -183; K:  -36),
    (F: $FD87B5F28300CA0E; E:  -157; K:  -28),
    (F: $BCE5086492111AEB; E:  -130; K:  -20),
    (F: $8CBCCC096F5088CC; E:  -103; K:  -12),
    (F: $D1B71758E219652C; E:   -77; K:   -4),
    (F: $9C40000000000000; E:   -50; K:    4),
    (F: $E8D4A51000000000; E:   -24; K:   12),
    (F: $AD78EBC5AC620000; E:     3; K:   20),
    (F: $813F3978F8940984; E:    30; K:   28),
    (F: $C097CE7BC90715B3; E:    56; K:   36),
    (F: $8F7E32CE7BEA5C70; E:    83; K:   44),
    (F: $D5D238A4ABE98068; E:   109; K:   52),
    (F: $9F4F2726179A2245; E:   136; K:   60),
    (F: $ED63A231D4C4FB27; E:   162; K:   68),
    (F: $B0DE65388CC8ADA8; E:   189; K:   76),
    (F: $83C7088E1AAB65DB; E:   216; K:   84),
    (F: $C45D1DF942711D9A; E:   242; K:   92),
    (F: $924D692CA61BE758; E:   269; K:  100),
    (F: $DA01EE641A708DEA; E:   295; K:  108),
    (F: $A26DA3999AEF774A; E:   322; K:  116),
    (F: $F209787BB47D6B85; E:   348; K:  124),
    (F: $B454E4A179DD1877; E:   375; K:  132),
    (F: $865B86925B9BC5C2; E:   402; K:  140),
    (F: $C83553C5C8965D3D; E:   428; K:  148),
    (F: $952AB45CFA97A0B3; E:   455; K:  156),
    (F: $DE469FBD99A05FE3; E:   481; K:  164),
    (F: $A59BC234DB398C25; E:   508; K:  172),
    (F: $F6C69A72A3989F5C; E:   534; K:  180),
    (F: $B7DCBF5354E9BECE; E:   561; K:  188),
    (F: $88FCF317F22241E2; E:   588; K:  196),
    (F: $CC20CE9BD35C78A5; E:   614; K:  204),
    (F: $98165AF37B2153DF; E:   641; K:  212),
    (F: $E2A0B5DC971F303A; E:   667; K:  220),
    (F: $A8D9D1535CE3B396; E:   694; K:  228),
    (F: $FB9B7CD9A4A7443C; E:   720; K:  236),
    (F: $BB764C4CA7A44410; E:   747; K:  244),
    (F: $8BAB8EEFB6409C1A; E:   774; K:  252),
    (F: $D01FEF10A657842C; E:   800; K:  260),
    (F: $9B10A4E5E9913129; E:   827; K:  268),
    (F: $E7109BFBA19C0C9D; E:   853; K:  276),
    (F: $AC2820D9623BF429; E:   880; K:  284),
    (F: $80444B5E7AA7CF85; E:   907; K:  292),
    (F: $BF21E44003ACDD2D; E:   933; K:  300),
    (F: $8E679C2F5E44FF8F; E:   960; K:  308),
    (F: $D433179D9C8CB841; E:   986; K:  316),
    (F: $9E19DB92B4E31BA9; E:  1013; K:  324)
  );
  CACHED_POWERS_MIN_K = -300;
  CACHED_POWERS_K_STEP = 8;

  // the scaled upper bound's exponent lands in here, so its integral part is
  // a 32-bit number and its fraction leaves room to multiply by ten
  GRISU_ALPHA = -60;

function DiyFp(f: UInt64; e: integer): TDiyFp; inline;
begin
  result.F:= f;
  result.E:= e;
end;

// the upper 64 bits of the 128-bit product, rounded - from four 32-bit products
function DiyMul(const x,y: TDiyFp): TDiyFp;
var
  a,b,c,d,ac,ad,bc,bd,middle: UInt64;
begin
  a:= x.F shr 32;  b:= x.F and $FFFFFFFF;
  c:= y.F shr 32;  d:= y.F and $FFFFFFFF;
  ac:= a*c;  ad:= a*d;  bc:= b*c;  bd:= b*d;

  middle:= (bd shr 32) + (ad and $FFFFFFFF) + (bc and $FFFFFFFF) + (UInt64(1) shl 31);
  result.F:= ac + (ad shr 32) + (bc shr 32) + (middle shr 32);
  result.E:= x.E + y.E + 64;
end;

function DiyNormalize(x: TDiyFp): TDiyFp;
begin
  while (x.F shr 63) = 0 do begin
    x.F:= x.F shl 1;
    dec(x.E);
  end;
  result:= x;
end;

// steps the last digit towards w as long as the number stays inside the bounds
// and gets closer to w
procedure GrisuRound(last: PAnsiChar; dist,delta,rest,tenK: UInt64);
begin
  while (rest < dist) and (delta - rest >= tenK)
    and ((rest + tenK < dist) or (dist - rest > rest + tenK - dist)) do begin
    last^:= pred(last^);
    inc(rest,tenK);
  end;
end;

// the digits of w, no more than it takes to stay between mMinus and mPlus. k
// comes in as the cached power's exponent and leaves as the digits' exponent
function GrisuDigits(buf: PAnsiChar; const mMinus,w,mPlus: TDiyFp; var k: integer): integer;
var
  shift,n,m: integer;
  one,p2,delta,dist,rest: UInt64;
  p1,pow10: cardinal;
begin
  delta:= mPlus.F - mMinus.F;
  dist:= mPlus.F - w.F;
  shift:= -mPlus.E;
  one:= UInt64(1) shl shift;
  p1:= mPlus.F shr shift;
  p2:= mPlus.F and (one - 1);

  // the integral part, at most ten digits
  n:= 1;
  pow10:= 1;
  while (n < 10) and (p1 >= pow10*10) do begin
    pow10:= pow10*10;
    inc(n);
  end;

  result:= 0;
  while n > 0 do begin
    buf[result]:= AnsiChar(ord('0') + p1 div pow10);
    inc(result);
    p1:= p1 mod pow10;
    dec(n);
    rest:= (UInt64(p1) shl shift) + p2;
    if rest <= delta then begin
      inc(k,n);
      GrisuRound(buf + result - 1,dist,delta,rest,UInt64(pow10) shl shift);
      exit;
    end;
    pow10:= pow10 div 10;
  end;

  // the fraction, until the digits are inside the bounds
  m:= 0;
  repeat
    p2:= p2*10;
    buf[result]:= AnsiChar(ord('0') + (p2 shr shift));
    inc(result);
    p2:= p2 and (one - 1);
    inc(m);
    delta:= delta*10;
    dist:= dist*10;
  until p2 <= delta;
  dec(k,m);
  GrisuRound(buf + result - 1,dist,delta,p2,one);
end;

// the digits of the float v = F * 2^E, not zero; the value is digits * 10^k.
// lowerCloser: v is a power of two, so the float below is half as far away
function Grisu2(buf: PAnsiChar; const v: TDiyFp; lowerCloser: boolean; out k: integer): integer;
var
  w,mPlus,mMinus,c: TDiyFp;
  q,i: integer;
begin
  // halfway to the neighbours on either side
  mPlus:= DiyNormalize(DiyFp(2*v.F + 1,v.E - 1));
  if lowerCloser then
    mMinus:= DiyFp(4*v.F - 1,v.E - 2)
  else
    mMinus:= DiyFp(2*v.F - 1,v.E - 1);
  mMinus:= DiyFp(mMinus.F shl (mMinus.E - mPlus.E),mPlus.E);
  w:= DiyNormalize(v);

  // the cached 10^-K that brings mPlus's exponent into place; 78913/2^18 is
  // log10(2), rounded up
  q:= GRISU_ALPHA - mPlus.E - 1;
  i:= (q*78913) div (1 shl 18);
  if q > 0 then inc(i);
  i:= (-CACHED_POWERS_MIN_K + i + CACHED_POWERS_K_STEP - 1) div CACHED_POWERS_K_STEP;
  c:= DiyFp(CACHED_POWERS[i].F,CACHED_POWERS[i].E);
  k:= -CACHED_POWERS[i].K;

  w:= DiyMul(w,c);
  mPlus:= DiyMul(mPlus,c);
  mMinus:= DiyMul(mMinus,c);
  // one unit in from each bound: the products are rounded
  inc(mMinus.F);
  dec(mPlus.F);

  result:= GrisuDigits(buf,mMinus,w,mPlus,k);
end;

// a float in FloatToStr's layout, with Grisu2's digits: fixed up to 15
// integral digits and down to 0.0001, scientific with an E beyond that
procedure WriteShortest(w: PJSONWriter; const v: TDiyFp; lowerCloser,negative: boolean);
var
  digits: array[0..19] of AnsiChar;
  text: array[0..31] of AnsiChar;
  n,k,point,len,i,exponent: integer;

  procedure Add(c: AnsiChar);
  begin
    text[len]:= c;
    inc(len);
  end;

begin
  len:= 0;
  if negative then Add('-');

  if v.F = 0 then begin
    Add('0');
    w.PutRaw(@text,len,false);
    exit;
  end;

  n:= Grisu2(@digits,v,lowerCloser,k);
  point:= n + k; // where the decimal point goes, counted from the first digit

  if (point > 0) and (point <= 15) then begin
    for i:= 0 to n-1 do begin
      if i = point then Add('.');
      Add(digits[i]);
    end;
    for i:= n to point-1 do Add('0');
  end else
  if (point <= 0) and (point > -4) then begin
    Add('0');
    Add('.');
    for i:= point to -1 do Add('0');
    for i:= 0 to n-1 do Add(digits[i]);
  end else begin
    Add(digits[0]);
    if n > 1 then Add('.');
    for i:= 1 to n-1 do Add(digits[i]);
    Add('E');
    exponent:= point - 1;
    if exponent < 0 then begin
      Add('-');
      exponent:= -exponent;
    end;
    if exponent >= 100 then Add(AnsiChar(ord('0') + exponent div 100));
    if exponent >= 10 then Add(AnsiChar(ord('0') + (exponent div 10) mod 10));
    Add(AnsiChar(ord('0') + exponent mod 10));
  end;

  w.PutRaw(@text,len,false);
end;

// every float but a Currency goes out here. NaN and the infinities have no JSON
// form and are refused. A single and a double get the shortest digits that read
// back as them; an 80-bit extended on Win32 - more bits than Grisu2 takes - and
// a Comp still get FloatToStr's 15 digits, clamped below MaxDouble, because 15
// digits round the doubles just under it up to text that overflows.
function WriteFloatNumber(w: PJSONWriter; const v: extended; floatType: TFloatType): TJSONResult;
const
  LARGEST_15_DIGIT_DOUBLE = 1.79769313486231E308;
var
  e: extended;
  d: double;
  s: single;
  bits,fraction: UInt64;
  fractionBits,exponentBits,bias,biased: integer;
begin
  if IsNan(v) or IsInfinite(v) then exit(JSONTypeMismatch);
  result:= JSONOK;

  if (floatType = ftExtended) and (SizeOf(extended) = SizeOf(double)) then floatType:= ftDouble;

  case floatType of
  ftDouble: begin d:= v; bits:= PUInt64(@d)^;   fractionBits:= 52; exponentBits:= 11; end;
  ftSingle: begin s:= v; bits:= PCardinal(@s)^; fractionBits:= 23; exponentBits:= 8;  end;
  else
    e:= v;
    if (Abs(e) > LARGEST_15_DIGIT_DOUBLE) and (Abs(e) <= MaxDouble) then begin
      if e > 0 then e:= LARGEST_15_DIGIT_DOUBLE else e:= -LARGEST_15_DIGIT_DOUBLE;
    end;
    w.WriteRaw(FloatToStr(e,JSONFormatSettings));
    exit;
  end;

  // sign, biased exponent, fraction; the leading 1 is implied except in a
  // subnormal, whose exponent is the smallest a normal number has
  bias:= (1 shl (exponentBits-1)) - 1 + fractionBits;
  biased:= (bits shr fractionBits) and ((1 shl exponentBits) - 1);
  fraction:= bits and (UInt64(1) shl fractionBits - 1);
  if biased = 0 then
    WriteShortest(w,DiyFp(fraction,1 - bias),false,(bits shr (fractionBits+exponentBits)) <> 0)
  else
    WriteShortest(w,DiyFp(fraction + UInt64(1) shl fractionBits,biased - bias),
                  (fraction = 0) and (biased > 1),(bits shr (fractionBits+exponentBits)) <> 0);
end;

// exact, from the scaled int64: 15 float digits would round large amounts
procedure WriteCurrency(w: PJSONWriter; const c: Currency);
begin
  w.WriteRaw(CurrToStr(c,JSONFormatSettings));
end;

function FormatFloat(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
begin
  if GetTypeData(ti)^.FloatType = ftCurr then begin
    WriteCurrency(w,PCurrency(data)^);
    exit(JSONOK);
  end;
  result:= WriteFloatNumber(w,LoadFloat(ti,data),GetTypeData(ti)^.FloatType);
end;

const
  // the powers of ten a double holds exactly
  EXACT_POWERS_OF_TEN: array[0..22] of double = (
    1E0, 1E1, 1E2, 1E3, 1E4, 1E5, 1E6, 1E7, 1E8, 1E9, 1E10, 1E11,
    1E12, 1E13, 1E14, 1E15, 1E16, 1E17, 1E18, 1E19, 1E20, 1E21, 1E22);

// Clinger's fast path, on the token's bytes: when the digits fit a double's 53
// bits and the power of ten is exact as well, one multiplication or division
// rounds correctly. false for anything else, which the RTL then reads - more
// slowly, and not correctly rounded past 15 digits
function TryFastFloat(p: PAnsiChar; len: integer; out d: double): boolean;
const
  EXACT_LIMIT = UInt64(1) shl 53;
var
  stop: PAnsiChar;
  negative,inFraction,negativeExponent: boolean;
  m: UInt64;
  digits,exp10,e: integer;
  x: extended;
begin
  result:= false;
  stop:= p + len;
  negative:= p^ = '-';
  if negative then inc(p);

  // the reader has checked the grammar: digits, maybe a fraction, maybe an
  // exponent. Leading zeros are no digits; each fraction digit is a 10^-1
  m:= 0;
  digits:= 0;
  exp10:= 0;
  inFraction:= false;
  while (p < stop) and (p^ in ['0'..'9','.']) do begin
    if p^ = '.' then begin
      inFraction:= true;
    end else begin
      if (m <> 0) or (p^ <> '0') then begin
        if digits = 19 then exit;
        inc(digits);
        m:= m*10 + UInt64(ord(p^) - ord('0'));
      end;
      if inFraction then dec(exp10);
    end;
    inc(p);
  end;

  if p < stop then begin
    inc(p); // e or E
    negativeExponent:= p^ = '-';
    if p^ in ['+','-'] then inc(p);
    e:= 0;
    while p < stop do begin
      if e < 10000 then e:= e*10 + (ord(p^) - ord('0'));
      inc(p);
    end;
    if negativeExponent then dec(exp10,e) else inc(exp10,e);
  end;

  if m > EXACT_LIMIT then exit;
  if m = 0 then begin
    d:= 0;
    if negative then d:= -d;
    exit(true);
  end;

  // 1E30 is 10^8 * 1E22, and fine while m * 10^8 stays exact
  while (exp10 > 22) and (m <= EXACT_LIMIT div 10) do begin
    m:= m*10;
    dec(exp10);
  end;
  if (exp10 > 22) or (exp10 < -22) then exit;

  x:= m;
  if exp10 >= 0 then
    x:= x*EXACT_POWERS_OF_TEN[exp10]
  else
    x:= x/EXACT_POWERS_OF_TEN[-exp10];

  // Win32 computes in 80 bits and rounds to 53 again on the way out. That
  // second rounding goes wrong only from a result exactly halfway between two
  // doubles - low 11 bits $400 - so those few go to the RTL. Setting the FPU
  // to double precision instead would mean Set8087CW, which writes the global
  // Default8087CW and races between threads
  if (SizeOf(extended) > SizeOf(double)) and ((PUInt64(@x)^ and $7FF) = $400) then exit;

  d:= x;
  if negative then d:= -d;
  result:= true;
end;

// the token's number: the fast path where it applies, else the RTL, which
// refuses what overflows a double
function TokenToFloat(r: PJSONReader; out d: double): boolean;
var
  p: PAnsiChar;
  len: integer;
begin
  p:= r.LastValueRaw(len);
  if TryFastFloat(p,len,d) then exit(true);
  result:= TryStrToFloat(r.LastValue,d,JSONFormatSettings);
end;

function ParseFloat(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
const
  // MaxSingle plus half an ulp: the shortest text for MaxSingle, 3.4028235E38,
  // lies just above it and has to read back
  SINGLE_OVERFLOW = 3.4028235677973366E38;
  COMP_OVERFLOW = 9223372036854775808.0;
var
  d: extended;
  fd: double;
  c: Currency;
  vt: TJSONValueType;
begin
  result:= r.ReadValue(@vt);
  if result <> JSONOK then exit;
  if vt <> jvtNumber then exit(JSONTypeMismatch);

  // read as a scaled int64: TryStrToCurr checks the range, an extended would not
  if GetTypeData(ti)^.FloatType = ftCurr then begin
    if not(TryStrToCurr(r.LastValue,c,JSONFormatSettings)) then exit(JSONTypeMismatch);
    PCurrency(data)^:= c;
    exit;
  end;

  // the token is a valid number, so a failure here is overflow. An 80-bit
  // extended on Win32 holds more than a double, so it skips the fast path
  if (GetTypeData(ti)^.FloatType = ftExtended) and (SizeOf(extended) > SizeOf(double)) then begin
    if not(TryStrToFloat(r.LastValue,d,JSONFormatSettings)) then exit(JSONTypeMismatch);
  end else begin
    if not(TokenToFloat(r,fd)) then exit(JSONTypeMismatch);
    d:= fd;
  end;

  // the destination's range, not extended's - which is 80 bits on Win32
  case GetTypeData(ti)^.FloatType of
    ftSingle: if Abs(d) >= SINGLE_OVERFLOW then exit(JSONTypeMismatch);
    ftDouble: if Abs(d) > MaxDouble then exit(JSONTypeMismatch);
    ftComp:   if Abs(d) >= COMP_OVERFLOW then exit(JSONTypeMismatch);
  end;

  StoreFloat(ti,data,d);
end;


//----------------------------------------------------------------------------------------------------------------------
// Booleans and enumerations
//----------------------------------------------------------------------------------------------------------------------
function IsBooleanType(ti: PTypeInfo): boolean;
begin
  result:= (ti = System.TypeInfo(boolean))
        or (ti = System.TypeInfo(ByteBool))
        or (ti = System.TypeInfo(WordBool))
        or (ti = System.TypeInfo(LongBool));
end;

function FormatEnum(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  v: int64;
  name: PByte;
begin
  v:= LoadOrdinal(ti,data);

  if IsBooleanType(ti) then begin
    w.WriteBoolean(v <> 0);
    exit(JSONOK);
  end;

  // a value past the last member - set by a cast - has no name
  if (v < GetTypeData(ti).MinValue) or (v > GetTypeData(ti).MaxValue) then exit(JSONTypeMismatch);

  // the name list GetEnumName walks: UTF-8 ShortStrings, one per member from
  // ordinal 0 of the base type. An identifier needs no escaping.
  name:= @GetTypeData(GetTypeData(ti).BaseType^).NameList;
  while v > 0 do begin
    inc(name,name^+1);
    dec(v);
  end;

  w.PutRaw(name+1,name^,true);
  result:= JSONOK;
end;

// a member's name, as FormatEnum and FormatSet write it: a string, and inside
// the declared range - GetEnumValue looks a name up among the base type's, so
// a subrange is held to its own here. An unknown name answers -1, below any
// MinValue
function ReadEnumName(r: PJSONReader; enumType: PTypeInfo; out e: integer): TJSONResult;
var
  vt: TJSONValueType;
begin
  result:= r.ReadValue(@vt);
  if result <> JSONOK then exit;
  if vt <> jvtString then exit(JSONTypeMismatch);

  e:= System.TypInfo.GetEnumValue(enumType,r.LastValue);
  if (e < GetTypeData(enumType).MinValue) or (e > GetTypeData(enumType).MaxValue) then
    exit(JSONTypeMismatch);
end;

function ParseEnum(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  e: integer;
  vt: TJSONValueType;
begin
  if IsBooleanType(ti) then begin
    result:= r.ReadValue(@vt);
    if result <> JSONOK then exit;
    // only the bare literals: in quotes, true is a string
    case vt of
      jvtTrue:  StoreOrdinal(ti,data,1);
      jvtFalse: StoreOrdinal(ti,data,0);
    else
      result:= JSONTypeMismatch;
    end;
    exit;
  end;

  result:= ReadEnumName(r,ti,e);
  if result <> JSONOK then exit;
  StoreOrdinal(ti,data,e);
end;


//----------------------------------------------------------------------------------------------------------------------
// Sets
//
// a set is a bitmap over the ordinals of its base type, starting at
// ByteOffsetOfSet. only an enumeration base is taken: the wire form is an array
// of member names.
//----------------------------------------------------------------------------------------------------------------------
type
  TSetInfo = record
    BaseType: PTypeInfo;
    MinValue: integer;
    MaxValue: integer;
    ByteOffset: integer;
    Size: integer;
  end;

function GetSetInfo(ti: PTypeInfo; out info: TSetInfo): boolean;
var
  ref: PPTypeInfo;
  td: PTypeData;
begin
  result:= false;
  info:= Default(TSetInfo);
  if ti = nil then exit;
  if ti.Kind <> tkSet then exit;

  ref:= GetTypeData(ti)^.CompType;
  if ref = nil then exit;
  info.BaseType:= ref^;
  if info.BaseType = nil then exit;
  if info.BaseType.Kind <> tkEnumeration then exit;

  td:= GetTypeData(info.BaseType);
  info.MinValue:= td.MinValue;
  info.MaxValue:= td.MaxValue;
  info.ByteOffset:= ByteOffsetOfSet(ti);
  info.Size:= SizeOfSet(ti);

  result:= (info.Size > 0) and (info.MaxValue >= info.MinValue);
end;

// the names of the members held, in declaration order
function FormatSet(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  info: TSetInfo;
  e: integer;
begin
  if not GetSetInfo(ti,info) then exit(JSONUnsupportedType);

  result:= w.BeginArray();
  if result <> JSONOK then exit;

  // every bit of the storage, not only the members' range: a spare bit set by
  // a cast is a member nobody can name, so it is refused
  for e:= info.ByteOffset*8 to (info.ByteOffset+info.Size)*8-1 do begin
    if (PByte(data)[(e shr 3) - info.ByteOffset] and (1 shl (e and 7))) = 0 then continue;
    if (e < info.MinValue) or (e > info.MaxValue) then exit(JSONTypeMismatch);

    w.WriteString(GetEnumName(info.BaseType,e));
  end;

  result:= w.EndArray();
end;

// the forgiving mirror of FormatSet: null and [] are both the empty set, and a
// name given twice is no error. an unknown name or a non-string is refused.
type
  TSetWalk = record
    Data: Pointer;
    Info: TSetInfo;
  end;
  PSetWalk = ^TSetWalk;

function SetElement(ctx: Pointer; j: TJSONCodec; r: PJSONReader; index: integer): TJSONResult;
var
  w: PSetWalk;
  e: integer;
begin
  w:= ctx;

  result:= ReadEnumName(r,w.Info.BaseType,e);
  if result <> JSONOK then exit;

  var b : PByte := @PByte(w.data)[(e shr 3) - w.info.ByteOffset];
  b^:= b^ or (1 shl (e and 7));
end;

function ParseSet(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  w: TSetWalk;
begin
  if not GetSetInfo(ti,w.Info) then exit(JSONUnsupportedType);
  w.Data:= data;

  // emptied before the shape is known, as a TList is cleared: a refused
  // document leaves it empty
  FillChar(data^,w.Info.Size,0);

  // 'n' can only begin "null", and ReadLiteral is what decides that
  if r.PeekNextToken = 'n' then exit(r.ReadValue);

  result:= WalkAggregate(j,r,'[',@w,SetElement);
end;


//----------------------------------------------------------------------------------------------------------------------
// TDateTime, TGUID and TColor
//
// Registered by name in TJSONCodec.Create, so these win over the handlers for their
// kind.
//----------------------------------------------------------------------------------------------------------------------
// every TDateTime goes out here, field or variant alike. A NaN or a day outside
// MinDateTime..MaxDateTime has no text and is refused, after the UTC conversion too.
function WriteDateTime(w: PJSONWriter; const d: TDateTime): TJSONResult;
var
  utc: TDateTime;
begin
  if IsNan(d) or (d < MinDateTime) or (d > MaxDateTime) then exit(JSONTypeMismatch);
  if w.Config.DateTimeIsUTC then begin
    utc:= d;
  end else begin
    utc:= TTimeZone.Local.ToUniversalTime(d);
    if (utc < MinDateTime) or (utc > MaxDateTime) then exit(JSONTypeMismatch);
  end;

  case w.Config.DateTimeFormat of
    jdfEpoch:
      w.WriteInteger(Round((utc-UnixDateDelta)*SecsPerDay));
    jdfEpochMillis:
      w.WriteInteger(Round((utc-UnixDateDelta)*MSecsPerDay));
  else
    w.WriteString(utc.ToISO8601(true));
  end;
  result:= JSONOK;
end;

function FormatDateTime(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
begin
  result:= WriteDateTime(w,TDateTime(LoadFloat(ti,data)));
end;

// goes by the token, not by DateTimeFormat: a string is ISO 8601, a number an
// epoch in the config's unit. a TDate or TTime is cut after the zone
// conversion, or a local midnight could land on the day before.
function ParseDateTime(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  vt: TJSONValueType;
  f: double;
  d: TDateTime;
begin
  result:= r.ReadValue(@vt);
  if result <> JSONOK then exit;

  if vt = jvtNumber then begin
    if not TokenToFloat(r,f) then exit(JSONTypeMismatch);
    if r.Config.DateTimeFormat = jdfEpochMillis then
      f:= f/MSecsPerDay
    else
      f:= f/SecsPerDay;
    d:= UnixDateDelta+f;
    if not(r.Config.DateTimeIsUTC) then d:= TTimeZone.Local.ToLocalTime(d);
  end else begin
    if vt <> jvtString then exit(JSONTypeMismatch);
    try
      d:= System.DateUtils.ISO8601ToDate(r.LastValue,r.Config.DateTimeIsUTC);
    except on E: Exception do
      // a well-formed JSON string that is not a date
      exit(JSONTypeMismatch);
    end;
  end;

  if ti = System.TypeInfo(TDate) then
    d:= DateOf(d)
  else if ti = System.TypeInfo(TTime) then
    d:= TimeOf(d);
  StoreFloat(ti,data,d);
end;

// lower case, as RFC 4122 asks of output; ParseGUID takes either case
function FormatGUID(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  P: PGUID;
  s: string;
begin
  p:= data;
  s:= LowerCase(GUIDToString(p^));
  w.WriteString(Copy(s,2,Length(s)-2));
  exit(JSONOK);
end;

function ParseGUID(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  vt: TJSONValueType;
begin
  result:= r.ReadValue(@vt);
  if result <> JSONOK then exit;
  if vt <> jvtString then exit(JSONTypeMismatch);

  try
    PGUID(data)^:= StringToGUID('{' + r.LastValue + '}');
  except on E: Exception do
    // a well-formed JSON string that is not a GUID
    exit(JSONTypeMismatch);
  end;
end;

// TColor is $00BBGGRR, so the bytes are swapped for #rrggbb. A system colour
// has the high byte set and no RGB value, so it is refused.
function FormatColor(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  v: int64;
begin
  v:= LoadOrdinal(ti,data);
  if (v < 0) or (v > $FFFFFF) then exit(JSONTypeMismatch);

  w.WriteString(LowerCase('#'
    + IntToHex(v and $FF,2)          // red   - the low byte
    + IntToHex((v shr 8) and $FF,2)  // green
    + IntToHex((v shr 16) and $FF,2) // blue  - the high byte
  ));

  result:= JSONOK;
end;

function ParseColor(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  valueType: TJSONValueType;
  text: PAnsiChar;
  len,i,digit: integer;
  rgb: integer;
begin
  result:= r.ReadValue(@valueType);
  if result <> JSONOK then exit;
  if valueType <> jvtString then exit(JSONTypeMismatch);

  // raw UTF-8: a colour is ASCII
  text:= r.LastValueRaw(len);
  if (len <> 7) or (text[0] <> '#') then exit(JSONTypeMismatch);

  // by hand: TryStrToInt would also take a sign and whitespace
  rgb:= 0;
  for i:= 1 to 6 do begin
    digit:= HexDigit(text[i]);
    if digit < 0 then exit(JSONTypeMismatch);
    rgb:= (rgb shl 4) or digit;
  end;

  // #RRGGBB back to $00BBGGRR
  StoreOrdinal(ti,data,
      ((rgb and $FF) shl 16)        // blue
    or (rgb and $FF00)              // green
    or ((rgb shr 16) and $FF));     // red

  result:= JSONOK;
end;


//----------------------------------------------------------------------------------------------------------------------
// Pointers
//----------------------------------------------------------------------------------------------------------------------
function FormatPointer(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  refType: PPTypeInfo;
  formatter: TJSONFormatter;
begin
  // never untyped - that one has no handler - but its target may lack type info
  refType:= GetTypeData(ti)^.RefType;
  if refType = nil then exit(JSONUnsupportedType);

  formatter:= j.GetFormatterForTypeInfo(refType^);
  if not(assigned(formatter)) then exit(JSONUnsupportedType);

  if PPointer(data)^ = nil then begin
    w.WriteNull;
    exit(JSONOK);
  end;

  result:= formatter(j,w,refType^,PPointer(data)^);
end;

// for the targets ParsePointer allocates
function TypeSize(ti: PTypeInfo): integer;
begin
  case ti.Kind of
    tkInteger,tkChar,tkWChar,tkEnumeration:
      case GetTypeData(ti)^.OrdType of
        otSByte,otUByte: result:= 1;
        otSWord,otUWord: result:= 2;
      else
        result:= 4;
      end;
    tkSet:
      // not OrdType: for a set that byte holds the size, past four bytes
      result:= SizeOfSet(ti);
    tkInt64:
      result:= 8;
    tkFloat:
      case GetTypeData(ti)^.FloatType of
        ftSingle: result:= 4;
        ftExtended: result:= SizeOf(extended);
      else
        result:= 8; // ftDouble, ftComp, ftCurr
      end;
    tkRecord,tkMRecord:
      result:= GetTypeData(ti)^.RecSize;
    tkArray:
      result:= GetTypeData(ti)^.ArrayData.Size;
    tkString:
      result:= GetTypeData(ti)^.MaxLength + 1;
    tkVariant:
      result:= SizeOf(Variant);
    tkMethod:
      result:= SizeOf(TMethod);
  else
    // classes, interfaces, all long strings, dynamic arrays, pointers
    result:= SizeOf(Pointer);
  end;
end;

function ParsePointer(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  refType: PPTypeInfo;
  referredType: PTypeInfo;
  parser: TJSONParser;
  ptr: Pointer;
  freeOnError: boolean;
begin
  // never untyped - that one has no handler - but its target may lack type info
  refType:= GetTypeData(ti)^.RefType;
  if refType = nil then exit(JSONUnsupportedType);
  referredType:= refType^;

  parser:= j.GetParserForTypeInfo(referredType);
  if not(assigned(parser)) then exit(JSONUnsupportedType);

  // null reads back as nil, as FormatPointer writes nil. the target is dropped,
  // never freed: it may come from New, AllocMem or a local
  if r.PeekNextToken = 'n' then begin
    result:= r.ReadValue;
    if result <> JSONOK then exit;
    PPointer(data)^:= nil;
    exit;
  end;

  ptr:= PPointer(data)^;
  freeOnError:= false;
  if ptr = nil then begin
    // zero-filled, plus a record's Initialize operator, as New would run it
    ptr:= AllocMem(TypeSize(referredType));
    if IsManaged(referredType) then InitializeArray(ptr,referredType,1);
    PPointer(data)^:= ptr;
    freeOnError:= true;
  end;

  result:= parser(j,r,referredType,ptr);

  if (result <> JSONOK) and freeOnError then begin
    // release what the parser filled, or freeing the block leaks it
    if IsManaged(referredType) then FinalizeArray(ptr,referredType,1);
    FreeMem(ptr,TypeSize(referredType));
    PPointer(data)^:= nil;
  end;
end;


//----------------------------------------------------------------------------------------------------------------------
// Arrays
//----------------------------------------------------------------------------------------------------------------------
type
  TArrayShape = record
    ElementType: PTypeInfo;
    ElementSize: integer;
    Count: NativeInt;   // a static array's length; 0 for a dynamic one
  end;

// what both sides need of an array type. false without an element type: a
// named array of an enumeration with explicit values has type info, but none
// for its element
function GetArrayShape(ti: PTypeInfo; out s: TArrayShape): boolean;
var
  td: PTypeData;
  elementRef: PPTypeInfo;
begin
  result:= false;
  td:= GetTypeData(ti);
  case ti.Kind of
    tkDynArray:
      begin
        // DynArrElType, not elType/elType2: for an array of arrays those drill
        // down to the innermost element
        elementRef:= td.DynArrElType;
        s.ElementSize:= td.elSize;
        s.Count:= 0;
      end;
    tkArray:
      begin
        elementRef:= td.ArrayData.ElType;
        s.Count:= td.ArrayData.ElCount;
        s.ElementSize:= td.ArrayData.Size div s.Count;
      end;
  else
    exit;
  end;
  if (elementRef = nil) or (elementRef^ = nil) then exit;
  s.ElementType:= elementRef^;
  result:= true;
end;

// the elements of an array or a TList, laid out one after another
function WriteElements(j: TJSONCodec; w: PJSONWriter; formatter: TJSONFormatter; elementType: PTypeInfo;
                       elements: PByte; elementSize: integer; count: NativeInt): TJSONResult;
begin
  result:= w.BeginArray();
  if result <> JSONOK then exit;

  for var i:= 0 to count-1 do begin
    result := formatter(j,w,elementType,elements);
    if result <> JSONOK then exit;
    inc(elements,elementSize);
  end;

  result:= w.EndArray();
end;

function FormatArray(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  shape: TArrayShape;
  elements: PByte;
  formatter: TJSONFormatter;
begin
  if not GetArrayShape(ti,shape) then exit(JSONUnsupportedType);
  if ti.Kind = tkDynArray then begin
    elements:= PPointer(data)^;
    shape.Count:= DynArraySize(elements);
  end else
    elements:= data;

  formatter:= j.GetFormatterForTypeInfo(shape.ElementType);
  if not(assigned(formatter)) then exit(JSONUnsupportedType);

  result:= WriteElements(j,w,formatter,shape.ElementType,elements,shape.ElementSize,shape.Count);
end;

const
  DYNARRAY_INITIALSIZE = 16;
  DYNARRAY_MAXGROW = 1048576;

type
  TArrayWalk = record
    TypeInfo: PTypeInfo;
    Data: Pointer;
    ElementType: PTypeInfo;
    ElementParser: TJSONParser;
    ElementSize: integer;
    Size: NativeInt;    // slots available
    Count: integer;     // slots filled
    IsDynamic: boolean;
  end;
  PArrayWalk = ^TArrayWalk;

function ArrayElement(ctx: Pointer; j: TJSONCodec; r: PJSONReader; index: integer): TJSONResult;
var
  w: PArrayWalk;
  elements: PByte;
begin
  w:= ctx;

  if index >= w.Size then begin
    // a static array cannot grow: the document has too many elements
    if not(w.IsDynamic) then exit(JSONTypeMismatch);

    // doubling from DYNARRAY_INITIALSIZE, then in steps of DYNARRAY_MAXGROW
    if w.Size = 0 then begin
      w.Size:= DYNARRAY_INITIALSIZE;
    end else begin
      if w.Size < DYNARRAY_MAXGROW then begin
        w.Size:= w.Size*2;
      end else begin
        w.Size:= w.Size+DYNARRAY_MAXGROW;
      end;
    end;
    DynArraySetLength(PPointer(w.Data)^,w.TypeInfo,1,@w.Size);
  end;

  // re-read after every grow: the block may have moved
  if w.IsDynamic then elements:= PPointer(w.Data)^ else elements:= w.Data;

  result:= w.ElementParser(j,r,w.ElementType,elements + index*w.ElementSize);
  if result = JSONOK then w.Count:= index+1;
end;

function ParseArray(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  w: TArrayWalk;
  shape: TArrayShape;
begin
  if not GetArrayShape(ti,shape) then exit(JSONUnsupportedType);

  w:= Default(TArrayWalk);
  w.TypeInfo:= ti;
  w.Data:= data;
  w.IsDynamic:= (ti.Kind = tkDynArray);
  w.ElementType:= shape.ElementType;
  w.ElementSize:= shape.ElementSize;
  w.Size:= shape.Count;

  // replaced, as an assignment would: a dynamic array is shared, and filling
  // it in place changed every other variable holding it
  if w.IsDynamic then DynArrayClear(PPointer(data)^,ti);

  w.ElementParser:= j.GetParserForTypeInfo(w.ElementType);
  if not(assigned(w.ElementParser)) then exit(JSONUnsupportedType);

  result:= WalkAggregate(j,r,'[',@w,ArrayElement);

  if w.IsDynamic then begin
    // the array grows ahead of the elements; the zero-filled slack is cut off,
    // on a failure too
    if w.Count < w.Size then begin
      w.Size:= w.Count;
      DynArraySetLength(PPointer(data)^,ti,1,@w.Size);
    end;
  end else begin
    if result <> JSONOK then exit;

    // a static array's length is part of its type, so the document must match
    // it exactly; too many elements already failed in the walk
    if w.Count <> w.Size then exit(JSONTypeMismatch);
  end;
end;


//----------------------------------------------------------------------------------------------------------------------
// The type cache
//
// What the unit knows about a type, worked out once per codec: its handler, and
// for a record or class its members - name, key, offset, handler. Asking RTTI
// each time is slow and allocates; a lookup here is a pointer scan, read
// without a lock and filled under one.
//----------------------------------------------------------------------------------------------------------------------
type
  TMemberInfo = record
    Member: TRttiNamedObject;
    Name: string;
    Key: UTF8String;
    KeyPtr: PAnsiChar;
    KeyLen: integer;
    Func: Pointer;
    OmitEmpty: boolean;
    TypeInfo: PTypeInfo;
    Offset: integer;      // -1 if its a property, >= 0 for fields
  end;
  PMemberInfo = ^TMemberInfo;

  // allocated once, never moved or copied - so it may hold managed fields. A
  // lock-free reader reads its arrays in place: a local copy of one would
  // write their shared reference count on every lookup
  TCachedType = record
    Handler: Pointer;                // the type's own formatter or parser, nil if it has none
    Members: TArray<TMemberInfo>;    // only where Handler is FormatStruct or ParseStruct
    WriteOrder: TArray<PMemberInfo>; // the encode order: declaration order, or sorted with SortKeys; nil on a parse cache
  end;
  PCachedType = ^TCachedType;

  // what the lock-free scan reads; only these move when the index grows
  TTypeCacheEntry = record
    Handle: PTypeInfo;
    Info: PCachedType;
  end;
  PTypeCacheEntry = ^TTypeCacheEntry;

  TTypeCacheIndex = record
    Len: integer;
    Cap: integer;
    First: TTypeCacheEntry;
  end;
  PTypeCacheIndex = ^TTypeCacheIndex;

  TTypeCache = class
  private
    Items: PTypeCacheIndex;
    Retired: array of PTypeCacheIndex;
    Lock: TCriticalSection;
    ForWriting: boolean;
    SortKeys: boolean;
    function Build(ti: PTypeInfo; j: TJSONCodec): PCachedType;
  public
    constructor Create(aForWriting,aSortKeys: boolean);
    destructor Destroy; override;
    function Get(ti: PTypeInfo; j: TJSONCodec): PCachedType;
  end;

constructor TTypeCache.Create(aForWriting,aSortKeys: boolean);
const
  initialCapacity = 16;
begin
  Lock:= TCriticalSection.Create;
  Items:= AllocMem( initialCapacity*SizeOf(TTypeCacheEntry) + SizeOf(TTypeCacheIndex));
  Items.Len:= 0;
  Items.Cap:= initialCapacity;
  ForWriting:= aForWriting;
  SortKeys:= aSortKeys;
end;

destructor TTypeCache.Destroy;
var
  e: PTypeCacheEntry;
begin
  // the infos belong to the live index; a retired one only pointed at them too
  e:= @Items.First;
  for var i:= 0 to Items.Len-1 do begin
    Dispose(e.Info);
    inc(e);
  end;
  FreeMem(Items);

  for var i:= 0 to Length(Retired)-1 do begin
    FreeMem(Retired[i]);
  end;
  Lock.Free;
  inherited;
end;

function TTypeCache.Get(ti: PTypeInfo; j: TJSONCodec): PCachedType;
var
  e: PTypeCacheEntry;
  numBefore,numAfter: integer;
  newCap: integer;
  curItems: PTypeCacheIndex;
begin
  if ti = nil then exit(nil);

  // Items is read once, so Len and the entries come from the same block; the
  // barrier keeps the reads after Len on weakly ordered CPUs
  curItems:= Items;
  numBefore:= curItems.Len;
  {$IF not (defined(CPUX86) or defined(CPUX64))}
  MemoryBarrier;
  {$ENDIF}
  e:= @curItems.First;
  for var i:= 0 to numBefore-1 do begin
    if e.Handle = ti then exit(e.Info) else inc(e);
  end;

  Lock.Enter;

  // another thread may have added it while this one waited for the lock
  numAfter:= Items.Len;
  e:= @Items.First;
  inc(e,numBefore);
  for var i:= numBefore to numAfter-1 do begin
    if e.Handle = ti then begin
      Lock.Leave;
      exit(e.Info);
    end;
    inc(e);
  end;

  // complete before its entry is published: a reader that finds the entry
  // finds the info filled
  result:= Build(ti,j);

  // a full index is copied into a bigger one and retired, not freed: readers
  // may still be scanning it
  if numAfter = Items.Cap then begin
    newCap:= Items.Cap+Items.Cap;
    var newItems: PTypeCacheIndex := AllocMem(newCap*SizeOf(TTypeCacheEntry)+SizeOf(TTypeCacheIndex));
    newItems.Len:= numAfter;
    newItems.Cap:= newCap;
    Move(Items.First,newItems.First,numAfter*SizeOf(TTypeCacheEntry));

    SetLength(Retired,Length(Retired)+1);
    Retired[Length(Retired)-1]:= Items;

    AtomicExchange(Items,newItems);
  end;

  e:= @Items.First;
  inc(e,numAfter);
  e.Handle:= ti;
  e.Info:= result;
  AtomicIncrement(Items.Len);
  Lock.Leave;
end;

constructor JSONAttribute.Create(const aname: string; aomitempty: boolean = false);
begin
  Name:= aname;
  OmitEmpty:= aomitempty;
end;

function GetJSONAttribute(field: TRttiMember): JSONAttribute;
begin
  for var a in field.GetAttributes() do
    if a is JSONAttribute then exit(JSONAttribute(a));
  result:= NullAttribute;
end;

procedure PrepareKey(m: PMemberInfo; memberName: string; attrName: string;forWriting: boolean);
var
  w: TJSONWriter;
begin
  if Length(attrName) = 0 then begin
    m.Name:= memberName;
  end else begin
    m.Name:= attrName;
  end;

  // Name stays unescaped to match incoming keys; Key is the escaped output form
  if forWriting then begin
    // escaped by the writer itself, so a key cannot come out unlike a value
    w.Reset('');
    w.PutText(m.Name,true);
    w.WriteChar(':');
    SetLength(w.BufferString,w.Buffer-PByte(w.BufferString));
    m.Key:= w.BufferString;

  end else begin
    m.Key:= UTF8String(m.Name);
  end;
  m.KeyPtr:= PAnsiChar(m.Key);
  m.KeyLen:= Length(m.Key);
end;

// ordinal by name; a tie goes to the earlier member, by address. Must return 0
// for a = b - the partition in TArray.Sort uses the pivot as its sentinel.
function CompareMemberNames(const a,b: PMemberInfo): integer;
begin
  result:= CompareStr(a.Name,b.Name);
  if result <> 0 then exit;
  result:= NativeInt(a) - NativeInt(b);
end;

function TypeDepth(t: TRttiType): integer;
begin
  result:= 0;
  while t.BaseType <> nil do begin
    inc(result);
    t:= t.BaseType;
  end;
end;

// a member redeclared further down the hierarchy hides this one, so a name goes
// out once; a skipped redeclaration hides too - [JSON('-')] property RefCount;
function IsHidden(member: TRttiMember; const fields: TArray<TRttiField>; const props: TArray<TRttiProperty>): boolean;

  function Hides(other: TRttiMember): boolean;
  begin
    result:= (other <> member)
      and (other.Visibility in [mvPublic,mvPublished])
      and SameText(other.Name,member.Name)
      and (TypeDepth(other.Parent) > TypeDepth(member.Parent));
  end;

var
  f: TRttiField;
  p: TRttiProperty;
begin
  for f in fields do if Hides(f) then exit(true);
  for p in props do if Hides(p) then exit(true);
  result:= false;
end;

function FormatStruct(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult; forward;

function ParseStruct(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult; forward;

// the handlers of a member Delphi emits no type info for
function FormatWithoutTypeInfo(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
begin
  result:= JSONUnsupportedType;
end;

function ParseWithoutTypeInfo(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
begin
  result:= JSONUnsupportedType;
end;

function TTypeCache.Build(ti: PTypeInfo; j: TJSONCodec): PCachedType;
var
  a: TRttiType;
  i: integer;
  attr: JSONAttribute;

  fields: TArray<TRttiField>;
  props: TArray<TRttiProperty>;

  m: PMemberInfo;
  c: integer;

  // a slot is taken by inc(m); a member refused before that leaves it to the next
  procedure FillMemberInfo(member: TRttiDataMember);
  begin
    if ForWriting and not(member.IsReadable) then exit;
    // a read-only class property is filled through its getter - SetValueByKey
    if not(ForWriting) and not(member.IsWritable)
       and not(member.IsReadable and (member.DataType <> nil) and (member.DataType.TypeKind = tkClass)) then exit;
    if not(member.Visibility in [mvPublic,mvPublished]) then exit;
    if IsHidden(member,fields,props) then exit;

    attr:= GetJSONAttribute(member); if attr.Name = '-' then exit;

    // no handler means skipped; no type info means refused - an inline static
    // array is expected in the document, an interface is not
    if member.DataType = nil then begin
      if ForWriting then m.Func:= @FormatWithoutTypeInfo else m.Func:= @ParseWithoutTypeInfo;
      // its handler touches nothing, so it gets an address, and no getter runs
      m.OmitEmpty:= false;
      m.TypeInfo:= nil;
      m.Offset:= 0;
    end else begin
      m.Func:= j.GetHandlerForType(member.DataType,ForWriting);
      if m.Func = nil then exit;
      m.OmitEmpty:= attr.OmitEmpty;
      m.TypeInfo:= member.DataType.Handle;
      if member is TRttiField then m.Offset:= TRttiField(member).Offset else m.Offset:= -1;
    end;
    m.Member:= member;

    PrepareKey(m,member.Name,attr.Name,ForWriting);

    inc(m);
    inc(c);
  end;
begin
  New(result);
  a:= RCTX.GetType(ti);

  // every type a handler is asked for is kept here, not only structs: an array
  // or container looks up its element's handler once per value, for the same
  // answer every time
  result.Handler:= j.GetHandlerForType(a,ForWriting);

  // members only for the types FormatStruct and ParseStruct walk
  if (result.Handler <> @FormatStruct) and (result.Handler <> @ParseStruct) then exit;

  fields:= a.GetFields();
  props:= a.GetProperties();

  SetLength(result.Members,Length(fields)+Length(props));
  m:= Pointer(result.Members);
  c:= 0;
  for i:= 0 to High(fields) do FillMemberInfo(fields[i]);
  for i:= 0 to High(props) do FillMemberInfo(props[i]);
  SetLength(result.Members,c);

  // seeded in declaration order, which the members' addresses follow: the
  // tiebreak in CompareMemberNames relies on it
  if ForWriting then begin
    SetLength(result.WriteOrder,c);
    for i:= 0 to c-1 do result.WriteOrder[i]:= @result.Members[i];
    if SortKeys then
      TArray.Sort<PMemberInfo>(result.WriteOrder,TComparer<PMemberInfo>.Construct(CompareMemberNames));
  end;
end;


//----------------------------------------------------------------------------------------------------------------------
// Records and classes
//
// Written and read member by member, from the list the type cache built.
//----------------------------------------------------------------------------------------------------------------------
function IsEmptyValue(ti: PTypeInfo; data: Pointer): boolean;
begin
  result:= false;
  case ti.Kind of
    tkString:
      result := PByte(data)^ = 0;                    // ShortString length byte
    tkLString:
      result := Length(PAnsiString(data)^) = 0;      // Ansi/UTF8/RawByteString
    tkUString:
      result := Length(PUnicodeString(data)^) = 0;
    tkWString:
      result := Length(PWideString(data)^) = 0;      // BSTR on Windows
    tkInteger,tkInt64:
      result:= (LoadOrdinal(ti,data) = 0);
    tkEnumeration:
      result:= IsBooleanType(ti) and (LoadOrdinal(ti,data) = 0);
    tkFloat:
      result:= (LoadFloat(ti,data) = 0.0);
    tkClass,tkPointer:
      result:= (PPointer(data)^ = nil);
    // no tkArray: a static array is never empty - Delphi rejects array[0..-1]
    tkDynArray:
      result:= DynArraySize(PPointer(data)^) = 0;
    tkSet:
      begin
        var setSize := SizeOfSet(ti);
        for var i:= 0 to setSize-1 do begin
          if PByte(data)[i] <> 0 then exit(false);
        end;
        exit(true);
      end;
    tkVariant:
      result:= VarIsEmpty(PVariant(data)^) or VarIsNull(PVariant(data)^)
            or VarIsClear(PVariant(data)^);
  end;
end;

// the formatters for strings, lists and dictionaries run instead of
// FormatStruct, so each one handles nil itself
function WroteNilObject(w: PJSONWriter; ti: PTypeInfo; data: Pointer): boolean;
begin
  result:= (ti.Kind = tkClass) and (PPointer(data)^ = nil);
  if result then w.WriteNull;
end;

function FormatStruct(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  i: integer;
  inst: Pointer;
  ct: PCachedType;
  m: PMemberInfo;
  src: Pointer;
  value: TValue;
begin
  if WroteNilObject(w,ti,data) then exit(JSONOK);

  ct:= TTypeCache(j.FormatterCache).Get(ti,j);
  if ct = nil then exit(JSONUnsupportedType);

  case ti.Kind of
  tkClass:
    // "data" holds the object-reference
    inst := PPointer(data)^;
  tkRecord,tkMRecord:
    // "data" already is the record
    inst := data;
  else
    exit(JSONUnsupportedType);
  end;

  result:= w.BeginObject();
  if result <> JSONOK then exit;

  for i:= 0 to High(ct.WriteOrder) do begin
    m:= ct.WriteOrder[i];

    // a property has no address, so it goes through a TValue
    if m.Offset >= 0 then begin
      src:= PByte(inst)+m.Offset;
    end else begin
      value:= TRttiProperty(m.Member).GetValue(inst);
      src:= value.GetReferenceToRawData;
    end;

    if m.OmitEmpty and IsEmptyValue(m.TypeInfo,src) then continue;

    w.WriteKeyDirect(m.KeyPtr,m.KeyLen);
    result:= TJSONFormatter(m.Func)(j,w,m.TypeInfo,src);
    if result <> JSONOK then begin
      // the innermost failure is kept; the frames above only pass it on. by
      // name: a member without type info has none to keep
      if w.ErrorMember = '' then begin
        w.ErrorType:= m.TypeInfo;
        w.ErrorMember:= m.Name;
      end;
      exit;
    end;
  end;

  result:= w.EndObject();
end;

function GetConstructor(rt: TRttiType) : TRttiMethod;
var
  Methods: TArray<TRttiMethod>;
  i: integer;
begin
  result:= nil;
  Methods := rt.GetMethods('Create');
  for i:= 0 to Length(Methods)-1 do begin
    if Length(Methods[i].GetParameters()) = 0 then begin
      exit(Methods[i]);
    end;
  end;
end;

type
  // fills an existing instance and owns nothing
  TInstanceFiller = function(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; instance: Pointer): TJSONResult;
  // frees what a failed fill left inside an instance ParseInstance built
  TInstanceRelease = procedure(ti: PTypeInfo; instance: Pointer);

// every built-in class destination decodes through here, so null and ownership
// are decided once: null frees the instance - the destination owns it - {}
// builds one, and one built here is freed again if the fill fails
function ParseInstance(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer; fill: TInstanceFiller; release: TInstanceRelease): TJSONResult;
var
  t: TRttiType;
  constructorMethod: TRttiMethod;
  instance: Pointer;
  created: boolean;
begin
  if ti.Kind <> tkClass then exit(JSONUnsupportedType);

  if r.PeekNextToken = 'n' then begin
    // only null begins with 'n'; ReadValue decides whether it is one
    result:= r.ReadValue;
    if result <> JSONOK then exit;
    TObject(PPointer(data)^).Free;
    PPointer(data)^:= nil;
    exit;
  end;

  instance:= PPointer(data)^;
  created:= false;
  if instance = nil then begin
    // RTTI only to construct: resolving it per instance would take the pool lock
    t:= RCTX.GetType(ti);
    if t = nil then exit(JSONUnsupportedType);

    constructorMethod:= GetConstructor(t);
    if constructorMethod = nil then exit(JSONUnsupportedType);

    instance:= constructorMethod.Invoke(t.AsInstance.MetaclassType,[]).AsObject;
    PPointer(data)^:= instance;
    created:= true;
  end;

  result:= fill(j,r,ti,instance);

  if (result <> JSONOK) and created then begin
    if assigned(release) then release(ti,instance);
    TObject(instance).Free;
    PPointer(data)^:= nil;
  end;
end;

// folds a..z and nothing else, as CompareText does; other bytes match exactly
function SameKey(a,b: PAnsiChar; len: integer): boolean;
var
  i: integer;
  ca,cb: byte;
begin
  for i:= 0 to len-1 do begin
    ca:= byte(a[i]);
    cb:= byte(b[i]);
    if ca = cb then continue;
    if (ca >= ord('a')) and (ca <= ord('z')) then ca:= ca xor $20;
    if (cb >= ord('a')) and (cb <= ord('z')) then cb:= cb xor $20;
    if ca <> cb then exit(false);
  end;
  result:= true;
end;

// the first match in declaration order wins when keys differ only in case
function GetMemberByKey(ct: PCachedType; key: PAnsiChar; len: integer): PMemberInfo;
var
  i: integer;
begin
  result:= Pointer(ct.Members);
  for i:= 0 to High(ct.Members) do begin
    if (result.KeyLen = len) and SameKey(key,result.KeyPtr,len) then exit;
    inc(result);
  end;
  result:= nil;
end;

function SetValueByKey(j: TJSONCodec; r: PJSONReader;ct: PCachedType; inst: Pointer; key: PAnsiChar; keyLen: integer): TJSONResult;
var
  prop: TRttiProperty;
  member: PMemberInfo;
  v: TValue;
  obj: TObject;
  ref: Pointer;
begin
  // key points into the reader's buffer, so it is resolved before the value is read
  member:= GetMemberByKey(ct,key,keyLen);
  if member = nil then begin
    // still consumed in full, or the reader would resume inside it
    exit( r.SkipValue );
  end;

  if member.Offset >= 0 then begin
    exit( TJSONParser(member.Func)(j,r,member.TypeInfo,PByte(inst)+member.Offset) );
  end;

  prop:= TRttiProperty(member.Member);

  // a class property is filled through its getter, as a field is: a property
  // guards the reference, not the contents. the setter is not called.
  if (member.TypeInfo.Kind = tkClass) and prop.IsReadable then begin
    obj:= prop.GetValue(inst).AsObject;
    if obj = nil then begin
      // nothing to fill, and without a setter nowhere to put a new one
      if not(prop.IsWritable) then exit( r.SkipValue );
    end else if r.PeekNextToken <> 'n' then begin
      ref:= Pointer(obj);
      result:= TJSONParser(member.Func)(j,r,member.TypeInfo,@ref);
      // a custom parser may hand back another instance; only a setter can store it
      if (result = JSONOK) and (ref <> Pointer(obj)) and prop.IsWritable then begin
        TValue.Make(@ref,member.TypeInfo,v);
        prop.SetValue(inst,v);
      end;
      exit;
    end else begin
      // null would free what the owner holds; with a setter, it gets nil below
      if not(prop.IsWritable) then exit(JSONTypeMismatch);
    end;
  end;

  // anything else goes through the setter, and so through a TValue
  TValue.Make(nil,member.TypeInfo,v);
  result:= TJSONParser(member.Func)(j,r,member.TypeInfo,v.GetReferenceToRawData);
  if result <> JSONOK then exit;
  prop.SetValue(inst,v);
end;

type
  TStructWalk = record
    Info: PCachedType;
    Instance: Pointer;
  end;
  PStructWalk = ^TStructWalk;

function StructMember(ctx: Pointer; j: TJSONCodec; r: PJSONReader; index: integer): TJSONResult;
var
  w: PStructWalk;
  key: PAnsiChar;
  keyLen: integer;
begin
  w:= ctx;
  key:= r.LastValueRaw(keyLen);
  result:= SetValueByKey(j,r,w.Info,w.Instance,key,keyLen);
end;

// "instance" is the record itself or the object, never the reference to one
function FillStruct(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; instance: Pointer): TJSONResult;
var
  w: TStructWalk;
begin
  w.Info:= TTypeCache(j.ParserCache).Get(ti,j);
  if w.Info = nil then exit(JSONUnsupportedType);
  w.Instance:= instance;

  result:= WalkAggregate(j,r,'{',@w,StructMember);
end;

function ParseStruct(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
begin
  // a record is data itself, and cannot be nil
  if ti.Kind in [tkRecord,tkMRecord] then exit(FillStruct(j,r,ti,data));

  result:= ParseInstance(j,r,ti,data,FillStruct,nil);
end;


//----------------------------------------------------------------------------------------------------------------------
// TStrings
//----------------------------------------------------------------------------------------------------------------------
// an object only if every entry has a name, so no entry is dropped for want of
// a key. by Pos, because l.Names[i] allocates a string per entry; a separator
// in position 1 means an empty name
function LooksLikeKeyValueList(l: TStrings): boolean;
var
  i: integer;
  separator: string;
begin
  result:= false;
  if l.Count = 0 then exit;

  // a string, once: Pos has no Char overload
  separator:= l.NameValueSeparator;
  for i:= 0 to l.Count-1 do
    if Pos(separator,l[i]) <= 1 then exit;

  result:= true;
end;

function FormatStrings(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  l: TStrings;
begin
  if WroteNilObject(w,ti,data) then exit(JSONOK);
  l:= TStrings(PPointer(data)^);

  if w.Config.DetectKeyValuePairs and LooksLikeKeyValueList(l) then begin

    result:= w.BeginObject();
    if result <> JSONOK then exit;

    for var i:= 0 to l.Count-1 do begin
      w.WriteKey(l.Names[i]);
      w.WriteString(l.ValueFromIndex[i]);
    end;

    exit(w.EndObject());
  end;

  result:= w.BeginArray();
  if result <> JSONOK then exit;

  for var i:= 0 to l.Count-1 do begin
    var s:= l[i];
    w.WriteString(s);
  end;

  result:= w.EndArray();
end;

// a TStrings takes any scalar as text, and null as the empty string: the four
// letters would read back as a value the document never had
function StringsArrayElement(ctx: Pointer; j: TJSONCodec; r: PJSONReader; index: integer): TJSONResult;
var
  vt: TJSONValueType;
  text: string;
begin
  result:= r.ReadValue(@vt);
  if result <> JSONOK then exit;
  if vt = jvtNull then text:= '' else text:= r.LastValue;
  TStrings(ctx).Add(text);
end;

function StringsStructMember(ctx: Pointer; j: TJSONCodec; r: PJSONReader; index: integer): TJSONResult;
var
  vt: TJSONValueType;
  name,text: string;
  strings: TStrings;
  i: integer;
begin
  // taken first: reading the value overwrites the reader's buffer
  name:= r.LastValue;

  result:= r.ReadValue(@vt);
  if result <> JSONOK then exit;
  if vt = jvtNull then text:= '' else text:= r.LastValue;

  // not Values[name]: assigning '' to it deletes the entry
  strings:= TStrings(ctx);
  text:= name + strings.NameValueSeparator + text;
  i:= strings.IndexOfName(name);
  if i < 0 then strings.Add(text) else strings[i]:= text;
end;

function FillStrings(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; instance: Pointer): TJSONResult;
begin
  TStrings(instance).Clear;

  case r.PeekNextToken of
    '[': result:= WalkAggregate(j,r,'[',instance,StringsArrayElement);
    '{': result:= WalkAggregate(j,r,'{',instance,StringsStructMember);
  else
    // a TStrings takes an array or an object, nothing else
    result:= r.ShapeError;
  end;
end;

function ParseStrings(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
begin
  result:= ParseInstance(j,r,ti,data,FillStrings,nil);
end;


//----------------------------------------------------------------------------------------------------------------------
// TList and TDictionary
//
// What a TList or TDictionary is to this unit, asked of its type - the same
// questions on both sides, so encoding and decoding cannot disagree about it.
// Whether its element type has a handler each side asks itself.
//
// Both add through RTTI Invoke, an element at a time - except a plain TList
// nobody listens to, which is filled at once.
//----------------------------------------------------------------------------------------------------------------------
// the qualified name without type parameters, so 'System.Generics.Collections.TList'
// covers every TList<T>. registration and lookup both key through here
function ClassKey(c: TClass): string;
var
  p: integer;
begin
  result:= c.QualifiedClassName;
  p:= Pos('<',result);
  if p > 0 then SetLength(result,p-1);
end;

// nil for anything but a class: AsInstance would raise EInvalidCast
function InstanceTypeOf(ti: PTypeInfo): TRttiInstanceType;
var
  t: TRttiType;
begin
  result:= nil;
  t:= RCTX.GetType(ti);
  if (t = nil) or not(t.IsInstance) then exit;
  result:= t.AsInstance;
end;

type
  // List is the list's own array, sized to the capacity; Count says how much
  // of it is in use
  TListShape = record
    InstanceType: TRttiInstanceType;
    ListProp,CountProp: TRttiProperty;
    ArrayType,ElementType: PTypeInfo;
  end;

  TDictionaryShape = record
    InstanceType: TRttiInstanceType;
    AddMethod: TRttiMethod;   // AddOrSetValue(key,value)
    ValueType: PTypeInfo;
  end;

function GetListShape(ti: PTypeInfo; out s: TListShape): boolean;
var
  elementRef: PPTypeInfo;
begin
  result:= false;
  s.InstanceType:= InstanceTypeOf(ti);
  if s.InstanceType = nil then exit;
  s.ListProp:= s.InstanceType.GetProperty('List');
  s.CountProp:= s.InstanceType.GetProperty('Count');
  if (s.ListProp = nil) or (s.CountProp = nil) or (s.ListProp.PropertyType.TypeKind <> tkDynArray) then exit;
  s.ArrayType:= s.ListProp.PropertyType.Handle;
  elementRef:= GetTypeData(s.ArrayType)^.DynArrElType;
  if elementRef = nil then exit;
  s.ElementType:= elementRef^;
  result:= true;
end;

// a JSON key is text, so only a string-keyed dictionary takes part - decided
// by the type, or an empty one with another key type would pass. Not a
// ShortString: Invoke wants the exact type for it, and 255 characters would
// truncate a longer key into another
function GetDictionaryShape(ti: PTypeInfo; out s: TDictionaryShape): boolean;
var
  params: TArray<TRttiParameter>;
begin
  result:= false;
  s.InstanceType:= InstanceTypeOf(ti);
  if s.InstanceType = nil then exit;
  s.AddMethod:= s.InstanceType.GetMethod('AddOrSetValue');
  if s.AddMethod = nil then exit;
  params:= s.AddMethod.GetParameters();
  if (Length(params) < 2) or (params[0].ParamType = nil) or (params[1].ParamType = nil) then exit;
  if not(params[0].ParamType.TypeKind in [tkLString,tkWString,tkUString]) then exit;
  s.ValueType:= params[1].ParamType.Handle;
  result:= true;
end;

// one key order for TDictionary and TVarDict, the one struct members get:
// ordinal, not locale-aware, so a document is the same on every machine
type
  TKeySort = record
    class procedure Sort<V>(var pairs: TArray<TPair<string,V>>); static;
  end;

class procedure TKeySort.Sort<V>(var pairs: TArray<TPair<string,V>>);
begin
  TArray.Sort<TPair<string,V>>(pairs,TComparer<TPair<string,V>>.Construct(
    function(const a,b: TPair<string,V>): integer
    begin
      result:= CompareStr(a.Key,b.Key);
    end));
end;

// two RTTI calls per list: List is read without a copy, only a reference held
function FormatList(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  shape: TListShape;
  items: TValue;
  count: NativeInt;
  formatter: TJSONFormatter;
begin
  // the element type decides, as for an array: nil and empty lists included
  if not GetListShape(ti,shape) then exit(JSONUnsupportedType);
  formatter:= j.GetFormatterForTypeInfo(shape.ElementType);
  if not(assigned(formatter)) then exit(JSONUnsupportedType);

  if WroteNilObject(w,ti,data) then exit(JSONOK);

  items:= shape.ListProp.GetValue(PPointer(data)^);
  count:= shape.CountProp.GetValue(PPointer(data)^).AsOrdinal;

  result:= WriteElements(j,w,formatter,shape.ElementType,PPointer(items.GetReferenceToRawData)^,
                         GetTypeData(shape.ArrayType)^.elSize,count);
end;

// pairs is the TArray<TPair<K,V>> ToArray returned: plain memory, walked by
// the offsets of Key and Value
function WriteDictionaryEntries(j: TJSONCodec; w: PJSONWriter; formatter: TJSONFormatter;
                                pairsType: PTypeInfo; pairs: PByte): TJSONResult;
var
  pairType: TRttiType;
  keyField,valueField: TRttiField;
  keyType,valueType: PTypeInfo;
  pairSize: integer;
  sorted: TArray<TPair<string,Pointer>>;
begin
  pairType:= RCTX.GetType(GetTypeData(pairsType)^.DynArrElType^);
  keyField:= pairType.GetField('Key');
  valueField:= pairType.GetField('Value');
  if (keyField = nil) or (valueField = nil) then exit(JSONUnsupportedType);
  keyType:= keyField.FieldType.Handle;
  valueType:= valueField.FieldType.Handle;
  pairSize:= GetTypeData(pairsType)^.elSize;

  result:= w.BeginObject();
  if result <> JSONOK then exit;

  // always sorted: hash order would differ from one RTL to the next. the values
  // stay where ToArray put them; only the keys and their addresses are sorted
  SetLength(sorted,DynArraySize(pairs));
  for var i:= 0 to High(sorted) do begin
    sorted[i]:= TPair<string,Pointer>.Create(LoadString(keyType,pairs+keyField.Offset),pairs+valueField.Offset);
    inc(pairs,pairSize);
  end;
  TKeySort.Sort<Pointer>(sorted);

  for var i:= 0 to High(sorted) do begin
    w.WriteKey(sorted[i].Key);
    result:= formatter(j,w,valueType,sorted[i].Value);
    if result <> JSONOK then exit;
  end;

  result:= w.EndObject();
end;

// one RTTI call per dictionary: ToArray copies the pairs out - shallow, strings
// and arrays by reference count - and the rest is plain memory
function FormatDictionary(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  shape: TDictionaryShape;
  toArray: TRttiMethod;
  formatter: TJSONFormatter;
  pairs: TValue;
begin
  // the key and value types decide, as for an array: asked before nil and
  // rather than off the first pair - see GetDictionaryShape
  if not GetDictionaryShape(ti,shape) then exit(JSONUnsupportedType);
  formatter:= j.GetFormatterForTypeInfo(shape.ValueType);
  if not(assigned(formatter)) then exit(JSONUnsupportedType);

  toArray:= shape.InstanceType.GetMethod('ToArray');
  if (toArray = nil) or (toArray.ReturnType = nil) or (toArray.ReturnType.TypeKind <> tkDynArray) then
    exit(JSONUnsupportedType);

  if WroteNilObject(w,ti,data) then exit(JSONOK);

  pairs:= toArray.Invoke(TObject(PPointer(data)^),[]);
  result:= WriteDictionaryEntries(j,w,formatter,pairs.TypeInfo,PPointer(pairs.GetReferenceToRawData)^);
end;

type
  TContainerWalk = record
    Instance: Pointer;
    AddMethod: TRttiMethod;
    ElementType: PTypeInfo;
    ElementParser: TJSONParser;
  end;
  PContainerWalk = ^TContainerWalk;

// the types decide whether a container can be decoded at all, as for an
// array - null and an empty document included. RTTI here runs once per
// container, not per element
function ResolveList(j: TJSONCodec; ti: PTypeInfo; out shape: TListShape; out w: TContainerWalk): TJSONResult;
begin
  if not GetListShape(ti,shape) then exit(JSONUnsupportedType);
  w.AddMethod:= shape.InstanceType.GetMethod('Add');
  if w.AddMethod = nil then exit(JSONUnsupportedType);
  w.ElementType:= shape.ElementType;
  w.ElementParser:= j.GetParserForTypeInfo(w.ElementType);
  if not(assigned(w.ElementParser)) then exit(JSONUnsupportedType);
  result:= JSONOK;
end;

function ResolveDictionary(j: TJSONCodec; ti: PTypeInfo; out shape: TDictionaryShape; out w: TContainerWalk): TJSONResult;
begin
  if not GetDictionaryShape(ti,shape) then exit(JSONUnsupportedType);
  w.AddMethod:= shape.AddMethod;
  w.ElementType:= shape.ValueType;
  w.ElementParser:= j.GetParserForTypeInfo(w.ElementType);
  if not(assigned(w.ElementParser)) then exit(JSONUnsupportedType);
  result:= JSONOK;
end;

// only once the types are resolved, so a refused container is not emptied
function ClearContainer(instanceType: TRttiInstanceType; instance: Pointer): TJSONResult;
var
  clearMethod: TRttiMethod;
begin
  clearMethod:= instanceType.GetMethod('Clear');
  if clearMethod = nil then exit(JSONUnsupportedType);
  clearMethod.Invoke(TObject(instance),[]);
  result:= JSONOK;
end;

function ListElement(ctx: Pointer; j: TJSONCodec; r: PJSONReader; index: integer): TJSONResult;
var
  w: PContainerWalk;
  nextValue: TValue;
begin
  w:= ctx;

  // Add takes a TValue; the parser fills its storage directly
  TValue.Make(nil,w.ElementType,nextValue);
  result:= w.ElementParser(j,r,w.ElementType,nextValue.GetReferenceToRawData);
  if result <> JSONOK then exit;

  w.AddMethod.Invoke(TObject(w.Instance),[nextValue]);
end;

function DictionaryEntry(ctx: Pointer; j: TJSONCodec; r: PJSONReader; index: integer): TJSONResult;
var
  w: PContainerWalk;
  nextValue: TValue;
  name: string;
begin
  w:= ctx;

  // taken before the value is read, which overwrites the reader's buffer
  name:= r.LastValue;

  // fresh, zeroed storage per entry; the parser writes into it directly
  TValue.Make(nil,w.ElementType,nextValue);
  result:= w.ElementParser(j,r,w.ElementType,nextValue.GetReferenceToRawData);
  if result <> JSONOK then exit;

  w.AddMethod.Invoke(TObject(w.Instance),[name,nextValue]);
end;

// Add notifies (OnNotify, an overridden Notify); setting Count does not. So
// only a plain TList<T> or TObjectList<T> with no OnNotify takes the fast way
function NobodyListens(instanceType: TRttiInstanceType; instance: Pointer): boolean;
var
  key: string;
  onNotify: TRttiProperty;
begin
  result:= false;
  // the instance's own class, not the declared one: a subclass may override Notify
  key:= ClassKey(TObject(instance).ClassType);
  if (key <> 'System.Generics.Collections.TList') and (key <> 'System.Generics.Collections.TObjectList') then exit;

  onNotify:= instanceType.GetProperty('OnNotify');
  if onNotify = nil then exit;
  result:= PMethod(onNotify.GetValue(instance).GetReferenceToRawData)^.Code = nil;
end;

// the elements are parsed as an array of the list's own array type, then
// copied in at once - an Invoke of Add per element cost ten times the parse.
// On a failure what was decoded is copied in too, as Add would have left it
function FillListAtOnce(j: TJSONCodec; r: PJSONReader; const shape: TListShape; instance: Pointer): TJSONResult;
var
  decoded,items: TValue;
  n: NativeInt;
begin
  result:= ClearContainer(shape.InstanceType,instance);
  if result <> JSONOK then exit;

  TValue.Make(nil,shape.ArrayType,decoded);
  result:= ParseArray(j,r,shape.ArrayType,decoded.GetReferenceToRawData);

  n:= DynArraySize(PPointer(decoded.GetReferenceToRawData)^);
  if n = 0 then exit;

  // Count grows the list's own array, zeroed; then the elements go into it
  shape.CountProp.SetValue(instance,TValue.From<NativeInt>(n));
  items:= shape.ListProp.GetValue(instance);
  if IsManaged(shape.ElementType) then
    CopyArray(PPointer(items.GetReferenceToRawData)^,PPointer(decoded.GetReferenceToRawData)^,shape.ElementType,n)
  else
    Move(PPointer(decoded.GetReferenceToRawData)^^,PPointer(items.GetReferenceToRawData)^^,n*GetTypeData(shape.ArrayType)^.elSize);
end;

function FillList(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; instance: Pointer): TJSONResult;
var
  shape: TListShape;
  w: TContainerWalk;
begin
  result:= ResolveList(j,ti,shape,w);
  if result <> JSONOK then exit;

  if shape.CountProp.IsWritable and NobodyListens(shape.InstanceType,instance) then
    exit(FillListAtOnce(j,r,shape,instance));

  result:= ClearContainer(shape.InstanceType,instance);
  if result <> JSONOK then exit;

  w.Instance:= instance;
  result:= WalkAggregate(j,r,'[',@w,ListElement);
end;

function FillDictionary(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; instance: Pointer): TJSONResult;
var
  shape: TDictionaryShape;
  w: TContainerWalk;
begin
  result:= ResolveDictionary(j,ti,shape,w);
  if result <> JSONOK then exit;

  result:= ClearContainer(shape.InstanceType,instance);
  if result <> JSONOK then exit;

  w.Instance:= instance;
  result:= WalkAggregate(j,r,'{',@w,DictionaryEntry);
end;

// a container built here and freed after a failure takes the objects already
// decoded into it along, one level deep. extracted, not removed: a TObjectList
// frees on removal, and they would be freed twice
procedure ReleaseListElements(ti: PTypeInfo; instance: Pointer);
var
  shape: TListShape;
  extractAt: TRttiMethod;
  n: NativeInt;
begin
  if not GetListShape(ti,shape) then exit;
  extractAt:= shape.InstanceType.GetMethod('ExtractAt');
  if (extractAt = nil) or (extractAt.ReturnType = nil) or (extractAt.ReturnType.TypeKind <> tkClass) then exit;

  n:= shape.CountProp.GetValue(instance).AsOrdinal;
  while n > 0 do begin
    dec(n);
    extractAt.Invoke(TObject(instance),[TValue.From<NativeInt>(n)]).AsObject.Free;
  end;
end;

procedure ReleaseDictionaryValues(ti: PTypeInfo; instance: Pointer);
var
  instanceType: TRttiInstanceType;
  extractPair,toArray: TRttiMethod;
  keysProp: TRttiProperty;
  keys,pair: TValue;
  keysObj: TObject;
  valueField: TRttiField;
begin
  instanceType:= InstanceTypeOf(ti);
  if instanceType = nil then exit;
  extractPair:= instanceType.GetMethod('ExtractPair');
  keysProp:= instanceType.GetProperty('Keys');
  if (extractPair = nil) or (keysProp = nil) or (extractPair.ReturnType = nil) then exit;
  valueField:= extractPair.ReturnType.GetField('Value');
  if (valueField = nil) or (valueField.FieldType = nil) or (valueField.FieldType.TypeKind <> tkClass) then exit;

  // keys copied out first: extracting changes what is being walked
  keysObj:= keysProp.GetValue(instance).AsObject;
  toArray:= InstanceTypeOf(keysObj.ClassInfo).GetMethod('ToArray');
  if toArray = nil then exit;
  keys:= toArray.Invoke(keysObj,[]);
  for var i:= 0 to keys.GetArrayLength-1 do begin
    pair:= extractPair.Invoke(TObject(instance),[keys.GetArrayElement(i)]);
    valueField.GetValue(pair.GetReferenceToRawData).AsObject.Free;
  end;
end;

// null is refused, too, for a container that cannot be decoded; anything else
// meets the same check in the fill
function ParseList(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  shape: TListShape;
  w: TContainerWalk;
begin
  if r.PeekNextToken = 'n' then begin
    result:= ResolveList(j,ti,shape,w);
    if result <> JSONOK then exit;
  end;
  result:= ParseInstance(j,r,ti,data,FillList,ReleaseListElements);
end;

function ParseDictionary(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  shape: TDictionaryShape;
  w: TContainerWalk;
begin
  if r.PeekNextToken = 'n' then begin
    result:= ResolveDictionary(j,ti,shape,w);
    if result <> JSONOK then exit;
  end;
  result:= ParseInstance(j,r,ti,data,FillDictionary,ReleaseDictionaryValues);
end;


//----------------------------------------------------------------------------------------------------------------------
// Variants
//
// TVarDict is the object half of a dynamic document.
// The store hangs off the TVarData and the variant owns it: Clear frees it,
// Copy clones it, and the compiler finalises it on every path. Keys are kept
// and matched exactly; the encoder sorts them.
//----------------------------------------------------------------------------------------------------------------------
type
  // pointer-sized, to fit the TVarData overlay below
  TVarDictStore = TDictionary<string,Variant>;

  // overlays TVarData, so it must be exactly as big - the variant part pads it,
  // as the RTL's TComplexVarData does
  TVarDictData = packed record
    VType: TVarType;
    Reserved1, Reserved2, Reserved3: word;
    case integer of
      0: (Store: TVarDictStore);
      1: (VLargest: TLargestVarData);
  end;

  TVarDict = class(TInvokeableVariantType)
  protected
    // the default uppercases the identifier; a key keeps the casing written
    function FixupIdent(const AText: string): string; override;
  public
    procedure Clear(var V: TVarData); override;
    procedure Copy(var Dest: TVarData; const Source: TVarData; const Indirect: boolean); override;
    function GetProperty(var Dest: TVarData; const V: TVarData; const Name: string): boolean; override;
    function SetProperty(const V: TVarData; const Name: string; const Value: TVarData): boolean; override;
  end;

var
  VarDictType: TVarDict;

function TVarDict.FixupIdent(const AText: string): string;
begin
  result:= AText;
end;

procedure TVarDict.Clear(var V: TVarData);
begin
  // VType first, so a variant being torn down never claims a released store
  V.VType:= varEmpty;
  FreeAndNil(TVarDictData(V).Store);
end;

procedure TVarDict.Copy(var Dest: TVarData; const Source: TVarData; const Indirect: boolean);
var
  pair: TPair<string,Variant>;
begin
  if Indirect and VarDataIsByRef(Source) then begin
    VarDataCopyNoInd(Dest,Source);
    exit;
  end;

  VarDataClear(Dest);

  // published before it is filled, so Dest owns the store from here on
  TVarDictData(Dest).VType:= VarType;
  TVarDictData(Dest).Store:= TVarDictStore.Create;

  // assigning the Variant deep-copies a nested document
  for pair in TVarDictData(Source).Store do
    TVarDictData(Dest).Store.AddOrSetValue(pair.Key,pair.Value);
end;

function TVarDict.GetProperty(var Dest: TVarData; const V: TVarData; const Name: string): boolean;
begin
  // a missing key reads as Unassigned - TryGetValue's default; answering false
  // would raise
  TVarDictData(V).Store.TryGetValue(Name,Variant(Dest));
  result:= true;
end;

function TVarDict.SetProperty(const V: TVarData; const Name: string; const Value: TVarData): boolean;
var
  incoming: Variant;
begin
  // late binding hands Value over byref, pointing at the caller's local. Only
  // FindVarData follows that; a plain copy would store a pointer to the stack.
  VarDataCopy(TVarData(incoming),FindVarData(Variant(Value))^);
  TVarDictData(V).Store.AddOrSetValue(Name,incoming);
  result:= true;
end;

function VarDictCreate: Variant;
begin
  VarClear(result);
  TVarDictData(result).VType:= VarDictType.VarType;
  TVarDictData(result).Store:= TVarDictStore.Create;
end;

function VarIsDict(const v: Variant): boolean;
begin
  // varTypeMask strips varByRef, so a byref dictionary still answers yes
  result:= (VarDictType <> nil)
       and ((VarType(v) and varTypeMask) = VarDictType.VarType);
end;

// the store behind a dictionary variant, through one level of byref
function DictStoreOf(const v: Variant): TVarDictStore;
var
  vd: PVarData;
begin
  if not(VarIsDict(v)) then exit(nil);

  vd:= @TVarData(v);
  if (vd.VType and varByRef) <> 0 then vd:= PVarData(vd.VPointer);

  result:= TVarDictData(vd^).Store;
end;

function FormatVariant(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult; forward;

function FormatVarArray(j: TJSONCodec; w: PJSONWriter; const va: Variant): TJSONResult;
var
  i,lo,hi: integer;
  el: Variant;
begin
  // one dimension only: a multi-dimensional array has no JSON shape
  if VarArrayDimCount(va) <> 1 then exit(JSONUnsupportedType);

  result:= w.BeginArray();
  if result <> JSONOK then exit;

  lo:= VarArrayLowBound(va,1);
  hi:= VarArrayHighBound(va,1);
  for i:= lo to hi do begin
    el:= VarArrayGet(va,[i]);
    result:= FormatVariant(j,w,nil,@el);
    if result <> JSONOK then exit;
  end;

  result:= w.EndArray();
end;

function FormatVarDict(j: TJSONCodec; w: PJSONWriter; const va: Variant): TJSONResult;
var
  store: TVarDictStore;
  pairs: TArray<TPair<string,Variant>>;
  i: integer;
begin
  store:= DictStoreOf(va);
  if store = nil then exit(JSONUnsupportedType);

  // copied out first: the walk re-enters this for a nested document. always
  // sorted, as a TDictionary is
  pairs:= store.ToArray;
  TKeySort.Sort<Variant>(pairs);

  result:= w.BeginObject();
  if result <> JSONOK then exit;

  for i:= 0 to High(pairs) do begin
    w.WriteKey(pairs[i].Key);
    result:= FormatVariant(j,w,nil,@pairs[i].Value);
    if result <> JSONOK then exit;
  end;

  result:= w.EndObject();
end;

function FormatVariant(j: TJSONCodec; w: PJSONWriter; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  va: Variant;
  vt: word;
begin
  va:= PVariant(data)^;
  vt:= VarType(va);

  // first: asking VarIsOrdinal or VarIsStr about a custom variant invites a cast
  if VarIsDict(va) then exit(FormatVarDict(j,w,va));
  if (vt and varArray) <> 0 then exit(FormatVarArray(j,w,va));

  // the rest converts on the way into the writer
  if vt = varBoolean then begin
    w.WriteBoolean(va);
    exit(JSONOK);
  end;

  if vt = varDate then exit(WriteDateTime(w,va));

  if VarIsOrdinal(va) then begin
    w.WriteInteger(va);
    exit(JSONOK);
  end;

  if vt = varCurrency then begin
    WriteCurrency(w,va);
    exit(JSONOK);
  end;

  // a Variant holds a single or a double, never an extended
  if vt = varSingle then exit(WriteFloatNumber(w,va,ftSingle));
  if VarIsFloat(va) then exit(WriteFloatNumber(w,va,ftDouble));

  if VarIsStr(va) then begin
    w.WriteString(va);
    exit(JSONOK);
  end;

  // Unassigned is the nearest thing to null a Variant has
  if VarIsNull(va) or VarIsEmpty(va) then begin
    w.WriteNull;
    exit(JSONOK);
  end;

  // an interface, a dispatch pointer, another custom type: no JSON form
  result:= JSONUnsupportedType;
end;

function ParseVariant(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult; forward;

// parsed as a TArray<Variant>, then handed over as a variant array in one go
function ParseVariantArray(j: TJSONCodec; r: PJSONReader; data: Pointer): TJSONResult;
var
  elements: TArray<Variant>;
begin
  result:= ParseArray(j,r,System.TypeInfo(TArray<Variant>),@elements);
  if result <> JSONOK then exit;

  PVariant(data)^:= VarArrayOf(elements);
end;

function VariantDictMember(ctx: Pointer; j: TJSONCodec; r: PJSONReader; index: integer): TJSONResult;
var
  name: string;
  value: Variant;
begin
  // the key is in the reader's buffer, which reading the value overwrites
  name:= r.LastValue;

  result:= ParseVariant(j,r,nil,@value);
  if result <> JSONOK then exit;

  TVarDictStore(ctx).AddOrSetValue(name,value);
end;

function ParseVariantDict(j: TJSONCodec; r: PJSONReader; data: Pointer): TJSONResult;
var
  v: Variant;
begin
  // v owns the store before a member is read
  v:= VarDictCreate;

  result:= WalkAggregate(j,r,'{',DictStoreOf(v),VariantDictMember);
  if result <> JSONOK then exit;

  PVariant(data)^:= v;
end;

function ParseVariant(j: TJSONCodec; r: PJSONReader; ti: PTypeInfo; data: Pointer): TJSONResult;
var
  variantValue: Variant;
  d: double;
  i: int64;
  vt: TJSONValueType;
begin
  case r.PeekNextToken of
    '[': exit(ParseVariantArray(j,r,data));
    '{': exit(ParseVariantDict(j,r,data));
  end;

  result:= r.ReadValue(@vt);
  if result <> JSONOK then exit;

  case vt of
  jvtString: variantValue:= r.LastValue;
  jvtNumber:
    // the notation decides, not the value: 1e2 is a real
    if r.NumberIsReal then begin
      if not(TokenToFloat(r,d)) then exit(JSONTypeMismatch);
      variantValue:= d;
    end else if TryStrToInt64(r.LastValue,i) then begin
      variantValue:= i;
    end else begin
      // a whole number past Int64 becomes a float, as Go reads it
      if not(TokenToFloat(r,d)) then exit(JSONTypeMismatch);
      variantValue:= d;
    end;
  jvtTrue:  variantValue:= true;
  jvtFalse: variantValue:= false;
  jvtNull:  variantValue:= System.Variants.Null;
  end;
  PVariant(data)^:= variantValue;
end;


//======================================================================================================================
// From a type to its handlers
//======================================================================================================================

//----------------------------------------------------------------------------------------------------------------------
// Handler lookup
//----------------------------------------------------------------------------------------------------------------------
// a class is keyed by its qualified name without type parameters, a public type
// by its qualified name, any other by '@' and its type info's address.
// registration and lookup both key through here, so they cannot disagree
function HandlerKeyFor(t: TRttiType): string;
begin
  result:= '';
  if t = nil then exit;
  if t.IsInstance then
    result:= ClassKey(t.AsInstance.MetaclassType)
  else if t.IsPublicType then
    result:= t.QualifiedName
  else
    result:= '@' + IntToHex(NativeUInt(t.Handle));
end;

// a class matches on itself or on its nearest registered ancestor
function FindRegistered(list: TStringList; t: TRttiType): Pointer;
var
  i: integer;
  c: TClass;
begin
  result:= nil;
  if t.IsInstance then begin
    c:= t.AsInstance.MetaclassType;
    while c <> nil do begin
      i:= list.IndexOf(ClassKey(c));
      if i >= 0 then exit(Pointer(list.Objects[i]));
      c:= c.ClassParent;
    end;
  end else begin
    i:= list.IndexOf(HandlerKeyFor(t));
    if i >= 0 then exit(Pointer(list.Objects[i]));
  end;
end;

// a type's formatter or parser, uncached: a registered handler wins over the
// built-in one for the type's kind. The built-ins come in pairs, one per side
function TJSONCodec.GetHandlerForType(t: TRttiType; forWriting: boolean): Pointer;

  function Pick(formatter: TJSONFormatter; parser: TJSONParser): Pointer;
  begin
    if forWriting then result:= @formatter else result:= @parser;
  end;

begin
  result:= nil;
  if t = nil then exit;

  if forWriting then result:= FindRegistered(Formatters,t) else result:= FindRegistered(Parsers,t);
  if result <> nil then exit;

  case t.TypeKind of
    tkString,tkLString,tkWString,tkUString: result:= Pick(FormatString,ParseString);
    tkInteger,tkInt64:                      result:= Pick(FormatInteger,ParseInteger);
    tkFloat:                                result:= Pick(FormatFloat,ParseFloat);
    tkEnumeration:                          result:= Pick(FormatEnum,ParseEnum);
    tkChar,tkWChar:                         result:= Pick(FormatChar,ParseChar);
    tkSet:                                  result:= Pick(FormatSet,ParseSet);
    tkRecord,tkMRecord,tkClass:             result:= Pick(FormatStruct,ParseStruct);
    tkArray,tkDynArray:                     result:= Pick(FormatArray,ParseArray);
    tkVariant:                              result:= Pick(FormatVariant,ParseVariant);
    tkPointer:
      // an untyped pointer has nothing to follow: skipped, as an interface is
      if t.Handle <> System.TypeInfo(Pointer) then result:= Pick(FormatPointer,ParsePointer);
  end;
end;

// through the cache: resolving builds a key string and scans the registry
function TJSONCodec.GetFormatterForTypeInfo(ti: PTypeInfo): TJSONFormatter;
begin
  if ti = nil then exit(nil);
  result:= TJSONFormatter(TTypeCache(FormatterCache).Get(ti,self).Handler);
end;

function TJSONCodec.GetParserForTypeInfo(ti: PTypeInfo): TJSONParser;
begin
  if ti = nil then exit(nil);
  result:= TJSONParser(TTypeCache(ParserCache).Get(ti,self).Handler);
end;


//----------------------------------------------------------------------------------------------------------------------
// Construction and registration
//----------------------------------------------------------------------------------------------------------------------
constructor TJSONCodec.Create(const aconfig: TJSONConfig);

  // the built-in handlers come in pairs: what one side writes, the other reads
  procedure Add(const name: string; f: TJSONFormatter; p: TJSONParser);
  begin
    Formatters.AddObject(name,@f);
    Parsers.AddObject(name,@p);
  end;

begin
  Configure(aconfig);
  ParserCache:= TTypeCache.Create(false,false);

  Formatters:= TStringList.Create;
  Parsers:= TStringList.Create;
  Add('System.TGUID',FormatGUID,ParseGUID);
  Add('System.UITypes.TColor',FormatColor,ParseColor);
  Add('System.TDateTime',FormatDateTime,ParseDateTime);
  Add('System.TDate',FormatDateTime,ParseDateTime);
  Add('System.TTime',FormatDateTime,ParseDateTime);
  Add('System.Classes.TStrings',FormatStrings,ParseStrings);
  Add('System.Generics.Collections.TList',FormatList,ParseList);
  Add('System.Generics.Collections.TDictionary',FormatDictionary,ParseDictionary);
end;

procedure TJSONCodec.Configure(const aconfig: TJSONConfig);
begin
  fConfig:= aconfig;
  if fConfig.MaxDepth <= 0 then fConfig.MaxDepth:= JSON_DEFAULTMAXDEPTH;
  FormatterCache.Free;
  FormatterCache:= TTypeCache.Create(true,fConfig.SortKeys);
end;

destructor TJSONCodec.Destroy;
begin
  Formatters.Free;
  FormatterCache.Free;
  Parsers.Free;
  ParserCache.Free;
  inherited;
end;

procedure SetHandler(list: TStringList; const qualifiedName: string; handler: Pointer);
var
  i: integer;
begin
  if qualifiedName = '' then exit;

  i:= list.IndexOf(qualifiedName);

  if handler = nil then begin
    if i >= 0 then list.Delete(i);
    exit;
  end;

  if i >= 0 then
    list.Objects[i]:= TObject(handler)
  else
    list.AddObject(qualifiedName,TObject(handler));
end;

procedure TJSONCodec.RegisterFormatter(const qualifiedName: string; f: TJSONFormatter);
begin
  SetHandler(Formatters,qualifiedName,@f);
  FormatterCache.Free;
  FormatterCache:= TTypeCache.Create(true,fConfig.SortKeys);
end;

procedure TJSONCodec.RegisterParser(const qualifiedName: string; p: TJSONParser);
begin
  SetHandler(Parsers,qualifiedName,@p);
  ParserCache.Free;
  ParserCache:= TTypeCache.Create(false,false);
end;

procedure TJSONCodec.RegisterFormatter(ti: PTypeInfo; f: TJSONFormatter);
begin
  RegisterFormatter(HandlerKeyFor(RCTX.GetType(ti)),f);
end;

procedure TJSONCodec.RegisterParser(ti: PTypeInfo; p: TJSONParser);
begin
  RegisterParser(HandlerKeyFor(RCTX.GetType(ti)),p);
end;

procedure TJSONCodec.RegisterFormatter<T>(f: TJSONFormatter);
begin
  RegisterFormatter(System.TypeInfo(T),f);
end;

procedure TJSONCodec.RegisterParser<T>(p: TJSONParser);
begin
  RegisterParser(System.TypeInfo(T),p);
end;

initialization
  RCTX:= TRttiContext.Create;
  JSONFormatSettings:= TFormatSettings.Create();
  JSONFormatSettings.DecimalSeparator:= '.';
  JSONFormatSettings.ThousandSeparator:= #0;
  NullAttribute:= JSONAttribute.Create('',false);

  VarDictType:= TVarDict.Create;

  JSON:= TJSONCodec.Create(JSONDefaultConfig);

finalization
  JSON.Free;
  JSON:= nil;
  NullAttribute.Free;
  NullAttribute:= nil;
  RCTX.Free;
  FreeAndNil(VarDictType);

end.

