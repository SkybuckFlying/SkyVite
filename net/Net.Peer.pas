unit Peer;

interface

uses
	System.SysUtils,
	System.Classes,
	GoToDelphi.Helpers.Net,
	VNode,
	NetTool;

function ExtractAddress(
	ParaSender: ITCPAddr;
	ParaFileAddressBytes: TBytes;
	ParaDefaultPort: Integer
): string;

implementation

uses
	System.NetEncoding;

function ExtractAddress(
	ParaSender: ITCPAddr;
	ParaFileAddressBytes: TBytes;
	ParaDefaultPort: Integer
): string;
var
	vFromIP: IIP;
	vPort: Word;
	vEndPoint: TEndPoint;
	vIP: TIPAddress;
begin
	vFromIP := ParaSender.IP;

	if Length(ParaFileAddressBytes) = 2 then
	begin
		vPort := ParaFileAddressBytes[1] or (ParaFileAddressBytes[0] shl 8);
		Result := vFromIP.ToString + ':' + IntToStr(vPort);
		Exit;
	end;

	if Length(ParaFileAddressBytes) > 2 then
	begin
		if vEndPoint.Deserialize(ParaFileAddressBytes) then
		begin
			if vEndPoint.mTyp in [htIP, htIPv4, htIPv6] then
			begin
				vIP.AsBytes := vEndPoint.mHost;
				// Assuming TNetTool.CheckRelayIP exists
				if TNetTool.CheckRelayIP(vFromIP, vIP) then
				begin
					vEndPoint.mHost := vFromIP.AsBytes;
				end;
				Result := vEndPoint.ToString;
				Exit;
			end
			else
			begin
				// Assuming a function to resolve TCP address exists
				// For now, just return the endpoint string
				Result := vEndPoint.ToString;
				Exit;
			end;
		end;
	end;

	Result := vFromIP.ToString + ':' + IntToStr(ParaDefaultPort);
end;

end.