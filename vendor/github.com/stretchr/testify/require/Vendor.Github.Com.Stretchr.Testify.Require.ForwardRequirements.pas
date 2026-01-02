{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Stretchr.Testify.Require.ForwardRequirements;

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
	TRequirements = class
	private
		mT : ITestingT;
	public
		constructor Create( ParaT : ITestingT );
		procedure Equal( ParaExpected, ParaActual : TValue; ParaMsg : string = '' );
	end;

implementation

constructor TRequirements.Create( ParaT : ITestingT );
begin
	inherited Create;
	mT := ParaT;
end;

procedure TRequirements.Equal( ParaExpected, ParaActual : TValue; ParaMsg : string = '' );
begin
end;

end.
