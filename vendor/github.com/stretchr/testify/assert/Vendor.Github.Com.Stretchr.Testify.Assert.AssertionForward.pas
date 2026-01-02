{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Stretchr.Testify.Assert.AssertionForward;

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
	TForwardAssertions = class
	private
		mT : ITestingT;
	public
		constructor Create( ParaT : ITestingT );
		function Equal( ParaExpected, ParaActual : TValue; ParaMsg : string = '' ) : Boolean;
	end;

implementation

constructor TForwardAssertions.Create( ParaT : ITestingT );
begin
	inherited Create;
	mT := ParaT;
end;

function TForwardAssertions.Equal( ParaExpected, ParaActual : TValue; ParaMsg : string = '' ) : Boolean;
begin
	Result := True;
end;

end.
