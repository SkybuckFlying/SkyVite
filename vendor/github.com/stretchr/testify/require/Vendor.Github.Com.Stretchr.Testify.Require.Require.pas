unit Vendor.Github.Com.Stretchr.Testify.Require.Require;

interface

uses
	System.SysUtils,
	System.Rtti,
	Vendor.Github.Com.Stretchr.Testify.Assert.Assertions;

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
