unit Vendor.Github.Com.Allegro.BigCache.Utils;

interface

function Max( ParaA, ParaB : Integer ) : Integer;
function ConvertMBToBytes( ParaValue : Integer ) : Integer;
function IsPowerOfTwo( ParaNumber : Integer ) : Boolean;

implementation

function Max( ParaA, ParaB : Integer ) : Integer;
begin
	if ParaA > ParaB then
	begin
		Result := ParaA;
	end else
	begin
		Result := ParaB;
	end;
end;

function ConvertMBToBytes( ParaValue : Integer ) : Integer;
begin
	Result := ParaValue * 1024 * 1024;
end;

function IsPowerOfTwo( ParaNumber : Integer ) : Boolean;
begin
	Result := ( ParaNumber > 0 ) and ( ( ParaNumber and ( ParaNumber - 1 ) ) = 0 );
end;

end.
