unit Vendor.Github.Com.GoOle.GoOle.Guid;

interface

uses
	System.Classes,
	System.SysUtils;

type
	TGUID = record
	public
		mData1 : Cardinal;
		mData2 : Word;
		mData3 : Word;
		mData4 : array[ 0..7 ] of Byte;

		function String : string;
	end;

function IIDFromString( ParaProgId : string ) : TGUID;
function StringFromIID( ParaIid : TGUID ) : string;

implementation

{ TGUID }

function TGUID.String : string;
begin
	Result := GUIDToString( System.TGUID( Self ) );
end;

function IIDFromString( ParaProgId : string ) : TGUID;
begin
	Result := TGUID( StringToGUID( ParaProgId ) );
end;

function StringFromIID( ParaIid : TGUID ) : string;
begin
	Result := GUIDToString( System.TGUID( ParaIid ) );
end;

end.
