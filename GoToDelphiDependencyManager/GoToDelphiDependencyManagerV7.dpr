program GoToDelphiDependencyManagerV7;

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
  // Standardize everything to lowercase backslashes and remove leading markers
  Result := APath.Replace('/', '\', [rfReplaceAll]).ToLower.Trim([' ', '"', '.', '\']);
end;

procedure TDependencyManager.LoadMappingFile(const AFileName: string);
var
  Lines: TArray<string>;
  Line, GoKey, DelphiPath, RootDir: string;
  LMatch: TMatch;
begin
  if not FileExists(AFileName) then Exit;

  // We assume the application is running in X:\Vite\Branch\Develop\Delphi
  RootDir := TDirectory.GetCurrentDirectory;

  Lines := TFile.ReadAllLines(AFileName);
  for Line in Lines do
  begin
    LMatch := TRegEx.Match(Line, '.*?"(.*?)"\s*,\s*"(.*?)"');
    if LMatch.Success then
    begin
      GoKey := NormalizePath(LMatch.Groups[1].Value);
      DelphiPath := LMatch.Groups[2].Value;

      // Force Delphi path to be relative to the root we are running in
      if not TPath.IsPathRooted(DelphiPath) then
      begin
         // If we are loading the VendorMapping, we check if it's already in a vendor subfolder
         if ContainsText(AFileName, 'Vendor') and not DelphiPath.StartsWith('vendor', True) then
           DelphiPath := TPath.Combine(TPath.Combine(RootDir, 'vendor'), DelphiPath)
         else
           DelphiPath := TPath.Combine(RootDir, DelphiPath);
      end;

      FFileMap.AddOrSetValue(GoKey, ExpandFileName(DelphiPath));
    end;
  end;
  WriteLn(Format('Loaded %d mappings from %s', [FFileMap.Count, ExtractFileName(AFileName)]));
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
    // Check if the GoKey is a file INSIDE the imported package directory
    if (GoKey.StartsWith(SearchPath + '\')) or (GoKey.StartsWith(VendorSearch + '\')) then
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
  if not FileExists(ADelphiFile) then begin Inc(FSkippedPasFiles); Exit; end;

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
  LoadMappingFile('GoToDelphiMapping.txt');
  LoadMappingFile('Vendor\VendorMappingV3.txt');

  for GoKey in FFileMap.Keys do
  begin
    DelphiFile := FFileMap[GoKey];

    // Logic: Try to find the Go file by looking at the key as a relative path
    FullGoPath := ExpandFileName(GoKey);

    if not FileExists(FullGoPath) then
    begin
      // If that fails, try looking for it inside the vendor folder explicitly
      FullGoPath := ExpandFileName(TPath.Combine('vendor', GoKey));
    end;

    if not FileExists(FullGoPath) then
    begin
      Inc(FMissingGoFiles);
      Continue;
    end;

    RequiredUnits := TStringList.Create;
    RequiredUnits.Sorted := True;
    RequiredUnits.Duplicates := dupIgnore;
    try
      // 1. Siblings
      var Siblings := GetSiblingUnits(GoKey);
      RequiredUnits.AddStrings(Siblings);
      Siblings.Free;

      // 2. Imports
      Imports := ExtractGoImports(FullGoPath);
      for var ImpPath in Imports do
      begin
        var Units := GetDelphiUnitsForGoPackage(ImpPath);
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

  WriteLn(Format('Modified: %d | Skipped (Not converted): %d | Missing Go: %d',
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
