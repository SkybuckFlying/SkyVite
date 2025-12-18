    program GoToDelphiDependencyManagerV8;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  System.RegularExpressions,
  System.StrUtils,
  System.Types;

type
  TMapping = TDictionary<string, string>;

  TDependencyManager = class
  private
    FFileMap: TMapping;
    FModifiedCount: Integer;
    FMissingGoFiles: Integer;
    FSkippedPasFiles: Integer;
    procedure LoadMappingFile(const AFileName: string; IsVendor: Boolean);
    function ExtractGoImports(const AGoFilePath: string): TStringList;
    procedure UpdateDelphiUses(const ADelphiFile: string; const ANewUnits: TStringList);
    function GetDelphiUnitsForGoPackage(const AImportPath: string): TStringList;
    function GetSiblingUnits(const AGoFilePath: string): TStringList;
    function NormalizePath(const APath: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Run;
  end;

{ TDependencyManager }

constructor TDependencyManager.Create;
begin
  FFileMap := TMapping.Create;
end;

destructor TDependencyManager.Destroy;
begin
  FFileMap.Free;
  inherited;
end;

function TDependencyManager.NormalizePath(const APath: string): string;
begin
  Result := APath.Replace('/', '\', [rfReplaceAll]).ToLower.Trim([' ', '"', '.', '\']);
end;

procedure TDependencyManager.LoadMappingFile(const AFileName: string; IsVendor: Boolean);
var
  Lines: TArray<string>;
  Line, GoKey, DelphiUnit, FinalPasPath, RootDir, SubFolder: string;
  LMatch: TMatch;
begin
  if not FileExists(AFileName) then Exit;
  RootDir := TDirectory.GetCurrentDirectory;

  Lines := TFile.ReadAllLines(AFileName);
  for Line in Lines do
  begin
    // Regex matches "GoPath", "DelphiUnitOrPath"
    LMatch := TRegEx.Match(Line, '.*?"(.*?)"\s*,\s*"(.*?)"');
    if LMatch.Success then
    begin
      GoKey := NormalizePath(LMatch.Groups[1].Value);
      DelphiUnit := LMatch.Groups[2].Value; // e.g. "Vendor.Github.Com..."

      if IsVendor then
      begin
        // Logic: vendor\ + go_subfolder + \ + DelphiUnitName
        SubFolder := ExtractFilePath(GoKey);
        // Ensure it starts with 'vendor\'
        if not SubFolder.StartsWith('vendor\') then
          SubFolder := 'vendor\' + SubFolder;

        FinalPasPath := TPath.Combine(TPath.Combine(RootDir, SubFolder), DelphiUnit);
        if not SameText(ExtractFileExt(FinalPasPath), '.pas') then
          FinalPasPath := FinalPasPath + '.pas';
      end
      else
      begin
        // Standard mapping logic for project files
        if not TPath.IsPathRooted(DelphiUnit) then
          FinalPasPath := TPath.Combine(RootDir, DelphiUnit)
        else
          FinalPasPath := DelphiUnit;
      end;

      FFileMap.AddOrSetValue(GoKey, ExpandFileName(FinalPasPath));
    end;
  end;
  WriteLn(Format('Loaded %s: %d mappings.', [ExtractFileName(AFileName), FFileMap.Count]));
end;

function TDependencyManager.GetDelphiUnitsForGoPackage(const AImportPath: string): TStringList;
var
  GoKey, SearchPath, VendorSearch: string;
begin
  Result := TStringList.Create;
  SearchPath := NormalizePath(AImportPath);
  VendorSearch := 'vendor\' + SearchPath;

  for GoKey in FFileMap.Keys do
  begin
    // Match files inside the package directory
    if GoKey.StartsWith(SearchPath + '\') or GoKey.StartsWith(VendorSearch + '\') then
      Result.Add(TPath.GetFileNameWithoutExtension(FFileMap[GoKey]));
  end;
end;

function TDependencyManager.GetSiblingUnits(const AGoFilePath: string): TStringList;
var
  GoKey, TargetDir, CurrentKey: string;
begin
  Result := TStringList.Create;
  CurrentKey := NormalizePath(AGoFilePath);
  TargetDir := ExtractFilePath(CurrentKey).TrimRight(['\']);

  for GoKey in FFileMap.Keys do
  begin
    if (ExtractFilePath(GoKey).TrimRight(['\']) = TargetDir) and (GoKey <> CurrentKey) then
      Result.Add(TPath.GetFileNameWithoutExtension(FFileMap[GoKey]));
  end;
end;

function TDependencyManager.ExtractGoImports(const AGoFilePath: string): TStringList;
var
  Content: string;
  MC: TMatchCollection;
  M, SM: TMatch;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.Duplicates := dupIgnore;
  if not FileExists(AGoFilePath) then Exit;
  Content := TFile.ReadAllText(AGoFilePath);
  MC := TRegEx.Matches(Content, 'import\s*(?:\(\s*([\s\S]*?)\s*\)|(?:[a-zA-Z0-9_.]+\s+)? "([^"]+)")');
  for M in MC do
  begin
    if M.Groups[1].Success then
    begin
      var SubMatches := TRegEx.Matches(M.Groups[1].Value, '(?:[a-zA-Z0-9_.]+\s+)? "([^"]+)"');
      for SM in SubMatches do Result.Add(SM.Groups[1].Value);
    end
    else if M.Groups[2].Success then Result.Add(M.Groups[2].Value);
  end;
end;

procedure TDependencyManager.UpdateDelphiUses(const ADelphiFile: string; const ANewUnits: TStringList);
var
  Lines, ExistingUnits, NewUses: TStringList;
  I, J, StartIdx, EndIdx: Integer;
  InterfaceFound, UsesFound, Changed: Boolean;
  CurrentUnit, UnitLine: string;
begin
  if not FileExists(ADelphiFile) then
  begin
    Inc(FSkippedPasFiles);
    Exit;
  end;

  CurrentUnit := TPath.GetFileNameWithoutExtension(ADelphiFile);
  Lines := TStringList.Create;
  ExistingUnits := TStringList.Create;
  ExistingUnits.Sorted := True;
  ExistingUnits.Duplicates := dupIgnore;
  try
    Lines.LoadFromFile(ADelphiFile);
    InterfaceFound := False; UsesFound := False; StartIdx := -1;

    for I := 0 to Lines.Count - 1 do
    begin
      if ContainsText(Lines[I], 'interface') then InterfaceFound := True;
      if InterfaceFound and ContainsText(Lines[I], 'uses') then
      begin
        UsesFound := True; StartIdx := I; Break;
      end;
      if ContainsText(Lines[I], 'implementation') then Break;
    end;

    if UsesFound then
    begin
      EndIdx := -1;
      for I := StartIdx to Lines.Count - 1 do
      begin
        UnitLine := Lines[I].Replace('uses', '').Replace(';', '').Replace(',', '').Trim;
        if (UnitLine <> '') and (not UnitLine.StartsWith('//')) then ExistingUnits.Add(UnitLine);
        if ContainsText(Lines[I], ';') then begin EndIdx := I; Break; end;
      end;
      for I := EndIdx downto StartIdx do Lines.Delete(I);
    end
    else
    begin
      for I := 0 to Lines.Count - 1 do
        if ContainsText(Lines[I], 'interface') then begin StartIdx := I + 1; Break; end;
    end;

    if StartIdx = -1 then Exit;

    Changed := False;
    for I := 0 to ANewUnits.Count - 1 do
      if (ANewUnits[I] <> '') and (not SameText(ANewUnits[I], CurrentUnit)) then
        if ExistingUnits.IndexOf(ANewUnits[I]) = -1 then
        begin
          ExistingUnits.Add(ANewUnits[I]);
          Changed := True;
        end;

    if Changed then
    begin
      NewUses := TStringList.Create;
      try
        NewUses.Add('uses');
        for I := 0 to ExistingUnits.Count - 1 do
          if I = ExistingUnits.Count - 1 then NewUses.Add('  ' + ExistingUnits[I] + ';')
          else NewUses.Add('  ' + ExistingUnits[I] + ',');
        for J := NewUses.Count - 1 downto 0 do Lines.Insert(StartIdx, NewUses[J]);
      finally
        NewUses.Free;
      end;
      Lines.SaveToFile(ADelphiFile);
      Inc(FModifiedCount);
    end;
  finally
    Lines.Free; ExistingUnits.Free;
  end;
end;

procedure TDependencyManager.Run;
var
  GoKey, DelphiFile, FullGoPath: string;
  Imports, RequiredUnits: TStringList;
begin
  // Load standard mapping
  LoadMappingFile('GoToDelphiMapping.txt', False);
  // Load vendor mapping with special path logic
  LoadMappingFile('Vendor\VendorMappingV3.txt', True);

  for GoKey in FFileMap.Keys do
  begin
    DelphiFile := FFileMap[GoKey];

    // Check if the Go file exists at the mapped key path
    FullGoPath := ExpandFileName(GoKey);
    if not FileExists(FullGoPath) then
      FullGoPath := ExpandFileName(TPath.Combine('vendor', GoKey));

    if not FileExists(FullGoPath) then
    begin
      Inc(FMissingGoFiles);
      Continue;
    end;

    RequiredUnits := TStringList.Create;
    try
      RequiredUnits.AddStrings(GetSiblingUnits(GoKey));
      Imports := ExtractGoImports(FullGoPath);
      for var ImpPath in Imports do
        RequiredUnits.AddStrings(GetDelphiUnitsForGoPackage(ImpPath));
      Imports.Free;

      if RequiredUnits.Count > 0 then
        UpdateDelphiUses(DelphiFile, RequiredUnits);
    finally
      RequiredUnits.Free;
    end;
  end;

  WriteLn(Format('Modified: %d | Skipped: %d | Missing Go: %d',
    [FModifiedCount, FSkippedPasFiles, FMissingGoFiles]));
end;

begin
  try
    with TDependencyManager.Create do
    try
      FModifiedCount := 0; FMissingGoFiles := 0; FSkippedPasFiles := 0;
      Run;
      ReadLn;
    finally
      Free;
    end;
  except
    on E: Exception do Writeln(E.Message);
  end;
end.
