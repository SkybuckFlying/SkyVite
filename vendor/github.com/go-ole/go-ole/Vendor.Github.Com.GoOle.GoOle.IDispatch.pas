unit Vendor.Github.Com.GoOle.GoOle.IDispatch;

interface

uses
	System.Classes,
	System.SysUtils,
	Vendor.Github.Com.GoOle.GoOle.IUnknown,
	Vendor.Github.Com.GoOle.GoOle.Guid;

type
	IDispatch = class( IUnknown )
	public
		function GetIDsOfNames( ParaNames : TArray<string> ) : TArray<Integer>;
		function Invoke( ParaDispid : Integer; ParaDispatch : SmallInt; ParaParams : array of Variant ) : Variant;
	end;

implementation

uses
	Winapi.ActiveX;

function IDispatch.GetIDsOfNames( ParaNames : TArray<string> ) : TArray<Integer>;
begin
	// Wrapper for IDispatch.GetIDsOfNames
	SetLength( Result, Length( ParaNames ) );
end;

function IDispatch.Invoke( ParaDispid : Integer; ParaDispatch : SmallInt; ParaParams : array of Variant ) : Variant;
begin
	// Wrapper for IDispatch.Invoke
end;

end.
