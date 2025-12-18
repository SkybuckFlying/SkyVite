unit Net.Sync.State;

interface

uses
	System.SysUtils;

type
	TSyncState = ( SyncInit, Syncing, SyncDone, SyncError, SyncCancel );

	TSyncErrorCode = ( syncErrorNoPeers, syncErrorStuck, syncErrorDownload );

function SyncStateToString( ParaSyncState : TSyncState ) : string;
function SyncErrorCodeToString( ParaSyncErrorCode : TSyncErrorCode ) : string;

type
	ISyncState = interface;

	ISyncStateHost = interface
		['{E3B4B3A2-3B3A-4B3A-8B3A-3B3A3B3A3B3A}']
		procedure SetSyncState( ParaState : ISyncState );
	end;

	ISyncState = interface
		['{A2B3B4B3-A2B3-A2B3-A2B3-A2B3A2B3A2B3}']
		function GetState : TSyncState;
		procedure Enter;
		procedure Sync;
		procedure Done;
		procedure Error( ParaReason : TSyncErrorCode );
		procedure Cancel;
		property State : TSyncState read GetState;
	end;

	TSyncStateInit = class( TInterfacedObject, ISyncState )
	private
		mHost : ISyncStateHost;
	public
		constructor Create( ParaHost : ISyncStateHost );
		function GetState : TSyncState;
		procedure Enter;
		procedure Sync;
		procedure Done;
		procedure Error( ParaReason : TSyncErrorCode );
		procedure Cancel;
	end;

	TSyncStateSyncing = class( TInterfacedObject, ISyncState )
	private
		mHost : ISyncStateHost;
	public
		constructor Create( ParaHost : ISyncStateHost );
		function GetState : TSyncState;
		procedure Enter;
		procedure Sync;
		procedure Done;
		procedure Error( ParaReason : TSyncErrorCode );
		procedure Cancel;
	end;

	TSyncStateDone = class( TInterfacedObject, ISyncState )
	private
		mHost : ISyncStateHost;
	public
		constructor Create( ParaHost : ISyncStateHost );
		function GetState : TSyncState;
		procedure Enter;
		procedure Sync;
		procedure Done;
		procedure Error( ParaReason : TSyncErrorCode );
		procedure Cancel;
	end;

	TSyncStateError = class( TInterfacedObject, ISyncState )
	private
		mHost : ISyncStateHost;
	public
		constructor Create( ParaHost : ISyncStateHost );
		function GetState : TSyncState;
		procedure Enter;
		procedure Sync;
		procedure Done;
		procedure Error( ParaReason : TSyncErrorCode );
		procedure Cancel;
	end;

	TSyncStateCancel = class( TInterfacedObject, ISyncState )
	private
		mHost : ISyncStateHost;
	public
		constructor Create( ParaHost : ISyncStateHost );
		function GetState : TSyncState;
		procedure Enter;
		procedure Sync;
		procedure Done;
		procedure Error( ParaReason : TSyncErrorCode );
		procedure Cancel;
	end;

implementation

function SyncStateToString( ParaSyncState : TSyncState ) : string;
begin
	case ParaSyncState of
		SyncInit: Result := 'Sync Not Start';
		Syncing: Result := 'Synchronising';
		SyncDone: Result := 'Sync done';
		SyncError: Result := 'Sync error';
		SyncCancel: Result := 'Sync canceled';
	else
		Result := 'unknown sync state';
	end;
end;

function SyncErrorCodeToString( ParaSyncErrorCode : TSyncErrorCode ) : string;
begin
	case ParaSyncErrorCode of
		syncErrorNoPeers: Result := 'no peers';
		syncErrorStuck: Result := 'stuck';
		syncErrorDownload: Result := 'download error';
	else
		Result := 'unknown sync error';
	end;
end;

{ TSyncStateInit }

constructor TSyncStateInit.Create( ParaHost : ISyncStateHost );
begin
	inherited Create;
	mHost := ParaHost;
end;

function TSyncStateInit.GetState : TSyncState;
begin
	Result := SyncInit;
end;

procedure TSyncStateInit.Enter;
begin
end;

procedure TSyncStateInit.Sync;
begin
	mHost.SetSyncState( TSyncStateSyncing.Create( mHost ) );
end;

procedure TSyncStateInit.Done;
begin
	mHost.SetSyncState( TSyncStateDone.Create( mHost ) );
end;

procedure TSyncStateInit.Error( ParaReason : TSyncErrorCode );
begin
	mHost.SetSyncState( TSyncStateError.Create( mHost ) );
end;

procedure TSyncStateInit.Cancel;
begin
	mHost.SetSyncState( TSyncStateCancel.Create( mHost ) );
end;

{ TSyncStateSyncing }

constructor TSyncStateSyncing.Create( ParaHost : ISyncStateHost );
begin
	inherited Create;
	mHost := ParaHost;
end;

function TSyncStateSyncing.GetState : TSyncState;
begin
	Result := Syncing;
end;

procedure TSyncStateSyncing.Enter;
begin
end;

procedure TSyncStateSyncing.Sync;
begin
	mHost.SetSyncState( TSyncStateSyncing.Create( mHost ) );
end;

procedure TSyncStateSyncing.Done;
begin
	mHost.SetSyncState( TSyncStateDone.Create( mHost ) );
end;

procedure TSyncStateSyncing.Error( ParaReason : TSyncErrorCode );
begin
	mHost.SetSyncState( TSyncStateError.Create( mHost ) );
end;

procedure TSyncStateSyncing.Cancel;
begin
	mHost.SetSyncState( TSyncStateCancel.Create( mHost ) );
end;

{ TSyncStateDone }

constructor TSyncStateDone.Create( ParaHost : ISyncStateHost );
begin
	inherited Create;
	mHost := ParaHost;
end;

function TSyncStateDone.GetState : TSyncState;
begin
	Result := SyncDone;
end;

procedure TSyncStateDone.Enter;
begin
end;

procedure TSyncStateDone.Sync;
begin
	mHost.SetSyncState( TSyncStateSyncing.Create( mHost ) );
end;

procedure TSyncStateDone.Done;
begin
end;

procedure TSyncStateDone.Error( ParaReason : TSyncErrorCode );
begin
end;

procedure TSyncStateDone.Cancel;
begin
end;

{ TSyncStateError }

constructor TSyncStateError.Create( ParaHost : ISyncStateHost );
begin
	inherited Create;
	mHost := ParaHost;
end;

function TSyncStateError.GetState : TSyncState;
begin
	Result := SyncError;
end;

procedure TSyncStateError.Enter;
begin
end;

procedure TSyncStateError.Sync;
begin
	mHost.SetSyncState( TSyncStateSyncing.Create( mHost ) );
end;

procedure TSyncStateError.Done;
begin
	mHost.SetSyncState( TSyncStateDone.Create( mHost ) );
end;

procedure TSyncStateError.Error( ParaReason : TSyncErrorCode );
begin
end;

procedure TSyncStateError.Cancel;
begin
	mHost.SetSyncState( TSyncStateCancel.Create( mHost ) );
end;

{ TSyncStateCancel }

constructor TSyncStateCancel.Create( ParaHost : ISyncStateHost );
begin
	inherited Create;
	mHost := ParaHost;
end;

function TSyncStateCancel.GetState : TSyncState;
begin
	Result := SyncCancel;
end;

procedure TSyncStateCancel.Enter;
begin
end;

procedure TSyncStateCancel.Sync;
begin
end;

procedure TSyncStateCancel.Done;
begin
end;

procedure TSyncStateCancel.Error( ParaReason : TSyncErrorCode );
begin
end;

procedure TSyncStateCancel.Cancel;
begin
end;

end.
