program test_json;

{$APPTYPE CONSOLE}

uses
    System.SysUtils,
    System.IOUtils,
    encoding.json;

var
    contents: TBytes;
    v: Variant;
begin
    contents:= TFile.ReadAllBytes(ParamStr(1));
    if JSON.Unmarshal(pointer(contents),Length(contents),v) = JSONOK then ExitCode:= 0
    else ExitCode:= 1;
end.