unit Common.Db.XLevelDB.Opt.Options;

interface

uses
  System.SysUtils,
  Common.Db.XLevelDB.Cache,
  Common.Db.XLevelDB.Comparer,
  Common.Db.XLevelDB.Filter;

const
  KiB = 1024;
  MiB = KiB * 1024;
  GiB = MiB * 1024;

  DefaultBlockCacheCapacity = 8 * MiB;
  DefaultBlockRestartInterval = 16;
  DefaultBlockSize = 4 * KiB;
  DefaultCompactionExpandLimitFactor = 25;
  DefaultCompactionGPOverlapsFactor = 10;
  DefaultCompactionL0Trigger = 4;
  DefaultCompactionSourceLimitFactor = 1;
  DefaultCompactionTableSize = 2 * MiB;
  DefaultCompactionTableSizeMultiplier = 1.0;
  DefaultCompactionTotalSize = 10 * MiB;
  DefaultCompactionTotalSizeMultiplier = 10.0;
  DefaultIteratorSamplingRate = 1 * MiB;
  DefaultOpenFilesCacheCapacity = 500;
  DefaultWriteBuffer = 4 * MiB;
  DefaultWriteL0PauseTrigger = 12;
  DefaultWriteL0SlowdownTrigger = 8;

type
  // Cacher is a caching algorithm.
  ICacher = interface
    ['{D2C1B7A6-D2C1-4E6F-8F3C-3D1B7A6D2C1B}']
    function New(const ParaCapacity: integer): ICacher;
  end;

  // Compression is the 'sorted table' block compression algorithm to use.
  TCompression = (
    DefaultCompression,
    NoCompression,
    SnappyCompression
  );

  // Strict is the DB 'strict level'.
  TStrict = (
    // If present then a corrupted or invalid chunk or block in manifest
    // journal will cause an error instead of being dropped.
    // This will prevent database with corrupted manifest to be opened.
    StrictManifest,
    // If present then journal chunk checksum will be verified.
    StrictJournalChecksum,
    // If present then a corrupted or invalid chunk or block in journal
    // will cause an error instead of being dropped.
    // This will prevent database with corrupted journal to be opened.
    StrictJournal,
    // If present then 'sorted table' block checksum will be verified.
    // This has effect on both 'read operation' and compaction.
    StrictBlockChecksum,
    // If present then a corrupted 'sorted table' will fails compaction.
    // The database will enter read-only mode.
    StrictCompaction,
    // If present then a corrupted 'sorted table' will halts 'read operation'.
    StrictReader,
    // If present then leveldb.Recover will drop corrupted 'sorted table'.
    StrictRecovery,
    // This only applicable for ReadOptions, if present then this ReadOptions
    // 'strict level' will override global ones.
    StrictOverride
  );
  TStricts = set of TStrict;

const
  // StrictAll enables all strict flags.
  StrictAll = [StrictManifest, StrictJournalChecksum, StrictJournal, StrictBlockChecksum, StrictCompaction, StrictReader, StrictRecovery];
  // DefaultStrict is the default strict flags. Specify any strict flags
  // will override default strict flags as whole (i.e. not OR'ed).
  DefaultStrict = [StrictJournalChecksum, StrictBlockChecksum, StrictCompaction, StrictReader];
  // NoStrict disables all strict flags. Override default strict flags.
  NoStrict = [];

type
  // Options holds the optional parameters for the DB at large.
  TOptions = record
    // AltFilters defines one or more 'alternative filters'.
    // 'alternative filters' will be used during reads if a filter block
    // does not match with the 'effective filter'.
    //
    // The default value is nil
    AltFilters: TArray<IFilter>;
    // BlockCacher provides cache algorithm for LevelDB 'sorted table' block caching.
    // Specify NoCacher to disable caching algorithm.
    //
    // The default value is LRUCacher.
    BlockCacher: ICacher;
    // BlockCacheCapacity defines the capacity of the 'sorted table' block caching.
    // Use -1 for zero, this has same effect as specifying NoCacher to BlockCacher.
    //
    // The default value is 8MiB.
    BlockCacheCapacity: integer;
    // BlockRestartInterval is the number of keys between restart points for
    // delta encoding of keys.
    //
    // The default value is 16.
    BlockRestartInterval: integer;
    // BlockSize is the minimum uncompressed size in bytes of each 'sorted table'
    // block.
    //
    // The default value is 4KiB.
    BlockSize: integer;
    // CompactionExpandLimitFactor limits compaction size after expanded.
    // This will be multiplied by table size limit at compaction target level.
    //
    // The default value is 25.
    CompactionExpandLimitFactor: integer;
    // CompactionGPOverlapsFactor limits overlaps in grandparent (Level + 2) that a
    // single 'sorted table' generates.
    // This will be multiplied by table size limit at grandparent level.
    //
    // The default value is 10.
    CompactionGPOverlapsFactor: integer;
    // CompactionL0Trigger defines number of 'sorted table' at level-0 that will
    // trigger compaction.
    //
    // The default value is 4.
    CompactionL0Trigger: integer;
    // CompactionSourceLimitFactor limits compaction source size. This doesn't apply to
    // level-0.
    // This will be multiplied by table size limit at compaction target level.
    //
    // The default value is 1.
    CompactionSourceLimitFactor: integer;
    // CompactionTableSize limits size of 'sorted table' that compaction generates.
    // The limits for each level will be calculated as:
    //   CompactionTableSize * (CompactionTableSizeMultiplier ^ Level)
    // The multiplier for each level can also fine-tuned using CompactionTableSizeMultiplierPerLevel.
    //
    // The default value is 2MiB.
    CompactionTableSize: integer;
    // CompactionTableSizeMultiplier defines multiplier for CompactionTableSize.
    //
    // The default value is 1.
    CompactionTableSizeMultiplier: double;
    // CompactionTableSizeMultiplierPerLevel defines per-level multiplier for
    // CompactionTableSize.
    // Use zero to skip a level.
    //
    // The default value is nil.
    CompactionTableSizeMultiplierPerLevel: TArray<double>;
    // CompactionTotalSize limits total size of 'sorted table' for each level.
    // The limits for each level will be calculated as:
    //   CompactionTotalSize * (CompactionTotalSizeMultiplier ^ Level)
    // The multiplier for each level can also fine-tuned using
    // CompactionTotalSizeMultiplierPerLevel.
    //
    // The default value is 10MiB.
    CompactionTotalSize: integer;
    // CompactionTotalSizeMultiplier defines multiplier for CompactionTotalSize.
    //
    // The default value is 10.
    CompactionTotalSizeMultiplier: double;
    // CompactionTotalSizeMultiplierPerLevel defines per-level multiplier for
    // CompactionTotalSize.
    // Use zero to skip a level.
    //
    // The default value is nil.
    CompactionTotalSizeMultiplierPerLevel: TArray<double>;
    // Comparer defines a total ordering over the space of []byte keys: a 'less
    // than' relationship. The same comparison algorithm must be used for reads
    // and writes over the lifetime of the DB.
    //
    // The default value uses the same ordering as bytes.Compare.
    Comparer: IComparer;
    // Compression defines the 'sorted table' block compression to use.
    //
    // The default value (DefaultCompression) uses snappy compression.
    Compression: TCompression;
    // DisableBufferPool allows disable use of util.BufferPool functionality.
    //
    // The default value is false.
    DisableBufferPool: boolean;
    // DisableBlockCache allows disable use of cache.Cache functionality on
    // 'sorted table' block.
    //
    // The default value is false.
    DisableBlockCache: boolean;
    // DisableCompactionBackoff allows disable compaction retry backoff.
    //
    // The default value is false.
    DisableCompactionBackoff: boolean;
    // DisableLargeBatchTransaction allows disabling switch-to-transaction mode
    // on large batch write. If enable batch writes large than WriteBuffer will
    // use transaction.
    //
    // The default is false.
    DisableLargeBatchTransaction: boolean;
    // ErrorIfExist defines whether an error should returned if the DB already
    // exist.
    //
    // The default value is false.
    ErrorIfExist: boolean;
    // ErrorIfMissing defines whether an error should returned if the DB is
    // missing. If false then the database will be created if missing, otherwise
    // an error will be returned.
    //
    // The default value is false.
    ErrorIfMissing: boolean;
    // Filter defines an 'effective filter' to use. An 'effective filter'
    // if defined will be used to generate per-table filter block.
    // The filter name will be stored on disk.
    // During reads LevelDB will try to find matching filter from
    // 'effective filter' and 'alternative filters'.
    //
    // Filter can be changed after a DB has been created. It is recommended
    // to put old filter to the 'alternative filters' to mitigate lack of
    // filter during transition period.
    //
    // A filter is used to reduce disk reads when looking for a specific key.
    //
    // The default value is nil.
    Filter: IFilter;
    // IteratorSamplingRate defines approximate gap (in bytes) between read
    // sampling of an iterator. The samples will be used to determine when
    // compaction should be triggered.
    //
    // The default is 1MiB.
    IteratorSamplingRate: integer;
    // NoSync allows completely disable fsync.
    //
    // The default is false.
    NoSync: boolean;
    // NoWriteMerge allows disabling write merge.
    //
    // The default is false.
    NoWriteMerge: boolean;
    // OpenFilesCacher provides cache algorithm for open files caching.
    // Specify NoCacher to disable caching algorithm.
    //
    // The default value is LRUCacher.
    OpenFilesCacher: ICacher;
    // OpenFilesCacheCapacity defines the capacity of the open files caching.
    // Use -1 for zero, this has same effect as specifying NoCacher to OpenFilesCacher.
    //
    // The default value is 500.
    OpenFilesCacheCapacity: integer;
    // If true then opens DB in read-only mode.
    //
    // The default value is false.
    ReadOnly: boolean;
    // Strict defines the DB strict level.
    Strict: TStricts;
    // WriteBuffer defines maximum size of a 'memdb' before flushed to
    // 'sorted table'. 'memdb' is an in-memory DB backed by an on-disk
    // unsorted journal.
    //
    // LevelDB may held up to two 'memdb' at the same time.
    //
    // The default value is 4MiB.
    WriteBuffer: integer;
    // WriteL0StopTrigger defines number of 'sorted table' at level-0 that will
    // pause write.
    //
    // The default value is 12.
    WriteL0PauseTrigger: integer;
    // WriteL0SlowdownTrigger defines number of 'sorted table' at level-0 that
    // will trigger write slowdown.
    //
    // The default value is 8.
    WriteL0SlowdownTrigger: integer;

    function GetAltFilters: TArray<IFilter>;
    function GetBlockCacher: ICacher;
    function GetBlockCacheCapacity: integer;
    function GetBlockRestartInterval: integer;
    function GetBlockSize: integer;
    function GetCompactionExpandLimit(const ParaLevel: integer): integer;
    function GetCompactionGPOverlaps(const ParaLevel: integer): integer;
    function GetCompactionL0Trigger: integer;
    function GetCompactionSourceLimit(const ParaLevel: integer): integer;
    function GetCompactionTableSize(const ParaLevel: integer): integer;
    function GetCompactionTotalSize(const ParaLevel: integer): int64;
    function GetComparer: IComparer;
    function GetCompression: TCompression;
    function GetDisableBufferPool: boolean;
    function GetDisableBlockCache: boolean;
    function GetDisableCompactionBackoff: boolean;
    function GetDisableLargeBatchTransaction: boolean;
    function GetErrorIfExist: boolean;
    function GetErrorIfMissing: boolean;
    function GetFilter: IFilter;
    function GetIteratorSamplingRate: integer;
    function GetNoSync: boolean;
    function GetNoWriteMerge: boolean;
    function GetOpenFilesCacher: ICacher;
    function GetOpenFilesCacheCapacity: integer;
    function GetReadOnly: boolean;
    function GetStrict(const ParaStrict: TStrict): boolean;
    function GetWriteBuffer: integer;
    function GetWriteL0PauseTrigger: integer;
    function GetWriteL0SlowdownTrigger: integer;
  end;

  // ReadOptions holds the optional parameters for 'read operation'. The
  // 'read operation' includes Get, Find and NewIterator.
  TReadOptions = record
    // DontFillCache defines whether block reads for this 'read operation'
    // should be cached. If false then the block will be cached. This does
    // not affects already cached block.
    //
    // The default value is false.
    DontFillCache: boolean;
    // Strict will be OR'ed with global DB 'strict level' unless StrictOverride
    // is present. Currently only StrictReader that has effect here.
    Strict: TStricts;
    function GetDontFillCache: boolean;
    function GetStrict(const ParaStrict: TStrict): boolean;
  end;

  // WriteOptions holds the optional parameters for 'write operation'. The
  // 'write operation' includes Write, Put and Delete.
  TWriteOptions = record
    // NoWriteMerge allows disabling write merge.
    //
    // The default is false.
    NoWriteMerge: boolean;
    // Sync is whether to sync underlying writes from the OS buffer cache
    // through to actual disk, if applicable. Setting Sync can result in
    // slower writes.
    //
    // If false, and the machine crashes, then some recent writes may be lost.
    // Note that if it is just the process that crashes (and the machine does
    // not) then no writes will be lost.
    //
    // In other words, Sync being false has the same semantics as a write
    // system call. Sync being true means write followed by fsync.
    //
    // The default value is false.
    Sync: boolean;
    function GetNoWriteMerge: boolean;
    function GetSync: boolean;
  end;

function GetStrict(const ParaO: TOptions; const ParaRo: TReadOptions; const ParaStrict: TStrict): boolean;

implementation

uses
  System.Math;

{ TOptions }

function TOptions.GetAltFilters: TArray<IFilter>;
begin
  Result := Self.AltFilters;
end;

function TOptions.GetBlockCacher: ICacher;
begin
  if Self.BlockCacher = nil then
  begin
    Result := nil // DefaultBlockCacher
  end
  else
  begin
    Result := Self.BlockCacher;
  end;
end;

function TOptions.GetBlockCacheCapacity: integer;
begin
  if Self.BlockCacheCapacity = 0 then
  begin
    Result := DefaultBlockCacheCapacity
  end
  else if Self.BlockCacheCapacity < 0 then
  begin
    Result := 0
  end
  else
  begin
    Result := Self.BlockCacheCapacity;
  end;
end;

function TOptions.GetBlockRestartInterval: integer;
begin
  if Self.BlockRestartInterval <= 0 then
  begin
    Result := DefaultBlockRestartInterval
  end
  else
  begin
    Result := Self.BlockRestartInterval;
  end;
end;

function TOptions.GetBlockSize: integer;
begin
  if Self.BlockSize <= 0 then
  begin
    Result := DefaultBlockSize
  end
  else
  begin
    Result := Self.BlockSize;
  end;
end;

function TOptions.GetCompactionExpandLimit(const ParaLevel: integer): integer;
var
  vFactor: integer;
begin
  vFactor := DefaultCompactionExpandLimitFactor;
  if Self.CompactionExpandLimitFactor > 0 then
  begin
    vFactor := Self.CompactionExpandLimitFactor;
  end;
  Result := Self.GetCompactionTableSize(ParaLevel + 1) * vFactor;
end;

function TOptions.GetCompactionGPOverlaps(const ParaLevel: integer): integer;
var
  vFactor: integer;
begin
  vFactor := DefaultCompactionGPOverlapsFactor;
  if Self.CompactionGPOverlapsFactor > 0 then
  begin
    vFactor := Self.CompactionGPOverlapsFactor;
  end;
  Result := Self.GetCompactionTableSize(ParaLevel + 2) * vFactor;
end;

function TOptions.GetCompactionL0Trigger: integer;
begin
  if Self.CompactionL0Trigger = 0 then
  begin
    Result := DefaultCompactionL0Trigger
  end
  else
  begin
    Result := Self.CompactionL0Trigger;
  end;
end;

function TOptions.GetCompactionSourceLimit(const ParaLevel: integer): integer;
var
  vFactor: integer;
begin
  vFactor := DefaultCompactionSourceLimitFactor;
  if Self.CompactionSourceLimitFactor > 0 then
  begin
    vFactor := Self.CompactionSourceLimitFactor;
  end;
  Result := Self.GetCompactionTableSize(ParaLevel + 1) * vFactor;
end;

function TOptions.GetCompactionTableSize(const ParaLevel: integer): integer;
var
  vBase: integer;
  vMult: double;
begin
  vBase := DefaultCompactionTableSize;
  vMult := 0;
  if Self.CompactionTableSize > 0 then
  begin
    vBase := Self.CompactionTableSize;
  end;
  if (ParaLevel < Length(Self.CompactionTableSizeMultiplierPerLevel)) and (Self.CompactionTableSizeMultiplierPerLevel[ParaLevel] > 0) then
  begin
    vMult := Self.CompactionTableSizeMultiplierPerLevel[ParaLevel]
  end
  else if Self.CompactionTableSizeMultiplier > 0 then
  begin
    vMult := Power(Self.CompactionTableSizeMultiplier, ParaLevel);
  end;
  if vMult = 0 then
  begin
    vMult := Power(DefaultCompactionTableSizeMultiplier, ParaLevel);
  end;
  Result := round(vBase * vMult);
end;

function TOptions.GetCompactionTotalSize(const ParaLevel: integer): int64;
var
  vBase: integer;
  vMult: double;
begin
  vBase := DefaultCompactionTotalSize;
  vMult := 0;
  if Self.CompactionTotalSize > 0 then
  begin
    vBase := Self.CompactionTotalSize;
  end;
  if (ParaLevel < Length(Self.CompactionTotalSizeMultiplierPerLevel)) and (Self.CompactionTotalSizeMultiplierPerLevel[ParaLevel] > 0) then
  begin
    vMult := Self.CompactionTotalSizeMultiplierPerLevel[ParaLevel]
  end
  else if Self.CompactionTotalSizeMultiplier > 0 then
  begin
    vMult := Power(Self.CompactionTotalSizeMultiplier, ParaLevel);
  end;
  if vMult = 0 then
  begin
    vMult := Power(DefaultCompactionTotalSizeMultiplier, ParaLevel);
  end;
  Result := round(vBase * vMult);
end;

function TOptions.GetComparer: IComparer;
begin
  if Self.Comparer = nil then
  begin
    Result := nil // DefaultComparer
  end
  else
  begin
    Result := Self.Comparer;
  end;
end;

function TOptions.GetCompression: TCompression;
begin
  if (Ord(Self.Compression) <= Ord(DefaultCompression)) or (Ord(Self.Compression) >= Ord(SnappyCompression) + 1) then
  begin
    Result := DefaultCompression
  end
  else
  begin
    Result := Self.Compression;
  end;
end;

function TOptions.GetDisableBufferPool: boolean;
begin
  Result := Self.DisableBufferPool;
end;

function TOptions.GetDisableBlockCache: boolean;
begin
  Result := Self.DisableBlockCache;
end;

function TOptions.GetDisableCompactionBackoff: boolean;
begin
  Result := Self.DisableCompactionBackoff;
end;

function TOptions.GetDisableLargeBatchTransaction: boolean;
begin
  Result := Self.DisableLargeBatchTransaction;
end;

function TOptions.GetErrorIfExist: boolean;
begin
  Result := Self.ErrorIfExist;
end;

function TOptions.GetErrorIfMissing: boolean;
begin
  Result := Self.ErrorIfMissing;
end;

function TOptions.GetFilter: IFilter;
begin
  Result := Self.Filter;
end;

function TOptions.GetIteratorSamplingRate: integer;
begin
  if Self.IteratorSamplingRate <= 0 then
  begin
    Result := DefaultIteratorSamplingRate
  end
  else
  begin
    Result := Self.IteratorSamplingRate;
  end;
end;

function TOptions.GetNoSync: boolean;
begin
  Result := Self.NoSync;
end;

function TOptions.GetNoWriteMerge: boolean;
begin
  Result := Self.NoWriteMerge;
end;

function TOptions.GetOpenFilesCacher: ICacher;
begin
  if Self.OpenFilesCacher = nil then
  begin
    Result := nil // DefaultOpenFilesCacher
  end
  else
  begin
    Result := Self.OpenFilesCacher;
  end;
end;

function TOptions.GetOpenFilesCacheCapacity: integer;
begin
  if Self.OpenFilesCacheCapacity = 0 then
  begin
    Result := DefaultOpenFilesCacheCapacity
  end
  else if Self.OpenFilesCacheCapacity < 0 then
  begin
    Result := 0
  end
  else
  begin
    Result := Self.OpenFilesCacheCapacity;
  end;
end;

function TOptions.GetReadOnly: boolean;
begin
  Result := Self.ReadOnly;
end;

function TOptions.GetStrict(const ParaStrict: TStrict): boolean;
begin
  if Self.Strict = [] then
  begin
    Result := ParaStrict in DefaultStrict
  end
  else
  begin
    Result := ParaStrict in Self.Strict;
  end;
end;

function TOptions.GetWriteBuffer: integer;
begin
  if Self.WriteBuffer <= 0 then
  begin
    Result := DefaultWriteBuffer
  end
  else
  begin
    Result := Self.WriteBuffer;
  end;
end;

function TOptions.GetWriteL0PauseTrigger: integer;
begin
  if Self.WriteL0PauseTrigger = 0 then
  begin
    Result := DefaultWriteL0PauseTrigger
  end
  else
  begin
    Result := Self.WriteL0PauseTrigger;
  end;
end;

function TOptions.GetWriteL0SlowdownTrigger: integer;
begin
  if Self.WriteL0SlowdownTrigger = 0 then
  begin
    Result := DefaultWriteL0SlowdownTrigger
  end
  else
  begin
    Result := Self.WriteL0SlowdownTrigger;
  end;
end;

{ TReadOptions }

function TReadOptions.GetDontFillCache: boolean;
begin
  Result := Self.DontFillCache;
end;

function TReadOptions.GetStrict(const ParaStrict: TStrict): boolean;
begin
  Result := ParaStrict in Self.Strict;
end;

{ TWriteOptions }

function TWriteOptions.GetNoWriteMerge: boolean;
begin
  Result := Self.NoWriteMerge;
end;

function TWriteOptions.GetSync: boolean;
begin
  Result := Self.Sync;
end;

function GetStrict(const ParaO: TOptions; const ParaRo: TReadOptions; const ParaStrict: TStrict): boolean;
begin
  if ParaRo.GetStrict(StrictOverride) then
  begin
    Result := ParaRo.GetStrict(ParaStrict)
  end
  else
  begin
    Result := ParaO.GetStrict(ParaStrict) or ParaRo.GetStrict(ParaStrict);
  end;
end;

end.