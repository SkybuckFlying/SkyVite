unit Net.Discovery.Discovery.Test;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Threading,
	System.TimeSpan,
	Net.Vnode,
	unit_GoLang_Compatibility_version_006;

procedure TestFindNode;
procedure TestTimer;
procedure Test_splitEndPoints;

implementation

procedure TestFindNode;
begin
	// structure for node lookup test
end;

procedure TestTimer;
var
	vStart : Int64;
begin
	vStart := DateTimeToUnix( Now );
	TThread.Sleep( 1000 );
	if DateTimeToUnix( Now ) - vStart < 1 then raise Exception.Create( 'timer error' );
end;

procedure Test_splitEndPoints;
begin
	// endpoint splitting test
end;

end.
