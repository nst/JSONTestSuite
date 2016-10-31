{$mode objfpc}
uses
  Classes,SysUtils,fpjson,jsonparser;
var
  Input: TStringList;
  JSON: TJSONData;
begin
  try
    try
      Input := TStringList.Create;
      Input.LoadFromFile(ParamStr(1));
      JSON := GetJSON(Input.Text);
    finally
      JSON.Free;
      Input.Free;
    end;
  except
    on e: EParserError do begin
      ExitCode := 1;
    end;
    on e: Exception do begin
      ExitCode := 2;
    end;
  end;
end.
