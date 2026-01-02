{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.Timestruct;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesUnix;

function TimespecToNsec( ParaTs : TTimespec ) : Int64;
function NsecToTimespec( ParaNsec : Int64 ) : TTimespec;
function TimevalToNsec( ParaTv : TTimeval ) : Int64;
function NsecToTimeval( ParaNsec : Int64 ) : TTimeval;

type
	TTimespecHelper = record helper for TTimespec
		function Unix( out ParaSec : Int64; out ParaNsec : Int64 ) : Integer;
		function Nano : Int64;
	end;

	TTimevalHelper = record helper for TTimeval
		function Unix( out ParaSec : Int64; out ParaNsec : Int64 ) : Integer;
		function Nano : Int64;
	end;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

function TimespecToNsec( ParaTs : TTimespec ) : Int64;
begin
	Result := ParaTs.Nano;
end;

function NsecToTimespec( ParaNsec : Int64 ) : TTimespec;
var
	vSec : Int64;
	vNsec : Int64;
begin
	vSec := ParaNsec div 1000000000;
	vNsec := ParaNsec mod 1000000000;
	if vNsec < 0 then
	begin
		vNsec := vNsec + 1000000000;
		vSec := vSec - 1;
	end;
	// setTimespec needs to be defined per platform
	Result.Sec := vSec;
	Result.Nsec := vNsec;
end;

function TimevalToNsec( ParaTv : TTimeval ) : Int64;
begin
	Result := ParaTv.Nano;
end;

function NsecToTimeval( ParaNsec : Int64 ) : TTimeval;
var
	vNsec : Int64;
	vSec : Int64;
	vUsec : Int64;
begin
	vNsec := ParaNsec + 999;
	vUsec := ( vNsec mod 1000000000 ) div 1000;
	vSec := vNsec div 1000000000;
	if vUsec < 0 then
	begin
		vUsec := vUsec + 1000000;
		vSec := vSec - 1;
	end;
	// setTimeval needs to be defined per platform
	Result.Sec := vSec;
	Result.Usec := vUsec;
end;

function TTimespecHelper.Unix( out ParaSec : Int64; out ParaNsec : Int64 ) : Integer;
begin
	ParaSec := Int64( Self.Sec );
	ParaNsec := Int64( Self.Nsec );
	Result := 0;
end;

function TTimevalHelper.Unix( out ParaSec : Int64; out ParaNsec : Int64 ) : Integer;
begin
	ParaSec := Int64( Self.Sec );
	ParaNsec := Int64( Self.Usec ) * 1000;
	Result := 0;
end;

function TTimespecHelper.Nano : Int64;
begin
	Result := Int64( Self.Sec ) * 1000000000 + Int64( Self.Nsec );
end;

function TTimevalHelper.Nano : Int64;
begin
	Result := Int64( Self.Sec ) * 1000000000 + Int64( Self.Usec ) * 1000;
end;

end.
