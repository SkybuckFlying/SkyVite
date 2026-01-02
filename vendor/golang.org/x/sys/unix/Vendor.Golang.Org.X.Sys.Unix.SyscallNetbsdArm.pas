{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallNetbsdArm;

interface

uses
	Vendor.Golang.Org.X.Sys.Unix.ZtypesNetbsd;

implementation

function SetTimespec( ParaSec : Int64; ParaNsec : Int64 ) : TTimespec;
begin
	Result.Sec := ParaSec;
	Result.Nsec := Int32( ParaNsec );
end;

function SetTimeval( ParaSec : Int64; ParaUsec : Int64 ) : TTimeval;
begin
	Result.Sec := ParaSec;
	Result.Usec := Int32( ParaUsec );
end;

procedure SetKevent( ParaK : PZKevent_t; ParaFd : Integer; ParaMode : Integer; ParaFlags : Integer );
begin
	ParaK.Ident := UInt32( ParaFd );
	ParaK.Filter := UInt32( ParaMode );
	ParaK.Flags := UInt32( ParaFlags );
end;

type
	TIovecHelper = record helper for TIovec
		procedure SetLen( ParaLength : Integer );
	end;

	TMsghdrHelper = record helper for TMsghdr
		procedure SetControllen( ParaLength : Integer );
		procedure SetIovlen( ParaLength : Integer );
	end;

	TCmsghdrHelper = record helper for TCmsghdr
		procedure SetLen( ParaLength : Integer );
	end;

procedure TIovecHelper.SetLen( ParaLength : Integer );
begin
	Self.Len := UInt32( ParaLength );
end;

procedure TMsghdrHelper.SetControllen( ParaLength : Integer );
begin
	Self.Controllen := UInt32( ParaLength );
end;

procedure TMsghdrHelper.SetIovlen( ParaLength : Integer );
begin
	Self.Iovlen := Int32( ParaLength );
end;

procedure TCmsghdrHelper.SetLen( ParaLength : Integer );
begin
	Self.Len := UInt32( ParaLength );
end;

end.
