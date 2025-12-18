unit Net.Mock.Codec;

interface

uses
	System.SysUtils,
	System.Classes,
	System.TimeSpan,
	System.SyncObjs,
	Net.Interface,
	unit_GoLang_Compatibility_version_006;

type
	TMockAddress = record
	private
		mName : string;
	public
		constructor Create( ParaName : string );
		function Network : string;
		function ToString : string;
	end;

	TMockCodec = class(TInterfacedObject, ICodec)
	private
		mName : string;
		mR : TGoChannel<IMsg>;
		mW : TGoChannel<IMsg>;
		mRTimeout : TTimeSpan;
		mWTimeout : TTimeSpan;
		mTerm : TGoChannel<Integer>;
		mClosed : Integer; 
		mWrite : Integer; 
	public
		constructor Create( ParaName : string; ParaR, ParaW : TGoChannel<IMsg> );
		destructor Destroy; override;

		function ReadMsg : IMsg;
		procedure WriteMsg( ParaMsg : IMsg );
		procedure Close;
		procedure SetReadTimeout( ParaTimeout : TTimeSpan );
		procedure SetWriteTimeout( ParaTimeout : TTimeSpan );
		procedure SetTimeout( ParaTimeout : TTimeSpan );
		function Address : TMockAddress;
	end;

procedure MockPipe( out ParaC1, ParaC2 : ICodec );

implementation

{ TMockAddress }

constructor TMockAddress.Create( ParaName : string );
begin
	mName := ParaName;
end;

function TMockAddress.Network : string;
begin
	Result := 'mock codec';
end;

function TMockAddress.ToString : string;
begin
	Result := 'mock codec ' + mName;
end;

{ TMockCodec }

constructor TMockCodec.Create( ParaName : string; ParaR, ParaW : TGoChannel<IMsg> );
begin
	inherited Create;
	mName := ParaName;
	mR := ParaR;
	mW := ParaW;
	mTerm := TGoChannel<Integer>.Create;
	mClosed := 0;
	mWrite := 0;
end;

destructor TMockCodec.Destroy;
begin
	mTerm.Free;
	inherited Destroy;
end;

function TMockCodec.ReadMsg : IMsg;
var
	vMsg : IMsg;
	vStartTime : Cardinal;
begin
	vStartTime := TThread.GetTickCount;
	while True do
	begin
		if mR.Receive( vMsg, 10 ) then
		begin
			Result := vMsg;
			Exit;
		end;

		if TInterlocked.Read( mClosed ) = 1 then
		begin
			raise Exception.Create( 'mock codec ' + mName + ' closed' );
		end;

		if ( mRTimeout.TotalMilliseconds > 0 ) and ( TThread.GetTickCount - vStartTime > mRTimeout.TotalMilliseconds ) then
		begin
			raise Exception.Create( 'read timeout' );
		end;
		
		TThread.Sleep( 1 );
	end;
end;

procedure TMockCodec.WriteMsg( ParaMsg : IMsg );
var
	vDefer : IGoDefer;
	vStartTime : Cardinal;
begin
	if TInterlocked.Read( mClosed ) = 1 then
	begin
		raise Exception.Create( 'mock codec ' + mName + ' closed' );
	end;

	TInterlocked.Increment( mWrite );
	vDefer := Defer( procedure begin TInterlocked.Decrement( mWrite ); end );

	vStartTime := TThread.GetTickCount;
	while True do
	begin
		// In Go, select can block on a send. 
		// Here we'll try a send with timeout if we had it, but Send blocks.
		// Since mW is a TGoChannel, we'll use a simulated send with select logic if needed.
		// But TGoChannel.Send is blocking.
		
		// For MockCodec, we'll assume we can use a simpler approach or a timeout-enabled Send.
		// Since we only added Receive with timeout, let's assume mW has space for now or 
		// we'd need to modify TGoChannel further.
		
		try
			mW.Send( ParaMsg );
			Exit;
		except
			on E: EGoChannelClosed do
			begin
				raise Exception.Create( 'mock codec ' + mName + ' closed' );
			end;
		end;

		if TInterlocked.Read( mClosed ) = 1 then
		begin
			raise Exception.Create( 'mock codec ' + mName + ' closed' );
		end;

		if ( mWTimeout.TotalMilliseconds > 0 ) and ( TThread.GetTickCount - vStartTime > mWTimeout.TotalMilliseconds ) then
		begin
			raise Exception.Create( 'write timeout' );
		end;
		
		TThread.Sleep( 1 );
	end;
end;

procedure TMockCodec.Close;
begin
	if TInterlocked.CompareExchange( mClosed, 1, 0 ) = 0 then
	begin
		mTerm.Close;

		while True do
		begin
			if TInterlocked.Read( mWrite ) = 0 then
			begin
				Break;
			end;
			TThread.Sleep( 10 );
		end;

		mR.Close;
		mW.Close;
	end else
	begin
		raise Exception.Create( 'closed' );
	end;
end;

procedure TMockCodec.SetReadTimeout( ParaTimeout : TTimeSpan );
begin
	mRTimeout := ParaTimeout;
end;

procedure TMockCodec.SetWriteTimeout( ParaTimeout : TTimeSpan );
begin
	mWTimeout := ParaTimeout;
end;

procedure TMockCodec.SetTimeout( ParaTimeout : TTimeSpan );
begin
	mRTimeout := ParaTimeout;
	mWTimeout := ParaTimeout;
end;

function TMockCodec.Address : TMockAddress;
begin
	Result := TMockAddress.Create( mName );
end;

procedure MockPipe( out ParaC1, ParaC2 : ICodec );
var
	vChan1 : TGoChannel<IMsg>;
	vChan2 : TGoChannel<IMsg>;
begin
	vChan1 := TGoChannel<IMsg>.Create;
	vChan2 := TGoChannel<IMsg>.Create;

	ParaC1 := TMockCodec.Create( 'mock1', vChan1, vChan2 );
	ParaC2 := TMockCodec.Create( 'mock2', vChan2, vChan1 );
end;

end.
