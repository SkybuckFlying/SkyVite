unit Vendor.Github.Com.Stretchr.Testify.Require.Require;

interface

uses
  System.Rtti,
  System.SysUtils,
  Vendor.Github.Com.Stretchr.Testify.Assert.AssertionCompare,
  Vendor.Github.Com.Stretchr.Testify.Assert.AssertionFormat,
  Vendor.Github.Com.Stretchr.Testify.Assert.AssertionForward,
  Vendor.Github.Com.Stretchr.Testify.Assert.AssertionOrder,
  Vendor.Github.Com.Stretchr.Testify.Assert.Assertions,
  Vendor.Github.Com.Stretchr.Testify.Assert.Doc,
  Vendor.Github.Com.Stretchr.Testify.Assert.Errors,
  Vendor.Github.Com.Stretchr.Testify.Assert.ForwardAssertions,
  Vendor.Github.Com.Stretchr.Testify.Assert.HttpAssertions,
  Vendor.Github.Com.Stretchr.Testify.Require.Doc,
  Vendor.Github.Com.Stretchr.Testify.Require.ForwardRequirements,
  Vendor.Github.Com.Stretchr.Testify.Require.RequireForward,
  Vendor.Github.Com.Stretchr.Testify.Require.Requirements;

type
	ERequireError = class( Exception );

procedure Equal( const ParaT : ITestingT; const ParaExpected, ParaActual : TValue; const ParaMsgAndArgs : array of const );
procedure NotEqual( const ParaT : ITestingT; const ParaExpected, ParaActual : TValue; const ParaMsgAndArgs : array of const );
procedure IsNil( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const );
procedure NotNil( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const );
procedure IsTrue( const ParaT : ITestingT; const ParaValue : Boolean; const ParaMsgAndArgs : array of const );
procedure IsFalse( const ParaT : ITestingT; const ParaValue : Boolean; const ParaMsgAndArgs : array of const );
procedure Empty( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const );
procedure NotEmpty( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const );

implementation

procedure FailNow;
begin
	raise ERequireError.Create( 'Requirement failed' );
end;

procedure Equal( const ParaT : ITestingT; const ParaExpected, ParaActual : TValue; const ParaMsgAndArgs : array of const );
begin
	if not Vendor.Github.Com.Stretchr.Testify.Assert.Assertions.Equal( ParaT, ParaExpected, ParaActual, ParaMsgAndArgs ) then
		FailNow;
end;

procedure NotEqual( const ParaT : ITestingT; const ParaExpected, ParaActual : TValue; const ParaMsgAndArgs : array of const );
begin
	if not Vendor.Github.Com.Stretchr.Testify.Assert.Assertions.NotEqual( ParaT, ParaExpected, ParaActual, ParaMsgAndArgs ) then
		FailNow;
end;

procedure IsNil( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const );
begin
	if not Vendor.Github.Com.Stretchr.Testify.Assert.Assertions.IsNil( ParaT, ParaObject, ParaMsgAndArgs ) then
		FailNow;
end;

procedure NotNil( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const );
begin
	if not Vendor.Github.Com.Stretchr.Testify.Assert.Assertions.NotNil( ParaT, ParaObject, ParaMsgAndArgs ) then
		FailNow;
end;

procedure IsTrue( const ParaT : ITestingT; const ParaValue : Boolean; const ParaMsgAndArgs : array of const );
begin
	if not Vendor.Github.Com.Stretchr.Testify.Assert.Assertions.IsTrue( ParaT, ParaValue, ParaMsgAndArgs ) then
		FailNow;
end;

procedure IsFalse( const ParaT : ITestingT; const ParaValue : Boolean; const ParaMsgAndArgs : array of const );
begin
	if not Vendor.Github.Com.Stretchr.Testify.Assert.Assertions.IsFalse( ParaT, ParaValue, ParaMsgAndArgs ) then
		FailNow;
end;

procedure Empty( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const );
begin
	if not Vendor.Github.Com.Stretchr.Testify.Assert.Assertions.Empty( ParaT, ParaObject, ParaMsgAndArgs ) then
		FailNow;
end;

procedure NotEmpty( const ParaT : ITestingT; const ParaObject : TValue; const ParaMsgAndArgs : array of const );
begin
	if not Vendor.Github.Com.Stretchr.Testify.Assert.Assertions.NotEmpty( ParaT, ParaObject, ParaMsgAndArgs ) then
		FailNow;
end;

end.
