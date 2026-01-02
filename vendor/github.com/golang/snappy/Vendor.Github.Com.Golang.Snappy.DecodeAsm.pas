{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Golang.Snappy.DecodeAsm;

interface

// Internal decode function
function decode( ParaDst, ParaSrc : TArray<Byte> ) : Integer;

implementation

function decode( ParaDst, ParaSrc : TArray<Byte> ) : Integer;
begin
	// Assembly implementation would go here or call external lib
	Result := -1;
end;

end.
