unit Vendor.Github.Com.Shirou.Gopsutil.Host.Types;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Generics.Collections;

type
	TWarnings = class( TInterfacedObject, IInterface )
	private
		mList : TList<Exception>;
	public
		constructor Create;
		destructor Destroy; override;
		procedure Add( ParaErr : Exception );
		function Reference : Exception;
		function Error : string;
	end;

implementation

{ TWarnings }

constructor TWarnings.Create;
begin
	inherited Create;
	mList := TList<Exception>.Create;
end;

destructor TWarnings.Destroy;
begin
	mList.Free;
	inherited;
end;

procedure TWarnings.Add( ParaErr : Exception );
begin
	mList.Add( ParaErr );
end;

function TWarnings.Reference : Exception;
begin
	if mList.Count > 0 then
		Result := Exception( Self ) // In Go, it returns itself as error
	else
		Result := nil;
end;

function TWarnings.Error : string;
begin
	Result := Format( 'Number of warnings: %v', [ mList.Count ] );
end;

end.
