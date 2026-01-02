{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.ZsysctlOpenbsdArm64;

interface

uses
	Vendor.Golang.Org.X.Sys.Unix.ZtypesOpenbsdArm64;

type
	Tmibentry = record
		mCtlname : string;
		mCtloid : TArray<_C_int>;
	end;

var
	sysctlMib : TArray<Tmibentry>;

implementation

initialization
	SetLength( sysctlMib, 145 );
	sysctlMib[0].mCtlname := 'ddb.console'; sysctlMib[0].mCtloid := TArray<_C_int>.Create( 9, 6 );
	// ... implementation of MIB entries ...
end.
