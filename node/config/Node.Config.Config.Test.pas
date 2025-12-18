unit Node.Config.Config.Test;

interface

uses
	System.SysUtils,
	System.Classes,
	System.JSON,
	Common.Types,
	Common.Config.Config,
	Node.Config.Config;

procedure TestChainConfig;
procedure TestDeferReturn;

implementation

procedure TestChainConfig;
var
	vConfigJsonA : string;
	vConfig : TNodeConfig;
	vChainConfig : TChainConfig;
begin
	vConfigJsonA := '{"VmLogWhiteList":["vite_d789431f1d820506c83fd539a0ae9863d6961382f67341a8b5"]}';
	vConfig := TNodeConfig.Create;
	try
		// mock json unmarshal
		vConfig.VmLogWhiteList := [TAddress.FromString( 'vite_d789431f1d820506c83fd539a0ae9863d6961382f67341a8b5' )];
		
		vChainConfig := vConfig.MakeChainConfig;
		try
			if Length( vChainConfig.VmLogWhiteList ) <> 1 then raise Exception.Create( 'length must be 1' );
		finally
			vChainConfig.Free;
		end;
	finally
		vConfig.Free;
	end;
end;

procedure TestDeferReturn;
begin
end;

end.
