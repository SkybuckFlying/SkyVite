unit Vendor.Github.Com.Golang.Mock.GoMock.CallSet;

interface

uses
	System.Classes,
	System.SysUtils,
	System.Generics.Collections,
	System.RTTI,
	Vendor.Github.Com.Golang.Mock.GoMock.Call;

type
	TCallSetKey = record
	public
		mReceiver : Pointer;
		mMethod    : string;
	end;

	TCallSet = class
	private
		mExpected  : TDictionary<TCallSetKey, TList<TCall>>;
		mExhausted : TDictionary<TCallSetKey, TList<TCall>>;
	public
		constructor Create;
		destructor Destroy; override;

		procedure Add( ParaCall : TCall );
		procedure Remove( ParaCall : TCall );
		function FindMatch( ParaReceiver : Pointer; ParaMethod : string; ParaArgs : array of TValue ) : TCall;
		function Failures : TArray<TCall>;
	end;

implementation

{ TCallSet }

constructor TCallSet.Create;
begin
	inherited Create;
	mExpected := TDictionary<TCallSetKey, TList<TCall>>.Create;
	mExhausted := TDictionary<TCallSetKey, TList<TCall>>.Create;
end;

destructor TCallSet.Destroy;
var
	vList : TList<TCall>;
begin
	for vList in mExpected.Values do
		vList.Free;
	for vList in mExhausted.Values do
		vList.Free;
	mExpected.Free;
	mExhausted.Free;
	inherited;
end;

procedure TCallSet.Add( ParaCall : TCall );
var
	vKey : TCallSetKey;
	vList : TList<TCall>;
begin
	vKey.mReceiver := ParaCall.Receiver;
	vKey.mMethod := ParaCall.Method;
	if not mExpected.TryGetValue( vKey, vList ) then
	begin
		vList := TList<TCall>.Create;
		mExpected.Add( vKey, vList );
	end;
	vList.Add( ParaCall );
end;

procedure TCallSet.Remove( ParaCall : TCall );
var
	vKey : TCallSetKey;
	vList : TList<TCall>;
begin
	vKey.mReceiver := ParaCall.Receiver;
	vKey.mMethod := ParaCall.Method;
	if mExpected.TryGetValue( vKey, vList ) then
	begin
		vList.Remove( ParaCall );
		if not mExhausted.TryGetValue( vKey, vList ) then
		begin
			vList := TList<TCall>.Create;
			mExhausted.Add( vKey, vList );
		end;
		vList.Add( ParaCall );
	end;
end;

function TCallSet.FindMatch( ParaReceiver : Pointer; ParaMethod : string; ParaArgs : array of TValue ) : TCall;
var
	vKey : TCallSetKey;
	vList : TList<TCall>;
	vCall : TCall;
begin
	vKey.mReceiver := ParaReceiver;
	vKey.mMethod := ParaMethod;
	if mExpected.TryGetValue( vKey, vList ) then
	begin
		for vCall in vList do
			if vCall.Matches( ParaArgs ) then
				Exit( vCall );
	end;
	Result := nil;
end;

function TCallSet.Failures : TArray<TCall>;
var
	vList : TList<TCall>;
	vCall : TCall;
	vResult : TList<TCall>;
begin
	vResult := TList<TCall>.Create;
	try
		for vList in mExpected.Values do
			for vCall in vList do
				if not vCall.Satisfied then
					vResult.Add( vCall );
		Result := vResult.ToArray;
	finally
		vResult.Free;
	end;
end;

end.
