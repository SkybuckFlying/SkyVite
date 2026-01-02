{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Stretchr.Testify.Require.Requirements;

interface

type
	ITestingT = interface
		procedure Errorf( const ParaFormat : string; const ParaArgs : array of const );
		procedure FailNow;
	end;

implementation

end.
