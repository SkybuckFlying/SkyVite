program GoToDelphiDependencyManagerV3;

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
    // We store the base directory for each mapping to resolve relative paths
    procedure LoadMappingFile(const AFileName: string);
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
  // Ensure we have a clean, lowercase, backslashed path for consistent mapping
  Result := APath.Replace('/', '\', [rfReplaceAll]).ToLower.Trim([' ', '"', '.']);
  if Result.StartsWith('\') then Delete(Result, 1, 1);
end;

procedure TDependencyManager.LoadMappingFile(const AFileName: string);
var
  Lines: TArray<string>;
  Line, GoPath, DelphiPath, BaseDir: string;
  LMatch: TMatch;
begin
  if not FileExists(AFileName) then
  begin
    WriteLn('Warning: Mapping file not found: ' + AFileName);
    Exit;
  end;

  BaseDir := ExtractFilePath(ExpandFileName(AFileName));
  Lines := TFile.ReadAllLines(AFileName);

  for Line in Lines do
  begin
    LMatch := TRegEx.Match(Line, '.*?"(.*?)"\s*,\s*"(.*?)"');
    if LMatch.Success then
    begin
      GoPath := LMatch.Groups[1].Value;
      DelphiPath := LMatch.Groups[2].Value;

      // Crucial: If the path in the text file is relative, we make it absolute
      // based on the location of the mapping file itself.
      if ExtractFilePath(GoPath) = '' then GoPath := BaseDir + GoPath
      else if not TPath.IsPathRooted(GoPath) then GoPath := TPath.Combine(TPath.GetDirectoryName(ExpandFileName(AFileName)), GoPath);

      if not TPath.IsPathRooted(DelphiPath) then
        DelphiPath := TPath.Combine(TPath.GetDirectoryName(ExpandFileName(AFileName)), DelphiPath);

      // We map the normalized relative path for the Go key, but keep the absolute Delphi path
      FFileMap.AddOrSetValue(NormalizePath(LMatch.Groups[1].Value), ExpandFileName(DelphiPath));
    end;
  end;
  WriteLn(Format('Loaded %d mappings from %s', [Length(Lines), AFileName]));
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

  // Matches 'import "path"' or 'import ( "path1" "path2" )' including aliases
  MC := TRegEx.Matches(Content, 'import\s*(?:\(\s*([\s\S]*?)\s*\)|(?:[a-zA-Z0-9_.]+\s+)? "([^"]+)")');
  for M in MC do
  begin
    if M.Groups[1].Success then
    begin
      var SubMatches := TRegEx.Matches(M.Groups[1].Value, '(?:[a-zA-Z0-9_.]+\s+)? "([^"]+)"');
      for SM in SubMatches do Result.Add(SM.Groups[1].Value);
    end
    else if M.Groups[2].Success then
      Result.Add(M.Groups[2].Value);
  end;
end;

function TDependencyManager.GetDelphiUnitsForGoPackage(const AImportPath: string): TStringList;
var
  GoKey, SearchPath: string;
begin
  Result := TStringList.Create;
  SearchPath := NormalizePath(AImportPath);

  for GoKey in FFileMap.Keys do
  begin
    // Check if the Go file belongs to the imported package path
    if GoKey.StartsWith(SearchPath) then
      Result.Add(TPath.GetFileNameWithoutExtension(FFileMap[GoKey]));
  end;
end;

function TDependencyManager.GetSiblingUnits(const AGoFilePath: string): TStringList;
var
  GoKey, TargetDir, CurrentFile: string;
begin
  Result := TStringList.Create;
  CurrentFile := NormalizePath(AGoFilePath);
  TargetDir := ExtractFilePath(CurrentFile);

  for GoKey in FFileMap.Keys do
  begin
    if (ExtractFilePath(GoKey) = TargetDir) and (GoKey <> CurrentFile) then
      Result.Add(TPath.GetFileNameWithoutExtension(FFileMap[GoKey]));
  end;
end;

procedure TDependencyManager.UpdateDelphiUses(const ADelphiFile: string; const ANewUnits: TStringList);
var
  Lines, ExistingUnits, NewUses: TStringList;
  I, J, StartIdx, EndIdx: Integer;
  InterfaceFound, UsesFound: Boolean;
  CurrentUnitName, UnitLine: string;
begin
  if not FileExists(ADelphiFile) then Exit;

  CurrentUnitName := TPath.GetFileNameWithoutExtension(ADelphiFile);
  Lines := TStringList.Create;
  ExistingUnits := TStringList.Create;
  ExistingUnits.Sorted := True;
  ExistingUnits.Duplicates := dupIgnore;
  try
    Lines.LoadFromFile(ADelphiFile);
    InterfaceFound := False;
    UsesFound := False;
    StartIdx := -1;

    for I := 0 to Lines.Count - 1 do
    begin
      if ContainsText(Lines[I], 'interface') then InterfaceFound := True;
      if InterfaceFound and ContainsText(Lines[I], 'uses') then
      begin
        UsesFound := True;
        StartIdx := I;
        Break;
      end;
      if ContainsText(Lines[I], 'implementation') then Break;
    end;

    if UsesFound then
    begin
      EndIdx := -1;
      for I := StartIdx to Lines.Count - 1 do
      begin
        UnitLine := Lines[I].Replace('uses', '').Replace(';', '').Replace(',', '').Trim;
        if (UnitLine <> '') and (not UnitLine.StartsWith('//')) then
          ExistingUnits.Add(UnitLine);

        if ContainsText(Lines[I], ';') then
        begin
          EndIdx := I;
          Break;
        end;
      end;
      for I := EndIdx downto StartIdx do Lines.Delete(I);
    end
    else
    begin
      StartIdx := -1;
      for I := 0 to Lines.Count - 1 do
        if ContainsText(Lines[I], 'interface') then begin StartIdx := I + 1; Break; end;
      if StartIdx = -1 then StartIdx := 0;
    end;

    for I := 0 to ANewUnits.Count - 1 do
      if (ANewUnits[I] <> '') and (not SameText(ANewUnits[I], CurrentUnitName)) then
        ExistingUnits.Add(ANewUnits[I]);

    if ExistingUnits.Count > 0 then
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
      WriteLn('  [Updated] ' + TPath.GetFileName(ADelphiFile));
    end;
  finally
    Lines.Free;
    ExistingUnits.Free;
  end;
end;

procedure TDependencyManager.Run;
var
  GoKey, DelphiFile, GoFileOnDisk: string;
  Imports, SiblingUnits, RequiredUnits: TStringList;
  ImportPath: string;
begin
  // 1. Load ALL mappings into one dictionary first
  LoadMappingFile('GoToDelphiMapping.txt');
  LoadMappingFile('Vendor\VendorMappingV3.txt');

  WriteLn('Scanning files...');

  // 2. Iterate through every mapped file
  for GoKey in FFileMap.Keys do
  begin
    DelphiFile := FFileMap[GoKey];

    // We need the physical Go file to read imports.
    // Since GoKey is relative, we check relative to current dir
    GoFileOnDisk := GoKey;
    if not FileExists(GoFileOnDisk) then Continue;

    RequiredUnits := TStringList.Create;
    RequiredUnits.Sorted := True;
    RequiredUnits.Duplicates := dupIgnore;
    try
      // Find package siblings
      SiblingUnits := GetSiblingUnits(GoKey);
      RequiredUnits.AddStrings(SiblingUnits);
      SiblingUnits.Free;

      // Find imports
      Imports := ExtractGoImports(GoFileOnDisk);
      for ImportPath in Imports do
      begin
        var Units := GetDelphiUnitsForGoPackage(ImportPath);
        RequiredUnits.AddStrings(Units);
        Units.Free;
      end;
      Imports.Free;

      if RequiredUnits.Count > 0 then
        UpdateDelphiUses(DelphiFile, RequiredUnits);
    finally
      RequiredUnits.Free;
    end;
  end;
end;

begin
  try
    with TDependencyManager.Create do
    try
      Run;
      WriteLn('Process complete.');
      ReadLn;
    finally
      Free;
    end;
  except
    on E: Exception do Writeln(E.ClassName, ': ', E.Message);
  end;
end.
