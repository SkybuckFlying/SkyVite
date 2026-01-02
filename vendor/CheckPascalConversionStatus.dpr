program CheckPascalConversionStatus;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils;

function ExtractQuoted(const S: string; Index: Integer): string;
var
  Parts: TArray<string>;
begin
  Parts := S.Split(['"']);
  if (Index >= 0) and (Index < Length(Parts)) then
    Result := Parts[Index]
  else
    Result := '';
end;

function StripVendorPrefix(const S: string): string;
const
  Prefix = 'vendor\';
begin
  if S.ToLower.StartsWith(Prefix) then
    Result := S.Substring(Length(Prefix))
  else
    Result := S;
end;

var
  InputLines: TStringList;
  OutputLines: TStringList;
  Line: string;
  GoFileRaw, GoFile, PasFileName, PasFullPath: string;
  GoFolder: string;
  GoExists, PasExists: Boolean;
  i: Integer;
begin
  InputLines := TStringList.Create;
  OutputLines := TStringList.Create;
  try
    if not FileExists('ConversionStatusV3.txt') then
    begin
      Writeln('ERROR: ConversionStatusV3.txt not found.');
      Exit;
    end;

    InputLines.LoadFromFile('ConversionStatusV3.txt');

    for i := 0 to InputLines.Count - 1 do
    begin
      Line := InputLines[i].Trim;
      if Line = '' then
        Continue;

      // Extract raw go file path
      GoFileRaw := ExtractQuoted(Line, 1);

      // Remove vendor\ prefix
      GoFile := StripVendorPrefix(GoFileRaw);

      // Extract pascal filename
      PasFileName := ExtractQuoted(Line, 3);

      // Determine folder of the .go file
      GoFolder := ExtractFileDir(GoFile);

      // Build full pascal path inside same folder
      PasFullPath := TPath.Combine(GoFolder, PasFileName);

      // Check existence
      GoExists  := FileExists(GoFile);
      PasExists := FileExists(PasFullPath);

      // Build output
      if GoExists and PasExists then
        OutputLines.Add(Line + ', exists')
      else
        OutputLines.Add(Line + ', does not exist');
    end;

    OutputLines.SaveToFile('ConversionStatusV3_Output.txt');

    Writeln('Done. Output written to ConversionStatusV3_Output.txt');
  finally
    InputLines.Free;
    OutputLines.Free;
  end;
end.
