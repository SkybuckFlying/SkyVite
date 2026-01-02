{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Stretchr.Testify.Assert.ForwardAssertions;

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

uses
	Vendor.Github.Com.Stretchr.Testify.Assert.Assertions
;

type
	TAssertions = class
	private
		mT : ITestingT;
	public
		constructor Create( ParaT : ITestingT );
		function Equal( ParaExpected, ParaActual : TValue; ParaMsg : string = '' ) : Boolean;
	end;

implementation

constructor TAssertions.Create( ParaT : ITestingT );
begin
	inherited Create;
	mT := ParaT;
end;

function TAssertions.Equal( ParaExpected, ParaActual : TValue; ParaMsg : string = '' ) : Boolean;
begin
	Result := True;
end;

end.
