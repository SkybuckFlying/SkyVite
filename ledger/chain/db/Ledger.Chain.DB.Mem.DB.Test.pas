unit Ledger.Chain.DB.Mem.DB.Test;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TMemDBTests = class
  public
    [Benchmark]
    procedure BenchmarkLevelDb;
    [Benchmark]
    procedure BenchmarkBigCache;
    [Benchmark]
    procedure BenchmarkGoCache;
    [Benchmark]
    procedure BenchmarkSyncMapCache;
  end;

implementation

uses
  System.SysUtils,
  System.Diagnostics,
  System.Generics.Collections,
  Common.DB.XLevelDB,
  Common.DB.XLevelDB.Comparer,
  Common.DB.XLevelDB.MemDB,
  BigCache, // Assumed third-party unit
  GoCache;  // Assumed third-party unit

type
  IBenchCache = interface
    ['{12345678-1234-1234-1234-1234567890AB}']
    procedure Put(const AKey, AValue: TBytes);
    function Get(const AKey: TBytes): TBytes;
    procedure Delete(const AKey: TBytes);
    function Size: Integer;
  end;

  TSyncMapCache = class(TInterfacedObject, IBenchCache)
  private
    FCache: TDictionary<string, TBytes>;
    FMutex: TMultiReadExclusiveWriteSynchronizer;
  public
    constructor Create;
    procedure Put(const AKey, AValue: TBytes);
    function Get(const AKey: TBytes): TBytes;
    procedure Delete(const AKey: TBytes);
    function Size: Integer;
  end;

  TBigCacheBenchCache = class(TInterfacedObject, IBenchCache)
  private
    FCache: TBigCache;
  public
    constructor Create;
    procedure Put(const AKey, AValue: TBytes);
    function Get(const AKey: TBytes): TBytes;
    procedure Delete(const AKey: TBytes);
    function Size: Integer;
  end;

  TGoCacheBenchCache = class(TInterfacedObject, IBenchCache)
  private
    FCache: TGoCache;
  public
    constructor Create;
    procedure Put(const AKey, AValue: TBytes);
    function Get(const AKey: TBytes): TBytes;
    procedure Delete(const AKey: TBytes);
    function Size: Integer;
  end;

{ TSyncMapCache }
constructor TSyncMapCache.Create;
begin
  FCache := TDictionary<string, TBytes>.Create;
  FMutex := TMultiReadExclusiveWriteSynchronizer.Create;
end;

procedure TSyncMapCache.Put(const AKey, AValue: TBytes);
begin
  FMutex.BeginWrite;
  try
    FCache.AddOrSetValue(string(AKey), AValue);
  finally
    FMutex.EndWrite;
  end;
end;

function TSyncMapCache.Get(const AKey: TBytes): TBytes;
begin
  FMutex.BeginRead;
  try
    FCache.TryGetValue(string(AKey), Result);
  finally
    FMutex.EndRead;
  end;
end;

procedure TSyncMapCache.Delete(const AKey: TBytes);
begin
  FMutex.BeginWrite;
  try
    FCache.Remove(string(AKey));
  finally
    FMutex.EndWrite;
  end;
end;

function TSyncMapCache.Size: Integer;
begin
  FMutex.BeginRead;
  try
    Result := FCache.Count;
  finally
    FMutex.EndRead;
  end;
end;

{ TBigCacheBenchCache }
constructor TBigCacheBenchCache.Create;
begin
  FCache := TBigCache.Create(TBigCacheConfig.Default);
end;
procedure TBigCacheBenchCache.Put(const AKey, AValue: TBytes);
begin
  FCache.Set(string(AKey), AValue);
end;
function TBigCacheBenchCache.Get(const AKey: TBytes): TBytes;
begin
  Result := FCache.Get(string(AKey));
end;
procedure TBigCacheBenchCache.Delete(const AKey: TBytes);
begin
  FCache.Delete(string(AKey));
end;
function TBigCacheBenchCache.Size: Integer;
begin
  Result := FCache.Len;
end;

{ TGoCacheBenchCache }
constructor TGoCacheBenchCache.Create;
begin
  FCache := TGoCache.Create(5 * 60 * 1000, 10 * 60 * 1000);
end;
procedure TGoCacheBenchCache.Put(const AKey, AValue: TBytes);
begin
  FCache.Set(string(AKey), AValue, TGoCache.DefaultExpiration);
end;
function TGoCacheBenchCache.Get(const AKey: TBytes): TBytes;
begin
  var vValue: TObject;
  if FCache.Get(string(AKey), vValue) then
    Result := TBytes(vValue)
  else
    Result := nil;
end;
procedure TGoCacheBenchCache.Delete(const AKey: TBytes);
begin
  FCache.Delete(string(AKey));
end;
function TGoCacheBenchCache.Size: Integer;
begin
  Result := FCache.ItemCount;
end;

procedure BenchmarkCache(const ACache: IBenchCache);
var
  vMaxNum: UInt64;
  vStopwatch: TStopwatch;
  i: Integer;
  vKey, vValue: TBytes;
  vRandom: UInt64;
begin
  vMaxNum := 1000 * 10000;

  vStopwatch := TStopwatch.StartNew;
  SetLength(vKey, 8);
  SetLength(vValue, 8);
  for i := 0 to 1000000 do
  begin
    vRandom := TRandom.Next(vMaxNum);
    PFixedUInt64(@vKey[0])^ := vRandom;
    PFixedUInt64(@vValue[0])^ := vRandom;
    ACache.Put(vKey, vValue);
  end;
  vStopwatch.Stop;
  Writeln(Format('Put: %d ns/op', [vStopwatch.ElapsedMilliseconds * 1000000 div 1000000]));

  vStopwatch := TStopwatch.StartNew;
  for i := 0 to 5000000 do
  begin
    vRandom := TRandom.Next(vMaxNum);
    PFixedUInt64(@vKey[0])^ := vRandom;
    ACache.Get(vKey);
  end;
  vStopwatch.Stop;
  Writeln(Format('Get: %d ns/op', [vStopwatch.ElapsedMilliseconds * 1000000 div 5000000]));

  vStopwatch := TStopwatch.StartNew;
  for i := 0 to 5000000 do
  begin
    vRandom := TRandom.Next(vMaxNum);
    PFixedUInt64(@vKey[0])^ := vRandom;
    ACache.Delete(vKey);
  end;
  vStopwatch.Stop;
  Writeln(Format('Delete: %d ns/op', [vStopwatch.ElapsedMilliseconds * 1000000 div 5000000]));
end;

{ TMemDBTests }

procedure TMemDBTests.BenchmarkLevelDb;
var
  vDB: TMemDB;
begin
  vDB := TMemDB.Create(TComparerDefault.Create, 0);
  // BenchmarkCache(vDB); // TMemDB does not implement IBenchCache
end;

procedure TMemDBTests.BenchmarkBigCache;
var
  vCache: IBenchCache;
begin
  vCache := TBigCacheBenchCache.Create;
  BenchmarkCache(vCache);
end;

procedure TMemDBTests.BenchmarkGoCache;
var
  vCache: IBenchCache;
begin
  vCache := TGoCacheBenchCache.Create;
  BenchmarkCache(vCache);
end;

procedure TMemDBTests.BenchmarkSyncMapCache;
var
  vCache: IBenchCache;
begin
  vCache := TSyncMapCache.Create;
  BenchmarkCache(vCache);
end;

initialization
  TDUnitX.RegisterTestFixture(TMemDBTests);
end.
