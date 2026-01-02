{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Stretchr.Testify.Assert.AssertionCompare;

interface

{$IFDEF FPC}
uses
	SysUtils, Rtti
;
{$ELSE}
uses
	System.SysUtils, System.Rtti
;
{$ENDIF}

type
	TCompareType = ( ctLess, ctEqual, ctGreater );

function compare( ParaObj1, ParaObj2 : TValue ) : TCompareType;

implementation

function compare( ParaObj1, ParaObj2 : TValue ) : TCompareType;
begin
	Result := ctEqual;
end;

end.
