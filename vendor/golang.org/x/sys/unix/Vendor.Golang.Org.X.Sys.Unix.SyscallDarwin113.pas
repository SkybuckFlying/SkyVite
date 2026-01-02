{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallDarwin113;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesDarwin;

function Getdirentries( ParaFd : Integer; ParaBuf : TArray<Byte>; ParaBasep : PUintPtr; out ParaErr : Integer ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallDarwin,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

function Getdirentries( ParaFd : Integer; ParaBuf : TArray<Byte>; ParaBasep : PUintPtr; out ParaErr : Integer ) : Integer;
var
	vSkip : Int64;
	vFd2 : Integer;
	vD : UIntPtr;
	vCnt : Int64;
	vEntry : TDirent;
	vEntryp : PDirent;
	vE : Integer;
	vReclen : Integer;
	vN : Integer;
	vCurrentBuf : TArray<Byte>;
begin
	vN := 0;
	vSkip := Seek( ParaFd, 0, 1, ParaErr );
	if ParaErr <> 0 then
	begin
		Result := 0;
		Exit;
	end;

	vFd2 := Openat( ParaFd, '.', O_RDONLY, 0, ParaErr );
	if ParaErr <> 0 then
	begin
		Result := 0;
		Exit;
	end;

	vD := fdopendir( vFd2, ParaErr );
	if ParaErr <> 0 then
	begin
		Close( vFd2 );
		Result := 0;
		Exit;
	end;

	try
		vCnt := 0;
		vCurrentBuf := ParaBuf;
		while True do
		begin
			vEntryp := nil;
			vE := readdir_r( vD, @vEntry, @vEntryp );
			if vE <> 0 then
			begin
				ParaErr := vE;
				Result := vN;
				Exit;
			end;
			if vEntryp = nil then
			begin
				Break;
			end;
			if vSkip > 0 then
			begin
				vSkip := vSkip - 1;
				vCnt := vCnt + 1;
				continue;
			end;

			vReclen := Integer( vEntry.Reclen );
			if vReclen > Length( vCurrentBuf ) then
			begin
				Break;
			end;

			// Copy entry into return buffer.
			Move( vEntry, vCurrentBuf[0], vReclen );

			// Slice vCurrentBuf
			if vReclen < Length( vCurrentBuf ) then
			begin
				vCurrentBuf := Copy( vCurrentBuf, vReclen, Length( vCurrentBuf ) - vReclen );
			end else
			begin
				vCurrentBuf := nil;
			end;
			
			vN := vN + vReclen;
			vCnt := vCnt + 1;
		end;

		Seek( ParaFd, vCnt, 0, ParaErr );
		Result := vN;
	finally
		closedir( vD );
	end;
end;

end.
