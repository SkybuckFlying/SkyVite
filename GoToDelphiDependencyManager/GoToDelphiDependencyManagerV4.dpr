program GoToDelphiDependencyManagerV4;

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
  FModifiedCount := 0;
  FMissingGoFiles := 0;
end;

destructor TDependencyManager.Destroy;
begin
  FFileMap.Free;
  inherited;
end;

function TDependencyManager.NormalizePath(const APath: string): string;
begin
  Result := APath.Replace('/', '\', [rfReplaceAll]).ToLower.Trim([' ', '"']);
  if Result.StartsWith('.\') then Delete(Result, 1, 2);
  if Result.StartsWith('\') then Delete(Result, 1, 1);
end;

procedure TDependencyManager.LoadMappingFile(const AFileName: string);
var
  Lines: TArray<string>;
  Line, GoKey, DelphiPath, MappingDir: string;
  LMatch: TMatch;
begin
  if not FileExists(AFileName) then Exit;

  MappingDir := ExtractFilePath(ExpandFileName(AFileName));
  // If we are loading from the Vendor subfolder, the root is one level up
  if SameText(TPath.GetFileName(ExcludeTrailingPathDelimiter(MappingDir)), 'vendor') then
    MappingDir := TDirectory.GetParent(ExcludeTrailingPathDelimiter(MappingDir));

  Lines := TFile.ReadAllLines(AFileName);
  for Line in Lines do
  begin
    LMatch := TRegEx.Match(Line, '.*?"(.*?)"\s*,\s*"(.*?)"');
    if LMatch.Success then
    begin
      GoKey := NormalizePath(LMatch.Groups[1].Value);
      DelphiPath := LMatch.Groups[2].Value;

      if not TPath.IsPathRooted(DelphiPath) then
        DelphiPath := TPath.Combine(MappingDir, DelphiPath);

      FFileMap.AddOrSetValue(GoKey, ExpandFileName(DelphiPath));
    end;
  end;
  WriteLn(Format('Loaded %d mappings from %s', [Length(Lines), ExtractFileName(AFileName)]));
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

  // Matches 'import "path"' or 'import ( "path" )'
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
  GoKey, SearchPath, VendorSearch: string;
begin
  Result := TStringList.Create;
  SearchPath := NormalizePath(AImportPath);
  VendorSearch := 'vendor\' + SearchPath;

  for GoKey in FFileMap.Keys do
  begin
    // Check if the Go file belongs to the package path (directly or under vendor/)
    if (ExtractFilePath(GoKey).TrimRight(['\']) = SearchPath) or
       (ExtractFilePath(GoKey).TrimRight(['\']) = VendorSearch) then
    begin
      // This retrieves the Delphi Unit Name (e.g., Vendor.Github.Com.Unit)
      Result.Add(TPath.GetFileNameWithoutExtension(FFileMap[GoKey]));
    end;
  end;
end;

function TDependencyManager.GetSiblingUnits(const AGoFilePath: string): TStringList;
var
  GoKey, TargetDir, CurrentKey: string;
begin
  Result := TStringList.Create;
  CurrentKey := NormalizePath(AGoFilePath);
  TargetDir := ExtractFilePath(CurrentKey);

  for GoKey in FFileMap.Keys do
  begin
    if (ExtractFilePath(GoKey) = TargetDir) and (GoKey <> CurrentKey) then
      Result.Add(TPath.GetFileNameWithoutExtension(FFileMap[GoKey]));
  end;
end;

procedure TDependencyManager.UpdateDelphiUses(const ADelphiFile: string; const ANewUnits: TStringList);
var
  Lines, ExistingUnits, NewUses: TStringList;
  I, J, StartIdx, EndIdx: Integer;
  InterfaceFound, UsesFound, Changed: Boolean;
  CurrentUnit, UnitLine: string;
begin
  CurrentUnit := TPath.GetFileNameWithoutExtension(ADelphiFile);
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
    Lines.Free;
    ExistingUnits.Free;
  end;
end;

procedure TDependencyManager.Run;
var
  GoKey, DelphiFile, FullGoPath: string;
  Imports, RequiredUnits: TStringList;
  ImportPath: string;
begin
  LoadMappingFile('GoToDelphiMapping.txt');
  LoadMappingFile('Vendor\VendorMappingV3.txt');

  for GoKey in FFileMap.Keys do
  begin
    DelphiFile := FFileMap[GoKey];
    FullGoPath := ExpandFileName(GoKey);

    if not FileExists(FullGoPath) then
    begin
      Inc(FMissingGoFiles);
      Continue;
    end;

    RequiredUnits := TStringList.Create;
    RequiredUnits.Sorted := True;
    RequiredUnits.Duplicates := dupIgnore;
    try
      // 1. Sibling units in the same vendor package folder
      var Siblings := GetSiblingUnits(GoKey);
      RequiredUnits.AddStrings(Siblings);
      Siblings.Free;

      // 2. Units from Go imports
      Imports := ExtractGoImports(FullGoPath);
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

  WriteLn('--- Process Finished ---');
  WriteLn(Format('Modified Delphi Files: %d', [FModifiedCount]));
  WriteLn(Format('Missing Go Source Files: %d', [FMissingGoFiles]));
end;

begin
  try
    with TDependencyManager.Create do
    try
      Run;
      ReadLn;
    finally
      Free;
    end;
  except
    on E: Exception do Writeln(E.ClassName, ': ', E.Message);
  end;
end.
