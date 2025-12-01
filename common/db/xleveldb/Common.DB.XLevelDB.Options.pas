unit Common.Db.XLevelDB.Options;

interface

uses
  System.SysUtils,
  Common.Db.XLevelDB.Opt.Options,
  Common.Db.XLevelDB.Filter,
  Common.Db.XLevelDB.Comparer;

type
  TCachedOptions = class
  private
    mOptions: TOptions;
    mCompactionExpandLimit: TArray<integer>;
    mCompactionGPOverlaps: TArray<integer>;
    mCompactionSourceLimit: TArray<integer>;
    mCompactionTableSize: TArray<integer>;
    mCompactionTotalSize: TArray<int64>;
    procedure Cache;
  public
    constructor Create(const ParaOptions: TOptions);
    function GetCompactionExpandLimit(const ParaLevel: integer): integer;
    function GetCompactionGPOverlaps(const ParaLevel: integer): integer;
    function GetCompactionSourceLimit(const ParaLevel: integer): integer;
    function GetCompactionTableSize(const ParaLevel: integer): integer;
    function GetCompactionTotalSize(const ParaLevel: integer): int64;
    property Options: TOptions read mOptions;
  end;

  TSession = class
  private
    mOptions: TCachedOptions;
    mComparer: IInternalComparer;
  public
    procedure SetOptions(const ParaOptions: TOptions);
    property Options: TCachedOptions read mOptions;
    property Comparer: IInternalComparer read mComparer;
  end;

function DupOptions(const ParaO: TOptions): TOptions;

implementation

const
  OptCachedLevel = 7;

function DupOptions(const ParaO: TOptions): TOptions;
begin
  Result := ParaO;
  if Result.Strict = [] then
  begin
    Result.Strict := DefaultStrict;
  end;
end;

{ TCachedOptions }

constructor TCachedOptions.Create(const ParaOptions: TOptions);
begin
  inherited Create;
  mOptions := ParaOptions;
  Cache;
end;

procedure TCachedOptions.Cache;
var
  vIndex: integer;
begin
  SetLength(mCompactionExpandLimit, OptCachedLevel);
  SetLength(mCompactionGPOverlaps, OptCachedLevel);
  SetLength(mCompactionSourceLimit, OptCachedLevel);
  SetLength(mCompactionTableSize, OptCachedLevel);
  SetLength(mCompactionTotalSize, OptCachedLevel);

  for vIndex := 0 to OptCachedLevel - 1 do
  begin
    mCompactionExpandLimit[vIndex] := mOptions.GetCompactionExpandLimit(vIndex);
    mCompactionGPOverlaps[vIndex] := mOptions.GetCompactionGPOverlaps(vIndex);
    mCompactionSourceLimit[vIndex] := mOptions.GetCompactionSourceLimit(vIndex);
    mCompactionTableSize[vIndex] := mOptions.GetCompactionTableSize(vIndex);
    mCompactionTotalSize[vIndex] := mOptions.GetCompactionTotalSize(vIndex);
  end;
end;

function TCachedOptions.GetCompactionExpandLimit(const ParaLevel: integer): integer;
begin
  if ParaLevel < OptCachedLevel then
  begin
    Result := mCompactionExpandLimit[ParaLevel];
  end
  else
  begin
    Result := mOptions.GetCompactionExpandLimit(ParaLevel);
  end;
end;

function TCachedOptions.GetCompactionGPOverlaps(const ParaLevel: integer): integer;
begin
  if ParaLevel < OptCachedLevel then
  begin
    Result := mCompactionGPOverlaps[ParaLevel];
  end
  else
  begin
    Result := mOptions.GetCompactionGPOverlaps(ParaLevel);
  end;
end;

function TCachedOptions.GetCompactionSourceLimit(const ParaLevel: integer): integer;
begin
  if ParaLevel < OptCachedLevel then
  begin
    Result := mCompactionSourceLimit[ParaLevel];
  end
  else
  begin
    Result := mOptions.GetCompactionSourceLimit(ParaLevel);
  end;
end;

function TCachedOptions.GetCompactionTableSize(const ParaLevel: integer): integer;
begin
  if ParaLevel < OptCachedLevel then
  begin
    Result := mCompactionTableSize[ParaLevel];
  end
  else
  begin
    Result := mOptions.GetCompactionTableSize(ParaLevel);
  end;
end;

function TCachedOptions.GetCompactionTotalSize(const ParaLevel: integer): int64;
begin
  if ParaLevel < OptCachedLevel then
  begin
    Result := mCompactionTotalSize[ParaLevel];
  end
  else
  begin
    Result := mOptions.GetCompactionTotalSize(ParaLevel);
  end;
end;

{ TSession }

procedure TSession.SetOptions(const ParaOptions: TOptions);
var
  vNo: TOptions;
  vIndex: integer;
  vF: IFilter;
begin
  vNo := DupOptions(ParaOptions);
  // Alternative filters.
  if Length(ParaOptions.GetAltFilters) > 0 then
  begin
    SetLength(vNo.AltFilters, Length(ParaOptions.GetAltFilters));
    for vIndex := 0 to Length(ParaOptions.GetAltFilters) - 1 do
    begin
      vF := ParaOptions.GetAltFilters[vIndex];
      vNo.AltFilters[vIndex] := TIFilter.Create(vF);
    end;
  end;
  // Comparer.
  mComparer := NewIComparer(ParaOptions.GetComparer);
  vNo.Comparer := mComparer;
  // Filter.
  if ParaOptions.GetFilter <> nil then
  begin
    vNo.Filter := TIFilter.Create(ParaOptions.GetFilter);
  end;

  mOptions := TCachedOptions.Create(vNo);
end;

end.
