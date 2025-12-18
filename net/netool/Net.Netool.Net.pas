unit Net.Netool.Net;

interface

uses
  Net.Block.Feed,
  Net.Block.Feed.Test,
  Net.Broadcaster,
  Net.Broadcaster.Test,
  Net.Codec,
  Net.Codec.Test,
  Net.Connector.Connector,
  Net.Database.Database,
  Net.Database.Database.Test,
  Net.Discovery.Booter,
  Net.Discovery.Booter.Test,
  Net.Discovery.Bucket.Test,
  Net.Discovery.Discovery,
  Net.Discovery.Discovery.Test,
  Net.Discovery.Finder,
  Net.Discovery.Message,
  Net.Discovery.Message.Test,
  Net.Discovery.Mock.Socket,
  Net.Discovery.Node,
  Net.Discovery.Node.Test,
  Net.Discovery.Pool,
  Net.Discovery.Pool.Test,
  Net.Discovery.Protos.Message.PB,
  Net.Discovery.Simular.Simular,
  Net.Discovery.Socket,
  Net.Discovery.Socket.Test,
  Net.Discovery.Table,
  Net.Discovery.Table.Test,
  Net.Fetcher,
  Net.Fetcher.Test,
  Net.Finder,
  Net.Handshaker,
  Net.Handshaker.Test,
  Net.Interface,
  Net.Message,
  Net.Message.Test,
  Net.Mock.Chain,
  Net.Mock.Codec,
  Net.Mock.Net,
  Net.Mock.Receiver,
  Net.MsgHandler,
  Net.MsgHandler.Test,
  Net.Net,
  Net.Netool.Blacklist,
  Net.Netool.Net,
  Net.Netool.Net.Test,
  Net.Peer,
  Net.Peer.Error,
  Net.Peer.Test,
  Net.Skeleton,
  Net.Skeleton.Test,
  Net.Sync.Cache.Reader,
  Net.Sync.Cache.Reader.Test,
  Net.Sync.Conn,
  Net.Sync.Conn.Test,
  Net.Sync.Downloader,
  Net.Sync.Downloader.Test,
  Net.Sync.Server,
  Net.Sync.Server.Test,
  Net.Sync.State,
  Net.Sync.State.Test,
  Net.Syncer,
  Net.Syncer.Test,
  Net.Vnode.Endpoint,
  Net.Vnode.Endpoint.Test,
  Net.Vnode.Host,
  Net.Vnode.Host.Test,
  Net.Vnode.Mock,
  Net.Vnode.Mode,
  Net.Vnode.Node,
  Net.Vnode.Node.PB,
  Net.Vnode.Node.Test,
  System.Classes,
  System.Generics.Collections,
  System.Net.IP,
  System.Net.Socket,
  System.StrUtils,
  System.SysUtils;

type
  TNetlist = class(TList<TIPNet>)
  public
    function Contains(ParaIP: TIPAddress): Boolean;
    procedure Add(const ParaCIDR: string);
    class function Parse(const ParaS: string): TNetlist;
  end;

function IsLAN(ParaIP: TIPAddress): Boolean;
function IsSpecialNetwork(ParaIP: TIPAddress): Boolean;
function CheckRelayIP(ParaSender, ParaAddr: TIPAddress): Exception;
function SameNet(ParaBits: Cardinal; ParaIP, ParaOther: TIPAddress): Boolean;

type
  TDistinctNetSet = class
  private
    mSubnet: Cardinal;
    mLimit: Cardinal;
    mMembers: TDictionary<string, Cardinal>;
    mBuf: TBytes;
    function GetKey(ParaIP: TIPAddress): TBytes;
  public
    constructor Create(ParaSubnet, ParaLimit: Cardinal);
    destructor Destroy; override;
    function Add(ParaIP: TIPAddress): Boolean;
    procedure Remove(ParaIP: TIPAddress);
    function Contains(ParaIP: TIPAddress): Boolean;
    function Len: Integer;
    function ToString: string;
  end;

var
  lan4, lan6, special4, special6: TNetlist;

implementation

uses
  System.Math,
  System.Net.Winsock;

function IsLAN(ParaIP: TIPAddress): Boolean;
begin
  if ParaIP.IsLoopback then
    Result := True
  else if ParaIP.AddressFamily = TAddressFamily.IPv4 then
    Result := lan4.Contains(ParaIP)
  else
    Result := lan6.Contains(ParaIP);
end;

function IsSpecialNetwork(ParaIP: TIPAddress): Boolean;
begin
  if ParaIP.IsMulticast then
    Result := True
  else if ParaIP.AddressFamily = TAddressFamily.IPv4 then
    Result := special4.Contains(ParaIP)
  else
    Result := special6.Contains(ParaIP);
end;

function CheckRelayIP(ParaSender, ParaAddr: TIPAddress): Exception;
begin
  Result := nil;
  if (ParaAddr.AddressFamily <> TAddressFamily.IPv4) and (ParaAddr.AddressFamily <> TAddressFamily.IPv6) then
    Result := Exception.Create('invalid IP')
  else if ParaAddr.IsUnspecified then
    Result := Exception.Create('zero address')
  else if IsSpecialNetwork(ParaAddr) then
    Result := Exception.Create('special network')
  else if ParaAddr.IsLoopback and not ParaSender.IsLoopback then
    Result := Exception.Create('loopback address from non-loopback host')
  else if IsLAN(ParaAddr) and not IsLAN(ParaSender) then
    Result := Exception.Create('LAN address from WAN host');
end;

function SameNet(ParaBits: Cardinal; ParaIP, ParaOther: TIPAddress): Boolean;
var
  vIPBytes, vOtherBytes: TBytes;
  vNB: Integer;
  vMask: Byte;
begin
  if ParaIP.AddressFamily <> ParaOther.AddressFamily then
    Exit(False);

  vIPBytes := ParaIP.GetAddressBytes;
  vOtherBytes := ParaOther.GetAddressBytes;

  vNB := ParaBits div 8;
  if vNB > Length(vIPBytes) then
    vNB := Length(vIPBytes);

  if not CompareMem(vIPBytes, vOtherBytes, vNB) then
    Exit(False);

  if ParaBits mod 8 <> 0 then
  begin
    vMask := not (Byte($FF) shr (ParaBits mod 8));
    if (vIPBytes[vNB] and vMask) <> (vOtherBytes[vNB] and vMask) then
      Exit(False);
  end;

  Result := True;
end;

{ TNetlist }

procedure TNetlist.Add(const ParaCIDR: string);
var
  vNet: TIPNet;
begin
  if TIPNet.TryParse(ParaCIDR, vNet) then
    inherited Add(vNet)
  else
    raise Exception.CreateFmt('Invalid CIDR: %s', [ParaCIDR]);
end;

function TNetlist.Contains(ParaIP: TIPAddress): Boolean;
var
  vNet: TIPNet;
begin
  Result := False;
  for vNet in Self do
    if vNet.Contains(ParaIP) then
      Exit(True);
end;

class function TNetlist.Parse(const ParaS: string): TNetlist;
var
  vMasks: TArray<string>;
  vMask: string;
begin
  Result := TNetlist.Create;
  vMasks := ParaS.Split([',', ' ', #9, #10, #13], TStringSplitOptions.ExcludeEmpty);
  for vMask in vMasks do
    Result.Add(vMask);
end;

{ TDistinctNetSet }

constructor TDistinctNetSet.Create(ParaSubnet, ParaLimit: Cardinal);
begin
  mSubnet := ParaSubnet;
  mLimit := ParaLimit;
  mMembers := TDictionary<string, Cardinal>.Create;
  SetLength(mBuf, 17);
end;

destructor TDistinctNetSet.Destroy;
begin
  mMembers.Free;
  inherited;
end;

function TDistinctNetSet.Add(ParaIP: TIPAddress): Boolean;
var
  vKey: TBytes;
  vN: Cardinal;
  vKeyStr: string;
begin
  vKey := GetKey(ParaIP);
  vKeyStr := TEncoding.ASCII.GetString(vKey);
  if mMembers.TryGetValue(vKeyStr, vN) then
  begin
    if vN < mLimit then
    begin
      mMembers[vKeyStr] := vN + 1;
      Result := True;
    end
    else
      Result := False;
  end
  else
  begin
    mMembers.Add(vKeyStr, 1);
    Result := True;
  end;
end;

procedure TDistinctNetSet.Remove(ParaIP: TIPAddress);
var
  vKey: TBytes;
  vN: Cardinal;
  vKeyStr: string;
begin
  vKey := GetKey(ParaIP);
  vKeyStr := TEncoding.ASCII.GetString(vKey);
  if mMembers.TryGetValue(vKeyStr, vN) then
  begin
    if vN = 1 then
      mMembers.Remove(vKeyStr)
    else
      mMembers[vKeyStr] := vN - 1;
  end;
end;

function TDistinctNetSet.Contains(ParaIP: TIPAddress): Boolean;
var
  vKey: TBytes;
  vKeyStr: string;
begin
  vKey := GetKey(ParaIP);
  vKeyStr := TEncoding.ASCII.GetString(vKey);
  Result := mMembers.ContainsKey(vKeyStr);
end;

function TDistinctNetSet.Len: Integer;
var
  vN: Cardinal;
begin
  Result := 0;
  for vN in mMembers.Values do
    Result := Result + vN;
end;

function TDistinctNetSet.GetKey(ParaIP: TIPAddress): TBytes;
var
  vTyp: Byte;
  vIPBytes: TBytes;
  vBits, vNB: Cardinal;
  vMask: Byte;
  vBuf: TBytes;
begin
  if ParaIP.AddressFamily = TAddressFamily.IPv4 then
  begin
    vTyp := Ord('4');
    vIPBytes := ParaIP.GetAddressBytes;
  end
  else
  begin
    vTyp := Ord('6');
    vIPBytes := ParaIP.GetAddressBytes;
  end;

  vBits := mSubnet;
  if vBits > Cardinal(Length(vIPBytes) * 8) then
    vBits := Cardinal(Length(vIPBytes) * 8);

  vNB := vBits div 8;
  vMask := not (Byte($FF) shr (vBits mod 8));

  SetLength(vBuf, 1 + vNB + Ord(vMask <> 0));
  vBuf[0] := vTyp;
  System.Move(vIPBytes[0], vBuf[1], vNB);
  if vMask <> 0 then
    vBuf[1 + vNB] := vIPBytes[vNB] and vMask;

  Result := vBuf;
end;

function TDistinctNetSet.ToString: string;
var
  vKeys: TArray<string>;
  vKey: string;
  vIP: TIPAddress;
  vIPBytes: TBytes;
  vI: Integer;
begin
  Result := '{';
  vKeys := mMembers.Keys.ToArray;
  TArray.Sort<string>(vKeys);
  for vI := 0 to High(vKeys) do
  begin
    vKey := vKeys[vI];
    if vKey[0] = '4' then
      SetLength(vIPBytes, 4)
    else
      SetLength(vIPBytes, 16);
    System.Move(vKey[1], vIPBytes[0], Length(vIPBytes));
    vIP := TIPAddress.Create(vIPBytes);
    Result := Result + vIP.ToString + '×' + mMembers[vKey].ToString;
    if vI < High(vKeys) then
      Result := Result + ' ';
  end;
  Result := Result + '}';
end;

initialization
  lan4 := TNetlist.Create;
  lan4.Add('0.0.0.0/8');
  lan4.Add('10.0.0.0/8');
  lan4.Add('172.16.0.0/12');
  lan4.Add('192.168.0.0/16');

  lan6 := TNetlist.Create;
  lan6.Add('fe80::/10');
  lan6.Add('fc00::/7');

  special4 := TNetlist.Create;
  special4.Add('192.0.0.0/29');
  special4.Add('192.0.0.9/32');
  special4.Add('192.0.0.170/32');
  special4.Add('192.0.0.171/32');
  special4.Add('192.0.2.0/24');
  special4.Add('192.31.196.0/24');
  special4.Add('192.52.193.0/24');
  special4.Add('192.88.99.0/24');
  special4.Add('192.175.48.0/24');
  special4.Add('198.18.0.0/15');
  special4.Add('198.51.100.0/24');
  special4.Add('203.0.113.0/24');
  special4.Add('255.255.255.255/32');

  special6 := TNetlist.Create;
  special6.Add('100::/64');
  special6.Add('2001::/32');
  special6.Add('2001:1::1/128');
  special6.Add('2001:2::/48');
  special6.Add('2001:3::/32');
  special6.Add('2001:4:112::/48');
  special6.Add('2001:5::/32');
  special6.Add('2001:10::/28');
  special6.Add('2001:20::/28');
  special6.Add('2001:db8::/32');
  special6.Add('2002::/16');

finalization
  lan4.Free;
  lan6.Free;
  special4.Free;
  special6.Free;

end.
