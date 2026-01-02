{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Stretchr.Testify.Assert.Errors;

interface

uses
	System.SysUtils
;

var
	AnError : Exception;

implementation

initialization
	AnError := Exception.Create( 'assert.AnError general error for testing' );
finalization
	AnError.Free;

end.
