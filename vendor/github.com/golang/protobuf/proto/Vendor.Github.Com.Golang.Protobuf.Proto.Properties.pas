unit Vendor.Github.Com.Golang.Protobuf.Proto.Properties;

interface

uses
	System.Classes,
	System.SysUtils;

type
	TProperties = class
	public
		mName     : string;
		mOrigName : string;
		mTag      : Integer;
		mWire     : string;
		mWireType : Integer;
		mRequired : Boolean;
		mOptional : Boolean;
		mRepeated : Boolean;
		mPacked   : Boolean;

		procedure Parse( ParaTag : string );
	end;

	TStructProperties = class
	public
		mProp : TList<TProperties>;
		constructor Create;
		destructor Destroy; override;
	end;

implementation

uses
	System.Generics.Collections;

{ TProperties }

procedure TProperties.Parse( ParaTag : string );
begin
end;

{ TStructProperties }

constructor TStructProperties.Create;
begin
	inherited Create;
	mProp := TList<TProperties>.Create;
end;

destructor TStructProperties.Destroy;
begin
	mProp.Free;
	inherited;
end;

end.
