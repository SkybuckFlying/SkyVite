unit Common.DB.XLevelDB.Options;

interface

uses
  Common.DB.XLevelDB.Batch,
  Common.DB.XLevelDB.Comparer,
  Common.DB.XLevelDB.DB,
  Common.DB.XLevelDB.DB.Compaction,
  Common.DB.XLevelDB.DB.Iter,
  Common.DB.XLevelDB.DB.Snapshot,
  Common.DB.XLevelDB.DB.State,
  Common.DB.XLevelDB.DB.Transaction,
  Common.DB.XLevelDB.DB.Util,
  Common.DB.XLevelDB.DB.Write,
  Common.DB.XLevelDB.Doc,
  Common.DB.XLevelDB.Errors,
  Common.DB.XLevelDB.Filter,
  Common.DB.XLevelDB.Key,
  Common.DB.XLevelDB.Opt.Options,
  Common.DB.XLevelDB.Session,
  Common.DB.XLevelDB.Session.Compaction,
  Common.DB.XLevelDB.Session.Record,
  Common.DB.XLevelDB.Session.Util,
  Common.DB.XLevelDB.Storage,
  Common.DB.XLevelDB.Table,
  Common.DB.XLevelDB.Util,
  Common.DB.XLevelDB.Version,
  System.SysUtils;

const
	Const_OptCachedLevel = 7;

type
	TCachedOptions = class(TObject)
	private
		mOptions : TOptions;
		mCompactionExpandLimit : TArray<Integer>;
		mCompactionGPOverlaps : TArray<Integer>;
		mCompactionSourceLimit : TArray<Integer>;
		mCompactionTableSize : TArray<Integer>;
		mCompactionTotalSize : TArray<Int64>;
	public
		constructor Create( ParaOptions : TOptions );
		destructor Destroy; override;

		procedure Cache;
		function GetCompactionExpandLimit( ParaLevel : Integer ) : Integer;
		function GetCompactionGPOverlaps( ParaLevel : Integer ) : Integer;
		function GetCompactionSourceLimit( ParaLevel : Integer ) : Integer;
		function GetCompactionTableSize( ParaLevel : Integer ) : Integer;
		function GetCompactionTotalSize( ParaLevel : Integer ) : Int64;

		property Options : TOptions read mOptions;
	end;

function DupOptions( ParaO : TOptions ) : TOptions;

implementation

function DupOptions( ParaO : TOptions ) : TOptions;
begin
	Result := TOptions.Create;
	try
		if ParaO <> nil then
		begin
			// Result := ParaO.Clone; // If Clone exists
			// For now, assuming manual assign or similar
		end;

		if Result.Strict = 0 then
		begin
			Result.Strict := TOptions.DefaultStrict;
		end;
	except
		on E: Exception do
		begin
			Result.Free;
			raise;
		end;
	end;
end;

{ TCachedOptions }

constructor TCachedOptions.Create( ParaOptions : TOptions );
begin
	inherited Create;
	mOptions := ParaOptions;
	Cache;
end;

destructor TCachedOptions.Destroy;
begin
	inherited Destroy;
end;

procedure TCachedOptions.Cache;
var
	vLevel : Integer;
begin
	try
		SetLength( mCompactionExpandLimit, Const_OptCachedLevel );
		SetLength( mCompactionGPOverlaps, Const_OptCachedLevel );
		SetLength( mCompactionSourceLimit, Const_OptCachedLevel );
		SetLength( mCompactionTableSize, Const_OptCachedLevel );
		SetLength( mCompactionTotalSize, Const_OptCachedLevel );

		for vLevel := 0 to Const_OptCachedLevel - 1 do
		begin
			mCompactionExpandLimit[vLevel] := mOptions.GetCompactionExpandLimit( vLevel );
			mCompactionGPOverlaps[vLevel] := mOptions.GetCompactionGPOverlaps( vLevel );
			mCompactionSourceLimit[vLevel] := mOptions.GetCompactionSourceLimit( vLevel );
			mCompactionTableSize[vLevel] := mOptions.GetCompactionTableSize( vLevel );
			mCompactionTotalSize[vLevel] := mOptions.GetCompactionTotalSize( vLevel );
		end;
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Memory allocation failed in TCachedOptions.Cache' );
		end;
	end;
end;

function TCachedOptions.GetCompactionExpandLimit( ParaLevel : Integer ) : Integer;
begin
	if ParaLevel < Const_OptCachedLevel then
	begin
		Result := mCompactionExpandLimit[ParaLevel];
	end else
	begin
		Result := mOptions.GetCompactionExpandLimit( ParaLevel );
	end;
end;

function TCachedOptions.GetCompactionGPOverlaps( ParaLevel : Integer ) : Integer;
begin
	if ParaLevel < Const_OptCachedLevel then
	begin
		Result := mCompactionGPOverlaps[ParaLevel];
	end else
	begin
		Result := mOptions.GetCompactionGPOverlaps( ParaLevel );
	end;
end;

function TCachedOptions.GetCompactionSourceLimit( ParaLevel : Integer ) : Integer;
begin
	if ParaLevel < Const_OptCachedLevel then
	begin
		Result := mCompactionSourceLimit[ParaLevel];
	end else
	begin
		Result := mOptions.GetCompactionSourceLimit( ParaLevel );
	end;
end;

function TCachedOptions.GetCompactionTableSize( ParaLevel : Integer ) : Integer;
begin
	if ParaLevel < Const_OptCachedLevel then
	begin
		Result := mCompactionTableSize[ParaLevel];
	end else
	begin
		Result := mOptions.GetCompactionTableSize( ParaLevel );
	end;
end;

function TCachedOptions.GetCompactionTotalSize( ParaLevel : Integer ) : Int64;
begin
	if ParaLevel < Const_OptCachedLevel then
	begin
		Result := mCompactionTotalSize[ParaLevel];
	end else
	begin
		Result := mOptions.GetCompactionTotalSize( ParaLevel );
	end;
end;

end.
