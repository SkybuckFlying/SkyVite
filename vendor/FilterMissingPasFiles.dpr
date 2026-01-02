program FilterMissingPasFiles;

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
    if not FileExists('ConversionStatusV3_Output.txt') then
    begin
      Writeln('ERROR: ConversionStatusV3_Output.txt not found.');
      Exit;
    end;

    InputLines.LoadFromFile('ConversionStatusV3_Output.txt');

    for i := 0 to InputLines.Count - 1 do
    begin
      Line := InputLines[i].Trim;
      if Line = '' then
        Continue;

      // Extract raw go file path (first quoted string)
      GoFileRaw := ExtractQuoted(Line, 1);

      // Apply same vendor stripping rule
      GoFile := StripVendorPrefix(GoFileRaw);

      // Extract Pascal filename (second quoted string)
      PasFileName := ExtractQuoted(Line, 3);

      // Determine folder of the .go file
      GoFolder := ExtractFileDir(GoFile);

      // Build full Pascal path inside same folder
      PasFullPath := TPath.Combine(GoFolder, PasFileName);

      // Check existence
      GoExists  := FileExists(GoFile);
      PasExists := FileExists(PasFullPath);

      // Keep only lines where:
      //   - .go file exists
      //   - .pas file does NOT exist
      if GoExists and (not PasExists) then
        OutputLines.Add(Line);
    end;

    OutputLines.SaveToFile('Missing.txt');

    Writeln('Done. Missing Pascal files written to Missing.txt');
  finally
    InputLines.Free;
    OutputLines.Free;
  end;
end.
