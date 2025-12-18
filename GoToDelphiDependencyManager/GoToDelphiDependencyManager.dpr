program GoToDelphiDependencyManager;

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

procedure TDependencyManager.LoadMappingFile(const AFileName: string);
var
  Lines: TArray<string>;
  Line: string;
  LMatch: TMatch;
begin
  if not FileExists(AFileName) then Exit;

  FFileMap.Clear;
  Lines := TFile.ReadAllLines(AFileName);
  for Line in Lines do
  begin
    LMatch := TRegEx.Match(Line, ':"(.*?)"\s*,\s*"(.*?)"');
    if LMatch.Success then
      FFileMap.AddOrSetValue(LMatch.Groups[1].Value.ToLower, LMatch.Groups[2].Value);
  end;
end;

function TDependencyManager.ExtractGoImports(const AGoFilePath: string): TStringList;
var
  Content: string;
  MC: TMatchCollection;
  M: TMatch;
  SM: TMatch;
begin
  Result := TStringList.Create;
  Result.Duplicates := dupIgnore;
  Result.Sorted := True;

  if not FileExists(AGoFilePath) then Exit;

  Content := TFile.ReadAllText(AGoFilePath);

  MC := TRegEx.Matches(Content, 'import\s*(?:\(\s*([\s\S]*?)\s*\)|"([^"]+)")');
  for M in MC do
  begin
    if M.Groups[1].Success then
    begin
      var SubMatches := TRegEx.Matches(M.Groups[1].Value, '"([^"]+)"');
      for SM in SubMatches do
        Result.Add(SM.Groups[1].Value);
    end
    else if M.Groups[2].Success then
      Result.Add(M.Groups[2].Value);
  end;
end;

function TDependencyManager.GetDelphiUnitsForGoPackage(const AImportPath: string): TStringList;
var
  GoFile: string;
  NormalizedImport: string;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.Duplicates := dupIgnore;

  NormalizedImport := AImportPath.Replace('/', '\', [rfReplaceAll]);

  for GoFile in FFileMap.Keys do
  begin
    if GoFile.StartsWith(NormalizedImport, True) then
      Result.Add(TPath.GetFileNameWithoutExtension(FFileMap[GoFile]));
  end;
end;

procedure TDependencyManager.UpdateDelphiUses(const ADelphiFile: string; const ANewUnits: TStringList);
var
  Lines: TStringList;
  I, J, StartIdx, EndIdx: Integer;
  ExistingUnits: TStringList;
  InterfaceFound, UsesFound: Boolean;
  UnitLine: string;
  NewUses: TStringList;
begin
  if (ANewUnits.Count = 0) or not FileExists(ADelphiFile) then Exit;

  Lines := TStringList.Create;
  ExistingUnits := TStringList.Create;
  ExistingUnits.Sorted := True;
  ExistingUnits.Duplicates := dupIgnore;
  try
    Lines.LoadFromFile(ADelphiFile);
    InterfaceFound := False;
    UsesFound := False;
    StartIdx := -1;
    EndIdx := -1;

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
      for I := StartIdx to Lines.Count - 1 do
      begin
        UnitLine := Lines[I].Replace('uses', '').Replace(';', '').Replace(',', '').Trim;
        if (UnitLine <> '') then ExistingUnits.Add(UnitLine);
        if ContainsText(Lines[I], ';') then
        begin
          EndIdx := I;
          Break;
        end;
      end;

      for I := 0 to ANewUnits.Count - 1 do
        if ExistingUnits.IndexOf(ANewUnits[I]) = -1 then
          ExistingUnits.Add(ANewUnits[I]);

      for I := EndIdx downto StartIdx do Lines.Delete(I);
    end
    else
    begin
      StartIdx := 0;
      for I := 0 to Lines.Count - 1 do
        if ContainsText(Lines[I], 'interface') then
        begin
          StartIdx := I + 1;
          Break;
        end;
      ExistingUnits.Assign(ANewUnits);
    end;

    NewUses := TStringList.Create;
    try
      NewUses.Add('uses');
      for I := 0 to ExistingUnits.Count - 1 do
      begin
        if I = ExistingUnits.Count - 1 then
          NewUses.Add('  ' + ExistingUnits[I] + ';')
        else
          NewUses.Add('  ' + ExistingUnits[I] + ',');
      end;

      // FIX: Manually insert in reverse order to maintain block order
      for J := NewUses.Count - 1 downto 0 do
        Lines.Insert(StartIdx, NewUses[J]);

    finally
      NewUses.Free;
    end;

    Lines.SaveToFile(ADelphiFile);
    WriteLn('Updated: ' + ADelphiFile);
  finally
    Lines.Free;
    ExistingUnits.Free;
  end;
end;

procedure TDependencyManager.Process(const AMappingFilePath: string);
var
  GoFile, DelphiFile: string;
  Imports: TStringList;
  RequiredDelphiUnits: TStringList;
  ImportPath: string;
  Units: TStringList;
begin
  if not FileExists(AMappingFilePath) then
  begin
    WriteLn('Warning: Mapping file not found: ' + AMappingFilePath);
    Exit;
  end;

  WriteLn('Processing mapping: ' + AMappingFilePath);
  LoadMappingFile(AMappingFilePath);

  for GoFile in FFileMap.Keys do
  begin
    DelphiFile := FFileMap[GoFile];

    if not FileExists(DelphiFile) then Continue;

    Imports := ExtractGoImports(GoFile);
    RequiredDelphiUnits := TStringList.Create;
    RequiredDelphiUnits.Sorted := True;
    RequiredDelphiUnits.Duplicates := dupIgnore;
    try
      for ImportPath in Imports do
      begin
        Units := GetDelphiUnitsForGoPackage(ImportPath);
        try
          RequiredDelphiUnits.AddStrings(Units);
        finally
          Units.Free;
        end;
      end;

      if RequiredDelphiUnits.Count > 0 then
        UpdateDelphiUses(DelphiFile, RequiredDelphiUnits);
    finally
      Imports.Free;
      RequiredDelphiUnits.Free;
    end;
  end;
end;

var
  Manager: TDependencyManager;
begin
  try
    Manager := TDependencyManager.Create;
    try
      Manager.Process('GoToDelphiMapping.txt');
      Manager.Process('Vendor\VendorMappingV3.txt');
    finally
      Manager.Free;
    end;
    WriteLn('Process complete. Press Enter to exit.');
    ReadLn;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
