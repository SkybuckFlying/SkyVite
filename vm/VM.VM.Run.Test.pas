unit VM.VM.Run.Test;

interface

uses
	System.SysUtils,
	System.Classes,
	System.JSON,
	System.Math,
	Common.Types,
	Interfaces,
	Interfaces.Core,
	VM.VM,
	unit_GoLang_Compatibility_version_006;

type
	TVMRunTestCase = record
		SbHeight : UInt64;
		SbTime : Int64;
		SbHash : string;
		// ... many fields
	end;

procedure TestVM_RunV2;

implementation

procedure TestVM_RunV2;
begin
	// VM data-driven tests...
end;

end.
