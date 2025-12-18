unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Memdb.Memdb;

interface

uses
	System.SysUtils,
	System.SyncObjs,
	System.Math,
	System.Generics.Collections,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer.Comparer,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.Iter,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util;

type
	TDB = class;

	TDBIter = class( TBasicReleaser, IIteratorSeeker, ICommonIterator, IIterator )
	private
		mP : TDB;
		mNode : Integer;
		mForward : Boolean;
		mKey, mValue : TBytes;
		mErr : Exception;
		function Fill( ParaCheckStart, ParaCheckLimit : Boolean ) : Boolean;
		procedure RErr;
	public
		constructor Create( ParaP : TDB );
		function Valid : Boolean; virtual;
		function First : Boolean; virtual;
		function Last : Boolean; virtual;
		function Seek( const ParaKey : TBytes ) : Boolean; virtual;
		function Next : Boolean; virtual;
		function Prev : Boolean; virtual;
		function Key : TBytes; virtual;
		function Value : TBytes; virtual;
		function Error : Exception; virtual;
		procedure Release; override;
	end;

	TDB = class
	private
		mCmp : IBasicComparer;
		mMu : TLightweightMvx; // Using a faster mutex if available, or just TCriticalSection
		mKvData : TBytes;
		mNodeData : TArray<Integer>;
		mPrevNode : array[ 0..11 ] of Integer;
		mMaxHeight : Integer;
		mN : Integer;
		mKvSize : Integer;
		
		const
			tMaxHeight = 12;
			nKV = 0;
			nKey = 1;
			nVal = 2;
			nHeight = 3;
			nNext = 4;
		
		function RandHeight : Integer;
		function FindGE( const ParaKey : TBytes; ParaPrev : Boolean ) : TPair<Integer, Boolean>;
		function FindLT( const ParaKey : TBytes ) : Integer;
		function FindLast : Integer;
	public
		constructor Create( const ParaCmp : IBasicComparer; ParaCapacity : Integer );
		destructor Destroy; override;
		
		procedure Put( const ParaKey, ParaValue : TBytes );
		procedure Delete( const ParaKey : TBytes );
		function Contains( const ParaKey : TBytes ) : Boolean;
		function Get( const ParaKey : TBytes ) : TBytes;
		function NewIterator : IIterator;
		
		property Len : Integer read mN;
		property Size : Integer read mKvSize;
	end;

implementation

{ TDBIter }

constructor TDBIter.Create( ParaP : TDB );
begin
	inherited Create;
	mP := ParaP;
end;

procedure TDBIter.RErr;
begin
	if ( mErr = nil ) and Released then
		mErr := Exception.Create( 'leveldb/memdb: iterator released' );
end;

function TDBIter.Fill( ParaCheckStart, ParaCheckLimit : Boolean ) : Boolean;
var
	vN, vM : Integer;
begin
	if mNode <> 0 then
	begin
		vN := mP.mNodeData[ mNode + TDB.nKV ];
		vM := vN + mP.mNodeData[ mNode + TDB.nKey ];
		mKey := Copy( mP.mKvData, vN, mP.mNodeData[ mNode + TDB.nKey ] );
		mValue := Copy( mP.mKvData, vM, mP.mNodeData[ mNode + TDB.nVal ] );
		Result := True;
	end
	else
	begin
		mKey := nil;
		mValue := nil;
		Result := False;
	end;
end;

function TDBIter.Valid : Boolean;
begin
	Result := mNode <> 0;
end;

function TDBIter.First : Boolean;
begin
	RErr;
	if mErr <> nil then Exit( False );
	
	mForward := True;
	mP.mMu.EnterRead;
	try
		mNode := mP.mNodeData[ TDB.nNext ];
		Result := Fill( False, True );
	finally
		mP.mMu.LeaveRead;
	end;
end;

function TDBIter.Last : Boolean;
begin
	RErr;
	if mErr <> nil then Exit( False );
	
	mForward := False;
	mP.mMu.EnterRead;
	try
		mNode := mP.FindLast;
		Result := Fill( True, False );
	finally
		mP.mMu.LeaveRead;
	end;
end;

function TDBIter.Seek( const ParaKey : TBytes ) : Boolean;
begin
	RErr;
	if mErr <> nil then Exit( False );
	
	mForward := True;
	mP.mMu.EnterRead;
	try
		mNode := mP.FindGE( ParaKey, False ).Key;
		Result := Fill( False, True );
	finally
		mP.mMu.LeaveRead;
	end;
end;

function TDBIter.Next : Boolean;
begin
	RErr;
	if mErr <> nil then Exit( False );
	
	if mNode = 0 then
	begin
		if not mForward then Exit( First );
		Exit( False );
	end;
	
	mForward := True;
	mP.mMu.EnterRead;
	try
		mNode := mP.mNodeData[ mNode + TDB.nNext ];
		Result := Fill( False, True );
	finally
		mP.mMu.LeaveRead;
	end;
end;

function TDBIter.Prev : Boolean;
begin
	RErr;
	if mErr <> nil then Exit( False );
	
	if mNode = 0 then
	begin
		if mForward then Exit( Last );
		Exit( False );
	end;
	
	mForward := False;
	mP.mMu.EnterRead;
	try
		mNode := mP.FindLT( mKey );
		Result := Fill( True, False );
	finally
		mP.mMu.LeaveRead;
	end;
end;

function TDBIter.Key : TBytes;
begin
	Result := mKey;
end;

function TDBIter.Value : TBytes;
begin
	Result := mValue;
end;

function TDBIter.Error : Exception;
begin
	Result := mErr;
end;

procedure TDBIter.Release;
begin
	if not Released then
	begin
		mP := nil;
		mNode := 0;
		mKey := nil;
		mValue := nil;
		inherited;
	end;
end;

{ TDB }

constructor TDB.Create( const ParaCmp : IBasicComparer; ParaCapacity : Integer );
begin
	mCmp := ParaCmp;
	mMu := TLightweightMvx.Create;
	SetLength( mKvData, 0 );
	SetLength( mNodeData, nNext + tMaxHeight );
	mMaxHeight := 1;
	mNodeData[ nHeight ] := tMaxHeight;
end;

destructor TDB.Destroy;
begin
	mMu.Free;
	inherited;
end;

function TDB.RandHeight : Integer;
begin
	Result := 1;
	while ( Result < tMaxHeight ) and ( Random( 4 ) = 0 ) do
		Inc( Result );
end;

function TDB.FindGE( const ParaKey : TBytes; ParaPrev : Boolean ) : TPair<Integer, Boolean>;
var
	vNode, vH, vNext, vO, vCmp : Integer;
begin
	vNode := 0;
	vH := mMaxHeight - 1;
	repeat
		vNext := mNodeData[ vNode + nNext + vH ];
		vCmp := 1;
		if vNext <> 0 then
		begin
			vO := mNodeData[ vNext + nKV ];
			vCmp := mCmp.Compare( Copy( mKvData, vO, mNodeData[ vNext + nKey ] ), ParaKey );
		end;
		
		if vCmp < 0 then
			vNode := vNext
		else
		begin
			if ParaPrev then
				mPrevNode[ vH ] := vNode
			else if vCmp = 0 then
				Exit( TPair<Integer, Boolean>.Create( vNext, True ) );
			
			if vH = 0 then
				Exit( TPair<Integer, Boolean>.Create( vNext, vCmp = 0 ) );
			Dec( vH );
		end;
	until False;
end;

function TDB.FindLT( const ParaKey : TBytes ) : Integer;
var
	vNode, vH, vNext, vO : Integer;
begin
	vNode := 0;
	vH := mMaxHeight - 1;
	repeat
		vNext := mNodeData[ vNode + nNext + vH ];
		if vNext <> 0 then
		begin
			vO := mNodeData[ vNext + nKV ];
			if mCmp.Compare( Copy( mKvData, vO, mNodeData[ vNext + nKey ] ), ParaKey ) >= 0 then
			begin
				if vH = 0 then Break;
				Dec( vH );
			end
			else
				vNode := vNext;
		end
		else
		begin
			if vH = 0 then Break;
			Dec( vH );
		end;
	until False;
	Result := vNode;
end;

function TDB.FindLast : Integer;
var
	vNode, vH, vNext : Integer;
begin
	vNode := 0;
	vH := mMaxHeight - 1;
	repeat
		vNext := mNodeData[ vNode + nNext + vH ];
		if vNext = 0 then
		begin
			if vH = 0 then Break;
			Dec( vH );
		end
		else
			vNode := vNext;
	until False;
	Result := vNode;
end;

procedure TDB.Put( const ParaKey, ParaValue : TBytes );
var
	vRes : TPair<Integer, Boolean>;
	vNode, vH, vKvOffset, vI, vN, vM : Integer;
begin
	mMu.EnterWrite;
	try
		vRes := FindGE( ParaKey, True );
		if vRes.Value then
		begin
			vNode := vRes.Key;
			vKvOffset := Length( mKvData );
			mKvData := mKvData + ParaKey + ParaValue;
			mNodeData[ vNode + nKV ] := vKvOffset;
			vM := mNodeData[ vNode + nVal ];
			mNodeData[ vNode + nVal ] := Length( ParaValue );
			mKvSize := mKvSize + Length( ParaValue ) - vM;
			Exit;
		end;
		
		vH := RandHeight;
		if vH > mMaxHeight then
		begin
			for vI := mMaxHeight to vH - 1 do
				mPrevNode[ vI ] := 0;
			mMaxHeight := vH;
		end;
		
		vKvOffset := Length( mKvData );
		mKvData := mKvData + ParaKey + ParaValue;
		vNode := Length( mNodeData );
		SetLength( mNodeData, vNode + nNext + vH );
		mNodeData[ vNode + nKV ] := vKvOffset;
		mNodeData[ vNode + nKey ] := Length( ParaKey );
		mNodeData[ vNode + nVal ] := Length( ParaValue );
		mNodeData[ vNode + nHeight ] := vH;
		for vI := 0 to vH - 1 do
		begin
			vN := mPrevNode[ vI ];
			vM := vN + nNext + vI;
			mNodeData[ vNode + nNext + vI ] := mNodeData[ vM ];
			mNodeData[ vM ] := vNode;
		end;
		
		mKvSize := mKvSize + Length( ParaKey ) + Length( ParaValue );
		Inc( mN );
	finally
		mMu.LeaveWrite;
	end;
end;

procedure TDB.Delete( const ParaKey : TBytes );
var
	vRes : TPair<Integer, Boolean>;
	vNode, vH, vI, vN, vM : Integer;
begin
	mMu.EnterWrite;
	try
		vRes := FindGE( ParaKey, True );
		if not vRes.Value then
			raise Exception.Create( 'leveldb: not found' );
		
		vNode := vRes.Key;
		vH := mNodeData[ vNode + nHeight ];
		for vI := 0 to vH - 1 do
		begin
			vN := mPrevNode[ vI ];
			vM := vN + nNext + vI;
			mNodeData[ vM ] := mNodeData[ mNodeData[ vM ] + nNext + vI ];
		end;
		
		mKvSize := mKvSize - ( mNodeData[ vNode + nKey ] + mNodeData[ vNode + nVal ] );
		Dec( mN );
	finally
		mMu.LeaveWrite;
	end;
end;

function TDB.Contains( const ParaKey : TBytes ) : Boolean;
begin
	mMu.EnterRead;
	try
		Result := FindGE( ParaKey, False ).Value;
	finally
		mMu.LeaveRead;
	end;
end;

function TDB.Get( const ParaKey : TBytes ) : TBytes;
var
	vRes : TPair<Integer, Boolean>;
	vO : Integer;
begin
	mMu.EnterRead;
	try
		vRes := FindGE( ParaKey, False );
		if vRes.Value then
		begin
			vO := mNodeData[ vRes.Key + nKV ] + mNodeData[ vRes.Key + nKey ];
			Result := Copy( mKvData, vO, mNodeData[ vRes.Key + nVal ] );
		end
		else
			raise Exception.Create( 'leveldb: not found' );
	finally
		mMu.LeaveRead;
	end;
end;

function TDB.NewIterator : IIterator;
begin
	Result := TDBIter.Create( Self );
end;

end.
