unit Vendor.Github.Com.Davecgh.GoSpew.Spew.Config;

interface

uses
	System.Classes,
	System.SysUtils;

type
	TConfigState = record
	public
		mIndent                  : string;
		mMaxDepth                : Integer;
		mDisableMethods          : Boolean;
		mDisablePointerMethods   : Boolean;
		mDisablePointerAddresses : Boolean;
		mDisableCapacities       : Boolean;
		mContinueOnMethod        : Boolean;
		mSortKeys                : Boolean;
		mSpewKeys                : Boolean;

		// Methods would be added here in spew.pas or as extensions
	end;

var
	Config : TConfigState;

function NewDefaultConfig : TConfigState;

implementation

function NewDefaultConfig : TConfigState;
begin
	Result.mIndent := ' ';
	Result.mMaxDepth := 0;
	Result.mDisableMethods := False;
	Result.mDisablePointerMethods := False;
	Result.mContinueOnMethod := False;
	Result.mSortKeys := False;
end;

initialization
	Config := NewDefaultConfig;

end.
