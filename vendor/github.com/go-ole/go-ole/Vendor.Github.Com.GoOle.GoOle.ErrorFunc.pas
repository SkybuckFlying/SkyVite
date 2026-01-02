{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.ErrorFunc;

interface

function errstr( ParaErrno : Integer ) : string;

implementation

// errstr converts error code to string.
function errstr( ParaErrno : Integer ) : string;
begin
	Result := '';
end;

end.
