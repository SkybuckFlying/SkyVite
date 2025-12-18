program GoToDelphiDependencyManagerV2;

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
    procedure LoadMappingFile(const AFileName: string);
    function ExtractGoImports(const AGoFilePath: string): TStringList;
    procedure UpdateDelphiUses(const ADelphiFile: string; const ANewUnits: TStringList);
    function GetDelphiUnitsForGoPackage(const AImportPath: string): TStringList;
    function GetSiblingUnits(const AGoFilePath: string): TStringList;
    function NormalizePath(const APath: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Process(const AMappingFilePath: string);
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
  // Standardize to lowercase and backslashes for dictionary lookups
  Result := APath.Replace('/', '\', [rfReplaceAll]).ToLower.Trim([' ', '"']);
end;

procedure TDependencyManager.LoadMappingFile(const AFileName: string);
var
  Lines: TArray<string>;
  Line: string;
  LMatch: TMatch;
begin
  if not FileExists(AFileName) then Exit;

  Lines := TFile.ReadAllLines(AFileName);
  for Line in Lines do
  begin
    // Regex allows for optional numbers and handles quotes
    LMatch := TRegEx.Match(Line, '.*?"(.*?)"\s*,\s*"(.*?)"');
    if LMatch.Success then
      FFileMap.AddOrSetValue(NormalizePath(LMatch.Groups[1].Value), LMatch.Groups[2].Value);
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

  // Improved Regex: Handles aliases e.g., 'import alias "path"' and multi-line imports
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
  GoKey: string;
  SearchPath: string;
begin
  Result := TStringList.Create;
  SearchPath := NormalizePath(AImportPath);

  for GoKey in FFileMap.Keys do
  begin
    // If the mapping entry starts with the package path (indicating it's inside that folder)
    if GoKey.StartsWith(SearchPath) then
      Result.Add(TPath.GetFileNameWithoutExtension(FFileMap[GoKey]));
  end;
end;

function TDependencyManager.GetSiblingUnits(const AGoFilePath: string): TStringList;
var
  GoKey, TargetDir: string;
begin
  Result := TStringList.Create;
  TargetDir := ExtractFilePath(NormalizePath(AGoFilePath));

  for GoKey in FFileMap.Keys do
  begin
    // Find files in the exact same directory (siblings in the same Go package)
    if (ExtractFilePath(GoKey) = TargetDir) and (GoKey <> NormalizePath(AGoFilePath)) then
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
        if UnitLine <> '' then ExistingUnits.Add(UnitLine);
        if ContainsText(Lines[I], ';') then { End of uses clause }
        begin
          EndIdx := I;
          Break;
        end;
      end;
      for I := EndIdx downto StartIdx do Lines.Delete(I);
    end
    else
    begin
      StartIdx := 0;
      for I := 0 to Lines.Count - 1 do
        if ContainsText(Lines[I], 'interface') then begin StartIdx := I + 1; Break; end;
    end;

    // Merge new units, excluding self
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
    end;
  finally
    Lines.Free;
    ExistingUnits.Free;
  end;
end;

procedure TDependencyManager.Process(const AMappingFilePath: string);
var
  GoFile, DelphiFile: string;
  Imports, SiblingUnits, RequiredUnits: TStringList;
  ImportPath: string;
begin
  if not FileExists(AMappingFilePath) then Exit;
  WriteLn('--- Processing: ' + AMappingFilePath);
  LoadMappingFile(AMappingFilePath);

  for GoFile in FFileMap.Keys do
  begin
    DelphiFile := FFileMap[GoFile];
    if not FileExists(DelphiFile) then Continue;

    RequiredUnits := TStringList.Create;
    RequiredUnits.Sorted := True;
    RequiredUnits.Duplicates := dupIgnore;

    // 1. Get units from Go Folder siblings (Same package)
    SiblingUnits := GetSiblingUnits(GoFile);
    RequiredUnits.AddStrings(SiblingUnits);
    SiblingUnits.Free;

    // 2. Get units from explicit Go Imports
    Imports := ExtractGoImports(GoFile);
    for ImportPath in Imports do
    begin
      var Units := GetDelphiUnitsForGoPackage(ImportPath);
      RequiredUnits.AddStrings(Units);
      Units.Free;
    end;
    Imports.Free;

    if RequiredUnits.Count > 0 then
      UpdateDelphiUses(DelphiFile, RequiredUnits);

    RequiredUnits.Free;
  end;
end;

begin
  with TDependencyManager.Create do
  try
    Process('GoToDelphiMapping.txt');
    Process('Vendor\VendorMappingV3.txt');
    WriteLn('Done. Check your git status again.');
    ReadLn;
  finally
    Free;
  end;
end.
