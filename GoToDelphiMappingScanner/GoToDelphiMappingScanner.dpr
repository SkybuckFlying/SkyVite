program GoToDelphiMappingScanner;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  System.StrUtils;

type
  TMappingEntry = record
    ID: Integer;
    GoFile: string;
    DelphiFile: string;
    LineNum: Integer;
  end;

var
  Mappings: TList<TMappingEntry>;
  GoFilesOnDisk: TDictionary<string, Boolean>;
  DelphiFilesOnDisk: TDictionary<string, Boolean>;
  MappedGoFiles: TDictionary<string, Integer>;
  MappedDelphiFiles: TDictionary<string, Integer>;
  MappedIDs: TDictionary<Integer, Integer>;
  AdditionalFiles: TStringList;
  MissingMappings: TStringList;
  RootPath: string;

function CleanPath(const APath: string): string;
begin
  Result := APath.Replace('/', '\', [rfReplaceAll]).Trim(['"']);
end;

procedure LoadMappings(const AFileName: string);
var
  LLines: TStringList;
  LLine: string;
  LParts: TArray<string>;
  LEntry: TMappingEntry;
  I: Integer;
begin
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(AFileName);
    for I := 0 to LLines.Count - 1 do
    begin
      LLine := LLines[I].Trim;
      if LLine = '' then Continue;

      // Format: ID:"GoFile","DelphiFile"
      LParts := LLine.Split([':']);
      if Length(LParts) < 2 then
      begin
        Writeln('Warning: Invalid line format at ', I + 1, ': ', LLine);
        Continue;
      end;

      LEntry.ID := StrToIntDef(LParts[0], -1);
      LEntry.LineNum := I + 1;

      // The rest is "GoFile","DelphiFile"
      LLine := LLine.Substring(LParts[0].Length + 1);
      LParts := LLine.Split([',']);
      if Length(LParts) >= 2 then
      begin
        LEntry.GoFile := CleanPath(LParts[0]);
        LEntry.DelphiFile := CleanPath(LParts[1]);
        Mappings.Add(LEntry);
      end
      else
        Writeln('Warning: Could not parse files at line ', I + 1);
    end;
  finally
    LLines.Free;
  end;
end;

procedure ScanDisk;
var
  LFiles: TArray<string>;
  LFile: string;
  LRelative: string;
  LPathLower: string;
begin
  LFiles := TDirectory.GetFiles(RootPath, '*', TSearchOption.soAllDirectories);

  for LFile in LFiles do
  begin
    LPathLower := LFile.ToLower;
    // Exclude vendor and golang subfolders
    if LPathLower.Contains('\vendor\') or LPathLower.Contains('\golang\') or
       LPathLower.EndsWith('\vendor') or LPathLower.EndsWith('\golang') then
      Continue;
    
    // Exclude this scanner folder
    if LPathLower.Contains('\gotodelphimappingscanner\') or LPathLower.EndsWith('\gotodelphimappingscanner') then
      Continue;

    LRelative := ExtractRelativePath(RootPath + '\', LFile);
    if LRelative.EndsWith('.go', True) then
    begin
      if not GoFilesOnDisk.ContainsKey(LRelative.ToLower) then
        GoFilesOnDisk.Add(LRelative.ToLower, True);
    end
    else if LRelative.EndsWith('.pas', True) or LRelative.EndsWith('.dpr', True) then
    begin
      if not DelphiFilesOnDisk.ContainsKey(LRelative.ToLower) then
        DelphiFilesOnDisk.Add(LRelative.ToLower, True);
    end;
  end;
end;

procedure RunChecks;
var
  I: Integer;
  LEntry: TMappingEntry;
  LPrevID: Integer;
  LFile: string;
begin
  LPrevID := 0;
  for I := 0 to Mappings.Count - 1 do
  begin
    LEntry := Mappings[I];

    // 3.12 Check that each mapping is unique
    if MappedGoFiles.ContainsKey(LEntry.GoFile.ToLower) then
      Writeln('Error: Duplicate Go file mapping: ', LEntry.GoFile, ' at line ', LEntry.LineNum)
    else
      MappedGoFiles.Add(LEntry.GoFile.ToLower, LEntry.LineNum);

    if MappedDelphiFiles.ContainsKey(LEntry.DelphiFile.ToLower) then
      Writeln('Error: Duplicate Delphi file mapping: ', LEntry.DelphiFile, ' at line ', LEntry.LineNum)
    else
      MappedDelphiFiles.Add(LEntry.DelphiFile.ToLower, LEntry.LineNum);

    if MappedIDs.ContainsKey(LEntry.ID) then
      Writeln('Error: Duplicate ID: ', LEntry.ID, ' at line ', LEntry.LineNum)
    else
      MappedIDs.Add(LEntry.ID, LEntry.LineNum);

    // 3.13 Check that all numberings are sequential
    if (I > 0) and (LEntry.ID <> LPrevID + 1) then
      Writeln('Error: Non-sequential ID at line ', LEntry.LineNum, ': Expected ', LPrevID + 1, ', got ', LEntry.ID);
    LPrevID := LEntry.ID;

    // 3.2 Check if all *.go files are present
    if not GoFilesOnDisk.ContainsKey(LEntry.GoFile.ToLower) then
      Writeln('Error: Go file missing on disk: ', LEntry.GoFile, ' (Mapped at line ', LEntry.LineNum, ')');

    // 3.3 & 3.4 Check if all *.pas/*.dpr files are present
    if not DelphiFilesOnDisk.ContainsKey(LEntry.DelphiFile.ToLower) then
    begin
      Writeln('Error: Delphi file missing on disk: ', LEntry.DelphiFile, ' (Mapped at line ', LEntry.LineNum, ')');
      // 3.10 Save any missing *.pas or *.dpr mappings to GoToDelphiMappingMissingNew.txt
      MissingMappings.Add(Format('%d:"%s","%s"', [LEntry.ID, LEntry.GoFile, LEntry.DelphiFile]));
    end;
  end;

  // 3.6 Report any additional *.go or *.pas files which are not in the GoToDelphiMapping
  for LFile in GoFilesOnDisk.Keys do
    if not MappedGoFiles.ContainsKey(LFile) then
      AdditionalFiles.Add(LFile);

  for LFile in DelphiFilesOnDisk.Keys do
    if not MappedDelphiFiles.ContainsKey(LFile) then
      AdditionalFiles.Add(LFile);
end;

begin
  try
    // RootPath is the parent directory (where GoToDelphiMapping.txt is)
    RootPath := TDirectory.GetParent(TDirectory.GetCurrentDirectory);
    
    if not FileExists('GoToDelphiMapping.txt') then
    begin
      Writeln('Error: GoToDelphiMapping.txt not found in current directory.');
      Exit;
    end;

    Mappings := TList<TMappingEntry>.Create;
    GoFilesOnDisk := TDictionary<string, Boolean>.Create;
    DelphiFilesOnDisk := TDictionary<string, Boolean>.Create;
    MappedGoFiles := TDictionary<string, Integer>.Create;
    MappedDelphiFiles := TDictionary<string, Integer>.Create;
    MappedIDs := TDictionary<Integer, Integer>.Create;
    AdditionalFiles := TStringList.Create;
    MissingMappings := TStringList.Create;

    try
      Writeln('Loading mappings...');
      LoadMappings('GoToDelphiMapping.txt');
      
      Writeln('Scanning disk (excluding vendor and golang) from ', RootPath, '...');
      ScanDisk;

      Writeln('Running checks...');
      RunChecks;

      Writeln('Saving reports...');
      AdditionalFiles.SaveToFile('AdditionalFiles.txt');
      MissingMappings.SaveToFile('GoToDelphiMappingMissingNew.txt');

      Writeln('Done.');
    finally
      Mappings.Free;
      GoFilesOnDisk.Free;
      DelphiFilesOnDisk.Free;
      MappedGoFiles.Free;
      MappedDelphiFiles.Free;
      MappedIDs.Free;
      AdditionalFiles.Free;
      MissingMappings.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  if DebugHook <> 0 then
  begin
    Write('Press Enter to quit...');
    Readln;
  end;
end.
