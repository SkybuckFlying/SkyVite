unit Vendor.Github.Com.GoOle.GoOle.Error;

interface

uses
	System.Classes,
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.Ole;

type
	TOleError = class( Exception )
	private
		mCode      : Cardinal;
		mSubError : string;
		mExcepInfo : TEXCEPINFO;
	public
		constructor Create( ParaCode : Cardinal );
		constructor CreateWithSubError( ParaCode : Cardinal; ParaSubError : string; const ParaExcepInfo : TEXCEPINFO );

		property Code : Cardinal read mCode;
	end;

implementation

constructor TOleError.Create( ParaCode : Cardinal );
begin
	inherited Create( 'Ole Error: ' + IntToHex( ParaCode, 8 ) );
	mCode := ParaCode;
end;

constructor TOleError.CreateWithSubError( ParaCode : Cardinal; ParaSubError : string; const ParaExcepInfo : TEXCEPINFO );
begin
	inherited Create( ParaSubError );
	mCode := ParaCode;
	mSubError := ParaSubError;
	mExcepInfo := ParaExcepInfo;
end;

end.
