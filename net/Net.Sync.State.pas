{
 * Copyright 2019 The go-vite Authors
 * This file is part of the go-vite library.
 *
 * The go-vite library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The go-vite library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with the go-vite library. If not, see <http://www.gnu.org/licenses/>.
}
unit net.sync_state;

interface

uses
	System.SysUtils;

type
	TSyncState = (
		SyncInit,
		Syncing,
		SyncDone,
		SyncError,
		SyncCancel
	);

	TSyncErrorCode = (
		syncErrorNoPeers,
		syncErrorStuck,
		syncErrorDownload
	);

function SyncStateToString(ParaSyncState: TSyncState): string;
function SyncErrorCodeToString(ParaSyncErrorCode: TSyncErrorCode): string;

type
	ISyncState;

	ISyncStateHost = interface
		['{E3B4B3A2-3B3A-4B3A-8B3A-3B3A3B3A3B3A}']
		procedure SetState(ParaState: ISyncState);
	end;

	ISyncState = interface
		['{A2B3B4B3-A2B3-A2B3-A2B3-A2B3A2B3A2B3}']
		function GetState: TSyncState;
		procedure Enter;
		procedure Sync;
		procedure Done;
		procedure Error(ParaReason: TSyncErrorCode);
		procedure Cancel;
		property State: TSyncState read GetState;
	end;

	TSyncStateInit = class(TInterfacedObject, ISyncState)
	private
		mHost: ISyncStateHost;
	public
		constructor Create(ParaHost: ISyncStateHost);
		function GetState: TSyncState;
		procedure Enter;
		procedure Sync;
		procedure Done;
		procedure Error(ParaReason: TSyncErrorCode);
		procedure Cancel;
	end;

	TSyncStateSyncing = class(TInterfacedObject, ISyncState)
	private
		mHost: ISyncStateHost;
	public
		constructor Create(ParaHost: ISyncStateHost);
		function GetState: TSyncState;
		procedure Enter;
		procedure Sync;
		procedure Done;
		procedure Error(ParaReason: TSyncErrorCode);
		procedure Cancel;
	end;

	TSyncStateDone = class(TInterfacedObject, ISyncState)
	private
		mHost: ISyncStateHost;
	public
		constructor Create(ParaHost: ISyncStateHost);
		function GetState: TSyncState;
		procedure Enter;
		procedure Sync;
		procedure Done;
		procedure Error(ParaReason: TSyncErrorCode);
		procedure Cancel;
	end;

	TSyncStateError = class(TInterfacedObject, ISyncState)
	private
		mHost: ISyncStateHost;
	public
		constructor Create(ParaHost: ISyncStateHost);
		function GetState: TSyncState;
		procedure Enter;
		procedure Sync;
		procedure Done;
		procedure Error(ParaReason: TSyncErrorCode);
		procedure Cancel;
	end;

	TSyncStateCancel = class(TInterfacedObject, ISyncState)
	private
		mHost: ISyncStateHost;
	public
		constructor Create(ParaHost: ISyncStateHost);
		function GetState: TSyncState;
		procedure Enter;
		procedure Sync;
		procedure Done;
		procedure Error(ParaReason: TSyncErrorCode);
		procedure Cancel;
	end;

implementation

var
	errTooShort: Exception;
	errUnknownSyncState: Exception;

function SyncStateToString(ParaSyncState: TSyncState): string;
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

function SyncErrorCodeToString(ParaSyncErrorCode: TSyncErrorCode): string;
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

constructor TSyncStateInit.Create(ParaHost: ISyncStateHost);
begin
	mHost := ParaHost;
end;

function TSyncStateInit.GetState: TSyncState;
begin
	Result := SyncInit;
end;

procedure TSyncStateInit.Enter;
begin
	// do nothing
end;

procedure TSyncStateInit.Sync;
begin
	mHost.SetState(TSyncStateSyncing.Create(mHost));
end;

procedure TSyncStateInit.Done;
begin
	mHost.SetState(TSyncStateDone.Create(mHost));
end;

procedure TSyncStateInit.Error(ParaReason: TSyncErrorCode);
begin
	mHost.SetState(TSyncStateError.Create(mHost));
end;

procedure TSyncStateInit.Cancel;
begin
	mHost.SetState(TSyncStateCancel.Create(mHost));
end;

{ TSyncStateSyncing }

constructor TSyncStateSyncing.Create(ParaHost: ISyncStateHost);
begin
	mHost := ParaHost;
end;

function TSyncStateSyncing.GetState: TSyncState;
begin
	Result := Syncing;
end;

procedure TSyncStateSyncing.Enter;
begin
	// do nothing
end;

procedure TSyncStateSyncing.Sync;
begin
	// self
	// maybe get taller peers
	mHost.SetState(TSyncStateSyncing.Create(mHost));
end;

procedure TSyncStateSyncing.Done;
begin
	mHost.SetState(TSyncStateDone.Create(mHost));
end;

procedure TSyncStateSyncing.Error(ParaReason: TSyncErrorCode);
begin
	mHost.SetState(TSyncStateError.Create(mHost));
end;

procedure TSyncStateSyncing.Cancel;
begin
	mHost.SetState(TSyncStateCancel.Create(mHost));
end;

{ TSyncStateDone }

constructor TSyncStateDone.Create(ParaHost: ISyncStateHost);
begin
	mHost := ParaHost;
end;

function TSyncStateDone.GetState: TSyncState;
begin
	Result := SyncDone;
end;

procedure TSyncStateDone.Enter;
begin
	// do nothing
end;

procedure TSyncStateDone.Sync;
begin
	mHost.SetState(TSyncStateSyncing.Create(mHost));
end;

procedure TSyncStateDone.Done;
begin
	// self
end;

procedure TSyncStateDone.Error(ParaReason: TSyncErrorCode);
begin
	// cannot happen
end;

procedure TSyncStateDone.Cancel;
begin
	// do nothing
end;

{ TSyncStateError }

constructor TSyncStateError.Create(ParaHost: ISyncStateHost);
begin
	mHost := ParaHost;
end;

function TSyncStateError.GetState: TSyncState;
begin
	Result := SyncError;
end;

procedure TSyncStateError.Enter;
begin
	// do nothing
end;

procedure TSyncStateError.Sync;
begin
	mHost.SetState(TSyncStateSyncing.Create(mHost));
end;

procedure TSyncStateError.Done;
begin
	mHost.SetState(TSyncStateDone.Create(mHost));
end;

procedure TSyncStateError.Error(ParaReason: TSyncErrorCode);
begin
	// self
end;

procedure TSyncStateError.Cancel;
begin
	mHost.SetState(TSyncStateCancel.Create(mHost));
end;

{ TSyncStateCancel }

constructor TSyncStateCancel.Create(ParaHost: ISyncStateHost);
begin
	mHost := ParaHost;
end;

function TSyncStateCancel.GetState: TSyncState;
begin
	Result := SyncCancel;
end;

procedure TSyncStateCancel.Enter;
begin
	// do nothing
end;

procedure TSyncStateCancel.Sync;
begin
	// cannot happen
end;

procedure TSyncStateCancel.Done;
begin
	// cannot happen
end;

procedure TSyncStateCancel.Error(ParaReason: TSyncErrorCode);
begin
	// cannot happen
end;

procedure TSyncStateCancel.Cancel;
begin
	// self
end;

initialization
	errTooShort := Exception.Create('too short');
	errUnknownSyncState := Exception.Create('unknown sync state');

finalization
	errTooShort.Free;
	errUnknownSyncState.Free;

end.
