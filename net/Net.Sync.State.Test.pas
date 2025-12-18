unit Net.Sync.State.Test;

interface

uses
	System.SysUtils,
	Net.Sync.State;

procedure ExampleSyncState_MarshalText;
procedure TestSyncState_MarshalText;

implementation

procedure ExampleSyncState_MarshalText;
var
	vS : TSyncState;
begin
	vS := SyncInit;
	Writeln( SyncStateToString( vS ) );
	// Output: Sync Not Start
end;

procedure TestSyncState_MarshalText;
var
	vS : TSyncState;
	vStr : string;
begin
	vS := Syncing;
	vStr := SyncStateToString( vS );
	
	// mock unmarshal
	if vStr <> 'Synchronising' then raise Exception.Create( 'wrong state string' );
end;

end.
