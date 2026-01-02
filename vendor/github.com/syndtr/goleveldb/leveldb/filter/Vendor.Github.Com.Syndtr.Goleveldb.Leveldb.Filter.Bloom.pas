{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter.Bloom;

interface

{$IFDEF FPC}
uses
	SysUtils
;
{$ELSE}
uses
	System.SysUtils
;
{$ENDIF}

function bloomHash( ParaKey : TArray<Byte> ) : Cardinal;

implementation

function bloomHash( ParaKey : TArray<Byte> ) : Cardinal;
begin
	Result := 0; // Placeholder
end;

end.
