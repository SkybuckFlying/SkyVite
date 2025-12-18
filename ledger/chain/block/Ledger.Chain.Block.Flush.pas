unit Ledger.Chain.Block.Flush;

interface

uses
  Common.Types,
  Ledger.Chain.Block.Account.Block,
  Ledger.Chain.Block.Block.DB,
  Ledger.Chain.Block.Block.DB.Test,
  Ledger.Chain.Block.Block.Parser,
  Ledger.Chain.Block.Buffer,
  Ledger.Chain.Block.Snapshot.Block,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
	TBufWriter = class(TObject)
	private
		mBuffer : TMemoryStream;
		mErr : Exception;
	public
		constructor Create( ParaBuffer : TMemoryStream );
		class function NewBufWriter : TBufWriter;
		
		procedure Write( ParaData : TBytes );
		procedure WriteError( ParaErr : Exception );
		function Close : Boolean;
		procedure Release;

		property Buffer : TMemoryStream read mBuffer;
		property Err : Exception read mErr;
	end;

	TBlockDBHelper = class helper for TBlockDB
	public
		function Id : THash;
		procedure Prepare;
		procedure CancelPrepare;
		function RedoLog : TBytes;
		function Commit : Boolean;
		procedure AfterCommit;
		procedure BeforeRecover( ParaRedoLog : TBytes );
		procedure AfterRecover;
		function PatchRedoLog( ParaRedoLog : TBytes ) : Boolean;
	end;

implementation

uses
	Ledger.Chain.Utils.Conversion; // Assuming SerializeLocation is here

var
	mBufferPool : TObjectStack<TMemoryStream>;

{ TBufWriter }

constructor TBufWriter.Create( ParaBuffer : TMemoryStream );
begin
	inherited Create;
	mBuffer := ParaBuffer;
	mErr := nil;
end;

class function TBufWriter.NewBufWriter : TBufWriter;
var
	vBuffer : TMemoryStream;
begin
	if ( mBufferPool <> nil ) and ( mBufferPool.Count > 0 ) then
	begin
		vBuffer := mBufferPool.Pop;
	end else
	begin
		vBuffer := TMemoryStream.Create;
	end;
	vBuffer.Size := 0;
	Result := TBufWriter.Create( vBuffer );
end;

procedure TBufWriter.Write( ParaData : TBytes );
begin
	if Length( ParaData ) > 0 then
	begin
		mBuffer.WriteBuffer( ParaData[0], Length( ParaData ) );
	end;
end;

procedure TBufWriter.WriteError( ParaErr : Exception );
begin
	mErr := ParaErr;
end;

function TBufWriter.Close : Boolean;
begin
	Result := True;
end;

procedure TBufWriter.Release;
begin
	if mBuffer <> nil then
	begin
		if mBufferPool = nil then
		begin
			mBufferPool := TObjectStack<TMemoryStream>.Create;
		end;
		mBufferPool.Push( mBuffer );
		mBuffer := nil;
	end;
	Free;
end;

{ TBlockDBHelper }

function TBlockDBHelper.Id : THash;
begin
	Result := mId;
end;

procedure TBlockDBHelper.Prepare;
var
	vBufWriter : TBufWriter;
begin
	mFlushStartLocation := mFM.NextFlushStartLocation;
	mFlushTargetLocation := mFM.LatestLocation;

	vBufWriter := TBufWriter.NewBufWriter;
	try
		mFM.ReadRange( mFlushStartLocation, mFlushTargetLocation, vBufWriter );

		if vBufWriter.Err <> nil then
		begin
			raise Exception.Create( Format( 'BlockDB prepare failed when flush, start location is %+v, target location is %+v. Error: %s', 
				[mFlushStartLocation.ToString, mFlushTargetLocation.ToString, vBufWriter.Err.Message] ) );
		end;

		mFlushBuf := vBufWriter;
		mFM.SetNextFlushStartLocation( mFlushTargetLocation );
	except
		on E: Exception do
		begin
			vBufWriter.Release;
			raise;
		end;
	end;
end;

procedure TBlockDBHelper.CancelPrepare;
begin
	if ( mFM.NextFlushStartLocation.Compare( mFlushStartLocation ) > 0 ) then
	begin
		mFM.SetNextFlushStartLocation( mFlushStartLocation );
	end;

	mFlushStartLocation := nil;
	mFlushTargetLocation := nil;

	if mFlushBuf <> nil then
	begin
		mFlushBuf.Release;
		mFlushBuf := nil;
	end;
end;

function TBlockDBHelper.RedoLog : TBytes;
var
	vData : TBytes;
begin
	SetLength( vData, mFlushBuf.Buffer.Size );
	mFlushBuf.Buffer.Position := 0;
	mFlushBuf.Buffer.ReadBuffer( vData[0], mFlushBuf.Buffer.Size );

	SetLength( Result, 24 + Length( vData ) );
	Move( TConversion.SerializeLocation( mFlushStartLocation )[0], Result[0], 12 );
	Move( TConversion.SerializeLocation( mFlushTargetLocation )[0], Result[12], 12 );
	Move( vData[0], Result[24], Length( vData ) );
end;

function TBlockDBHelper.Commit : Boolean;
var
	vData : TBytes;
begin
	SetLength( vData, mFlushBuf.Buffer.Size );
	mFlushBuf.Buffer.Position := 0;
	mFlushBuf.Buffer.ReadBuffer( vData[0], mFlushBuf.Buffer.Size );
	Result := mFM.Flush( mFlushStartLocation, mFlushTargetLocation, vData );
end;

procedure TBlockDBHelper.AfterCommit;
begin
	mFlushStartLocation := nil;
	mFlushTargetLocation := nil;

	if mFlushBuf <> nil then
	begin
		mFlushBuf.Release;
		mFlushBuf := nil;
	end;
end;

procedure TBlockDBHelper.BeforeRecover( ParaRedoLog : TBytes );
var
	vFlushStartLocation : ILocation;
	vData : TBytes;
begin
	vFlushStartLocation := TConversion.DeserializeLocation( Copy( ParaRedoLog, 0, 12 ) );

	if not mFM.DeleteTo( vFlushStartLocation ) then
	begin
		raise Exception.Create( 'BlockDB recover failed during delete' );
	end;

	vData := Copy( ParaRedoLog, 24, Length( ParaRedoLog ) - 24 );
	if mFM.Write( vData ) < 0 then
	begin
		raise Exception.Create( 'BlockDB recover failed during write' );
	end;
end;

procedure TBlockDBHelper.AfterRecover;
begin
end;

function TBlockDBHelper.PatchRedoLog( ParaRedoLog : TBytes ) : Boolean;
var
	vFlushStartLocation : ILocation;
	vFlushTargetLocation : ILocation;
	vData : TBytes;
begin
	vFlushStartLocation := TConversion.DeserializeLocation( Copy( ParaRedoLog, 0, 12 ) );
	vFlushTargetLocation := TConversion.DeserializeLocation( Copy( ParaRedoLog, 12, 12 ) );
	vData := Copy( ParaRedoLog, 24, Length( ParaRedoLog ) - 24 );

	Result := mFM.Flush( vFlushStartLocation, vFlushTargetLocation, vData );
end;

initialization
	mBufferPool := nil;

finalization
	if mBufferPool <> nil then
	begin
		mBufferPool.Free;
	end;

end.
