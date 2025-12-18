unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.Options;

interface

uses
  System.Math,
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer.Comparer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter.Filter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.OptionsDarwin,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.OptionsDefault;

const
	KiB = 1024;
	MiB = KiB * 1024;
	GiB = MiB * 1024;

type
	TCompression = (
		DefaultCompression = 0,
		NoCompression = 1,
		SnappyCompression = 2
	);

	TStrict = Cardinal;

const
	StrictManifest         = TStrict( 1 ) shl 0;
	StrictJournalChecksum  = TStrict( 1 ) shl 1;
	StrictJournal          = TStrict( 1 ) shl 2;
	StrictBlockChecksum    = TStrict( 1 ) shl 3;
	StrictCompaction       = TStrict( 1 ) shl 4;
	StrictReader           = TStrict( 1 ) shl 5;
	StrictRecovery         = TStrict( 1 ) shl 6;
	StrictOverride         = TStrict( 1 ) shl 7;

	StrictAll = StrictManifest or StrictJournalChecksum or StrictJournal or StrictBlockChecksum or
	            StrictCompaction or StrictReader or StrictRecovery;

	DefaultStrict = StrictJournalChecksum or StrictBlockChecksum or StrictCompaction or StrictReader;
	NoStrict = not StrictAll;

type
	TOptions = class
	public
		AltFilters : TArray<IFilter>;
		BlockCacheCapacity : Integer;
		BlockCacheEvictRemoved : Boolean;
		BlockRestartInterval : Integer;
		BlockSize : Integer;
		CompactionExpandLimitFactor : Integer;
		CompactionGPOverlapsFactor : Integer;
		CompactionL0Trigger : Integer;
		CompactionSourceLimitFactor : Integer;
		CompactionTableSize : Integer;
		CompactionTableSizeMultiplier : Double;
		CompactionTableSizeMultiplierPerLevel : TArray<Double>;
		CompactionTotalSize : Integer;
		CompactionTotalSizeMultiplier : Double;
		CompactionTotalSizeMultiplierPerLevel : TArray<Double>;
		Comparer : IComparer;
		Compression : TCompression;
		DisableBufferPool : Boolean;
		DisableBlockCache : Boolean;
		DisableCompactionBackoff : Boolean;
		DisableLargeBatchTransaction : Boolean;
		DisableSeeksCompaction : Boolean;
		ErrorIfExist : Boolean;
		ErrorIfMissing : Boolean;
		Filter : IFilter;
		IteratorSamplingRate : Integer;
		NoSync : Boolean;
		NoWriteMerge : Boolean;
		OpenFilesCacheCapacity : Integer;
		ReadOnly : Boolean;
		Strict : TStrict;
		WriteBuffer : Integer;
		WriteL0PauseTrigger : Integer;
		WriteL0SlowdownTrigger : Integer;
		FilterBaseLg : Integer;

		constructor Create;
		
		function GetBlockRestartInterval : Integer;
		function GetBlockSize : Integer;
		function GetComparer : IComparer;
		function GetCompression : TCompression;
		function GetFilter : IFilter;
		function GetFilterBaseLg : Integer;
		function GetStrict( ParaStrict : TStrict ) : Boolean;
	end;

	TReadOptions = record
		DontFillCache : Boolean;
		Strict : TStrict;
		function GetStrict( ParaStrict : TStrict ) : Boolean;
	end;

	TWriteOptions = record
		NoWriteMerge : Boolean;
		Sync : Boolean;
	end;

function GetStrict( ParaO : TOptions; const ParaRo : TReadOptions; ParaStrict : TStrict ) : Boolean;

implementation

{ TOptions }

constructor TOptions.Create;
begin
	BlockCacheCapacity := 8 * MiB;
	BlockRestartInterval := 16;
	BlockSize := 4 * KiB;
	CompactionExpandLimitFactor := 25;
	CompactionGPOverlapsFactor := 10;
	CompactionL0Trigger := 4;
	CompactionSourceLimitFactor := 1;
	CompactionTableSize := 2 * MiB;
	CompactionTableSizeMultiplier := 1.0;
	CompactionTotalSize := 10 * MiB;
	CompactionTotalSizeMultiplier := 10.0;
	Compression := SnappyCompression;
	IteratorSamplingRate := 1 * MiB;
	WriteBuffer := 4 * MiB;
	WriteL0PauseTrigger := 12;
	WriteL0SlowdownTrigger := 8;
	FilterBaseLg := 11;
	Strict := DefaultStrict;
end;

function TOptions.GetBlockRestartInterval : Integer;
begin
	if BlockRestartInterval <= 0 then Result := 16 else Result := BlockRestartInterval;
end;

function TOptions.GetBlockSize : Integer;
begin
	if BlockSize <= 0 then Result := 4 * KiB else Result := BlockSize;
end;

function TOptions.GetComparer : IComparer;
begin
	if Comparer = nil then Result := TBytesComparer.DefaultComparer else Result := Comparer;
end;

function TOptions.GetCompression : TCompression;
begin
	if ( Compression = DefaultCompression ) or ( Ord( Compression ) >= 3 ) then
		Result := SnappyCompression
	else
		Result := Compression;
end;

function TOptions.GetFilter : IFilter;
begin
	Result := Filter;
end;

function TOptions.GetFilterBaseLg : Integer;
begin
	if FilterBaseLg <= 0 then Result := 11 else Result := FilterBaseLg;
end;

function TOptions.GetStrict( ParaStrict : TStrict ) : Boolean;
begin
	if Strict = 0 then
		Result := ( DefaultStrict and ParaStrict ) <> 0
	else
		Result := ( Strict and ParaStrict ) <> 0;
end;

{ TReadOptions }

function TReadOptions.GetStrict( ParaStrict : TStrict ) : Boolean;
begin
	Result := ( Strict and ParaStrict ) <> 0;
end;

{ Global }

function GetStrict( ParaO : TOptions; const ParaRo : TReadOptions; ParaStrict : TStrict ) : Boolean;
begin
	if ParaRo.GetStrict( StrictOverride ) then
		Result := ParaRo.GetStrict( ParaStrict )
	else
		Result := ParaO.GetStrict( ParaStrict ) or ParaRo.GetStrict( ParaStrict );
end;

end.
