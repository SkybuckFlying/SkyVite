{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Stretchr.Testify.Require.RequireForward;

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
	Vendor.Github.Com.Stretchr.Testify.Require.Requirements
;

type
	TRequireForward = class
	private
		mT : ITestingT;
	public
		constructor Create( ParaT : ITestingT );
		procedure Equal( ParaExpected, ParaActual : TValue; ParaMsg : string = '' );
	end;

implementation

constructor TRequireForward.Create( ParaT : ITestingT );
begin
	inherited Create;
	mT := ParaT;
end;

procedure TRequireForward.Equal( ParaExpected, ParaActual : TValue; ParaMsg : string = '' );
begin
end;

end.
