{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallSolarisAmd64;

interface

uses
	Vendor.Golang.Org.X.Sys.Unix.ZtypesSolaris;

implementation

function SetTimespec( ParaSec : Int64; ParaNsec : Int64 ) : TTimespec;
begin
	Result.Sec := ParaSec;
	Result.Nsec := ParaNsec;
end;

function SetTimeval( ParaSec : Int64; ParaUsec : Int64 ) : TTimeval;
begin
	Result.Sec := ParaSec;
	Result.Usec := ParaUsec;
end;

type
	TIovecHelper = record helper for TIovec
		procedure SetLen( ParaLength : Integer );
	end;

	TMsghdrHelper = record helper for TMsghdr
		procedure SetIovlen( ParaLength : Integer );
	end;

	TCmsghdrHelper = record helper for TCmsghdr
		procedure SetLen( ParaLength : Integer );
	end;

procedure TIovecHelper.SetLen( ParaLength : Integer );
begin
	Self.Len := uint64( ParaLength );
end;

procedure TMsghdrHelper.SetIovlen( ParaLength : Integer );
begin
	Self.Iovlen := int32( ParaLength );
end;

procedure TCmsghdrHelper.SetLen( ParaLength : Integer );
begin
	Self.Len := uint32( ParaLength );
end;

end.
