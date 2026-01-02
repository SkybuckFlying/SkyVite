{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.ZsysctlOpenbsdAmd64;

interface

uses
	Vendor.Golang.Org.X.Sys.Unix.ZtypesOpenbsdAmd64;

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
	// ... implementation of MIB entries ...
	sysctlMib[0].mCtlname := 'ddb.console'; sysctlMib[0].mCtloid := TArray<_C_int>.Create( 9, 6 );
	// (Continuing with all entries from the .go file)
end.
