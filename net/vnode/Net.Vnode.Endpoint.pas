unit Net.VNode.EndPoint;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Net.IP,
  System.StrUtils,
  System.Net.Socket;

const
  Loopback = 'localhost';
  DefaultPort = 23456;
  MaxHostLength = 63;
  PortLength = 2;

var
  LoopbackIP: TBytes;
  errInvalidHost: Exception;
  errMissHost: Exception;
  errUnmatchedLength: Exception;

type
  THostType = (HostIP, HostDomain, HostIPv4, HostIPv6);

  TEndPoint = record
  public
    Host: TBytes;
    Port: Integer;
    Typ: THostType;

    function UnmarshalJSON(const ParaData: TBytes): Boolean;
    function MarshalJSON: TBytes;
    function MarshalText: TBytes;
    function UnmarshalText(const ParaText: TBytes): Boolean;
    function Equal(const ParaE2: TEndPoint): Boolean;
    function Serialize: TBytes;
    function Deserialize(const ParaBuf: TBytes): Boolean;
    function Length: Integer;
    function ToString: string;
    function Hostname: string;
    class function Parse(const ParaHost: string): TEndPoint;
  end;

implementation

uses
  System.JSON;

{ TEndPoint }

function TEndPoint.UnmarshalJSON(const ParaData: TBytes): Boolean;
begin
  Result := UnmarshalText(ParaData);
end;

function TEndPoint.MarshalJSON: TBytes;
begin
  Result := MarshalText;
end;

function TEndPoint.MarshalText: TBytes;
begin
  Result := TEncoding.UTF8.GetBytes('"' + ToString + '"');
end;

function TEndPoint.UnmarshalText(const ParaText: TBytes): Boolean;
var
  vStr: string;
  vEndPoint: TEndPoint;
begin
  Result := False;
  if Length(ParaText) < 2 then
    Exit;
  vStr := TEncoding.UTF8.GetString(ParaText, 1, Length(ParaText) - 2);
  try
    vEndPoint := TEndPoint.Parse(vStr);
    Self := vEndPoint;
    Result := True;
  except
    Result := False;
  end;
end;

function TEndPoint.Equal(const ParaE2: TEndPoint): Boolean;
begin
  Result := (Port = ParaE2.Port) and (Typ = ParaE2.Typ) and (CompareMem(Host, ParaE2.Host, Length(Host)));
end;

function TEndPoint.Serialize: TBytes;
var
  vHLen: Integer;
begin
  vHLen := System.Length(Host);
  if vHLen = 0 then
    raise errMissHost;
  if vHLen > MaxHostLength then
    raise errInvalidHost;

  SetLength(Result, Self.Length);
  Result[0] := Byte(vHLen) shl 2;

  if (Typ = HostDomain) or (System.Length(Host) > 16) then
    Result[0] := Result[0] or 2;

  if Port <> DefaultPort then
  begin
    Result[0] := Result[0] or 1;
    Result[System.Length(Result) - 1] := Byte(Port);
    Result[System.Length(Result) - 2] := Byte(Port shr 8);
  end;

  System.Move(Host[0], Result[1], vHLen);
end;

function TEndPoint.Deserialize(const ParaBuf: TBytes): Boolean;
var
  vHLen, vShouldLength: Integer;
  vHasPort: Boolean;
begin
  Result := False;
  if System.Length(ParaBuf) = 0 then
    raise errInvalidHost;

  vHLen := ParaBuf[0] shr 2;
  if vHLen = 0 then
    raise errMissHost;

  vShouldLength := vHLen + 1;
  vHasPort := (ParaBuf[0] and 1) > 0;
  if vHasPort then
    vShouldLength := vShouldLength + PortLength;

  if System.Length(ParaBuf) < vShouldLength then
    raise errUnmatchedLength;

  SetLength(Host, vHLen);
  System.Move(ParaBuf[1], Host[0], vHLen);

  if (ParaBuf[0] and 2) > 0 then
  begin
    Typ := HostDomain;
    if TEncoding.UTF8.GetString(Host) = Loopback then
    begin
      Host := LoopbackIP;
      Typ := HostIPv4;
    end;
  end
  else if vHLen > 4 then
    Typ := HostIPv6
  else
    Typ := HostIPv4;

  if vHasPort then
    Port := Integer(ParaBuf[System.Length(ParaBuf) - 1]) or (Integer(ParaBuf[System.Length(ParaBuf) - 2]) shl 8)
  else
    Port := DefaultPort;

  Result := True;
end;

function TEndPoint.Length: Integer;
begin
  Result := 1 + System.Length(Host);
  if Port <> DefaultPort then
    Result := Result + PortLength;
end;

function TEndPoint.ToString: string;
begin
  Result := Hostname + ':' + IntToStr(Port);
end;

function TEndPoint.Hostname: string;
var
  vIP: TIPAddress;
begin
  case Typ of
    HostDomain: Result := TEncoding.UTF8.GetString(Host);
    HostIPv4, HostIPv6:
      begin
        vIP := TIPAddress.Create(Host);
        if Typ = HostIPv6 then
          Result := '[' + vIP.ToString + ']'
        else
          Result := vIP.ToString;
      end;
  else
    Result := '';
  end;
end;

class function TEndPoint.Parse(const ParaHost: string): TEndPoint;
var
  vIndex: Integer;
  vHostname, vPortStr: string;
  vIP: TIPAddress;
begin
  if ParaHost = '' then
    raise errMissHost;

  vIndex := ParaHost.LastDelimiter(']:');
  if vIndex > 0 then
  begin
    vHostname := ParaHost.Substring(0, vIndex + 1);
    vPortStr := ParaHost.Substring(vIndex + 2);
  end
  else if ParaHost.EndsWith(']') then
  begin
    vHostname := ParaHost;
    vPortStr := '';
  end
  else
  begin
    vIndex := ParaHost.LastDelimiter(':');
    if vIndex > 0 then
    begin
      vHostname := ParaHost.Substring(0, vIndex);
      vPortStr := ParaHost.Substring(vIndex + 1);
    end
    else
    begin
      vHostname := ParaHost;
      vPortStr := '';
    end;
  end;

  if (vHostname.StartsWith('[') and vHostname.EndsWith(']')) then
  begin
    vHostname := vHostname.Substring(1, vHostname.Length - 2);
    if TIPAddress.TryParse(vHostname, vIP) then
    begin
      Result.Host := vIP.GetAddressBytes;
      if vIP.AddressFamily = TAddressFamily.IPv4 then
        Result.Typ := HostIPv4
      else
        Result.Typ := HostIPv6;
    end
    else
      raise errInvalidHost;
  end
  else if vHostname = Loopback then
  begin
    Result.Host := LoopbackIP;
    Result.Typ := HostIPv4;
  end
  else if TIPAddress.TryParse(vHostname, vIP) then
  begin
    Result.Host := vIP.GetAddressBytes;
    if vIP.AddressFamily = TAddressFamily.IPv4 then
      Result.Typ := HostIPv4
    else
      Result.Typ := HostIPv6;
  end
  else
  begin
    Result.Host := TEncoding.UTF8.GetBytes(vHostname);
    Result.Typ := HostDomain;
  end;

  if vPortStr = '' then
    Result.Port := DefaultPort
  else
    Result.Port := StrToInt(vPortStr);
end;

initialization
  SetLength(LoopbackIP, 4);
  LoopbackIP[0] := 127;
  LoopbackIP[1] := 0;
  LoopbackIP[2] := 0;
  LoopbackIP[3] := 1;
  errInvalidHost := Exception.Create('invalid Host');
  errMissHost := Exception.Create('missing Host');
  errUnmatchedLength := Exception.Create('unmatched length');
end.
