{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Stretchr.Testify.Assert.HttpAssertions;

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

function HTTPSuccess( ParaT : ITestingT; ParaHandler : TValue; ParaMethod, ParaUrl : string; ParaValues : TValue; ParaMsg : string = '' ) : Boolean;
function HTTPRedirect( ParaT : ITestingT; ParaHandler : TValue; ParaMethod, ParaUrl : string; ParaValues : TValue; ParaMsg : string = '' ) : Boolean;
function HTTPError( ParaT : ITestingT; ParaHandler : TValue; ParaMethod, ParaUrl : string; ParaValues : TValue; ParaMsg : string = '' ) : Boolean;
function HTTPStatusCode( ParaT : ITestingT; ParaHandler : TValue; ParaMethod, ParaUrl : string; ParaValues : TValue; ParaStatusCode : Integer; ParaMsg : string = '' ) : Boolean;
function HTTPBodyContains( ParaT : ITestingT; ParaHandler : TValue; ParaMethod, ParaUrl : string; ParaValues : TValue; ParaStr : TValue; ParaMsg : string = '' ) : Boolean;
function HTTPBodyNotContains( ParaT : ITestingT; ParaHandler : TValue; ParaMethod, ParaUrl : string; ParaValues : TValue; ParaStr : TValue; ParaMsg : string = '' ) : Boolean;

implementation

function HTTPSuccess( ParaT : ITestingT; ParaHandler : TValue; ParaMethod, ParaUrl : string; ParaValues : TValue; ParaMsg : string = '' ) : Boolean;
begin
	Result := True;
end;

function HTTPRedirect( ParaT : ITestingT; ParaHandler : TValue; ParaMethod, ParaUrl : string; ParaValues : TValue; ParaMsg : string = '' ) : Boolean;
begin
	Result := True;
end;

function HTTPError( ParaT : ITestingT; ParaHandler : TValue; ParaMethod, ParaUrl : string; ParaValues : TValue; ParaMsg : string = '' ) : Boolean;
begin
	Result := True;
end;

function HTTPStatusCode( ParaT : ITestingT; ParaHandler : TValue; ParaMethod, ParaUrl : string; ParaValues : TValue; ParaStatusCode : Integer; ParaMsg : string = '' ) : Boolean;
begin
	Result := True;
end;

function HTTPBodyContains( ParaT : ITestingT; ParaHandler : TValue; ParaMethod, ParaUrl : string; ParaValues : TValue; ParaStr : TValue; ParaMsg : string = '' ) : Boolean;
begin
	Result := True;
end;

function HTTPBodyNotContains( ParaT : ITestingT; ParaHandler : TValue; ParaMethod, ParaUrl : string; ParaValues : TValue; ParaStr : TValue; ParaMsg : string = '' ) : Boolean;
begin
	Result := True;
end;

end.
