unit Vendor.Github.Com.Shirou.Gopsutil.Net.Net;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetAix,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetDarwin,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetFallback,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetFreebsd,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetLinux,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetOpenbsd,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetUnix,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetWindows;

type
	TIOCountersStat = record
		Name        : string;
		BytesSent   : UInt64;
		BytesRecv   : UInt64;
		PacketsSent : UInt64;
		PacketsRecv : UInt64;
		Errin       : UInt64;
		Errout      : UInt64;
		Dropin      : UInt64;
		Dropout     : UInt64;
		Fifoin      : UInt64;
		Fifoout     : UInt64;
		function Stringify : string;
	end;

	TAddr = record
		IP   : string;
		Port : UInt32;
		function Stringify : string;
	end;

	TConnectionStat = record
		Fd     : UInt32;
		Family : UInt32;
		SockType : UInt32;
		Laddr  : TAddr;
		Raddr  : TAddr;
		Status : string;
		Uids   : TArray<Int32>;
		Pid    : Int32;
		function Stringify : string;
	end;

	TProtoCountersStat = record
		Protocol : string;
		Stats    : TDictionary<string, Int64>;
		function Stringify : string;
	end;

	TInterfaceAddr = record
		Addr : string;
		function Stringify : string;
	end;

	TInterfaceStat = record
		Index        : Integer;
		MTU          : Integer;
		Name         : string;
		HardwareAddr : string;
		Flags        : TArray<string>;
		Addrs        : TArray<TInterfaceAddr>;
		function Stringify : string;
	end;

	TFilterStat = record
		ConnTrackCount : Int64;
		ConnTrackMax   : Int64;
	end;

	TConntrackStat = record
		Entries       : UInt32;
		Searched      : UInt32;
		Found         : UInt32;
		New           : UInt32;
		Invalid       : UInt32;
		Ignore        : UInt32;
		Delete        : UInt32;
		DeleteList    : UInt32;
		Insert        : UInt32;
		InsertFailed  : UInt32;
		Drop          : UInt32;
		EarlyDrop     : UInt32;
		IcmpError     : UInt32;
		ExpectNew     : UInt32;
		ExpectCreate  : UInt32;
		ExpectDelete  : UInt32;
		SearchRestart : UInt32;
		function Stringify : string;
	end;

function Interfaces : TArray<TInterfaceStat>;
function IOCounters( ParaPernic : Boolean ) : TArray<TIOCountersStat>;
function Connections( const ParaKind : string ) : TArray<TConnectionStat>;

implementation

uses
	{$IFDEF MSWINDOWS}
	Vendor.Github.Com.Shirou.Gopsutil.Net.NetWindows
	{$ELSE}
	Vendor.Github.Com.Shirou.Gopsutil.Net.NetFallback
	{$ENDIF}
	;

{ TIOCountersStat }

function TIOCountersStat.Stringify : string;
begin
	Result := Format( '{"name":"%s","bytesSent":%d,"bytesRecv":%d}', [ Name, BytesSent, BytesRecv ] );
end;

{ TAddr }

function TAddr.Stringify : string;
begin
	Result := Format( '{"ip":"%s","port":%d}', [ IP, Port ] );
end;

{ TConnectionStat }

function TConnectionStat.Stringify : string;
begin
	Result := Format( '{"pid":%d,"status":"%s","laddr":%s,"raddr":%s}', [ Pid, Status, Laddr.Stringify, Raddr.Stringify ] );
end;

{ TProtoCountersStat }

function TProtoCountersStat.Stringify : string;
begin
	Result := Format( '{"protocol":"%s"}', [ Protocol ] );
end;

{ TInterfaceAddr }

function TInterfaceAddr.Stringify : string;
begin
	Result := Format( '{"addr":"%s"}', [ Addr ] );
end;

{ TInterfaceStat }

function TInterfaceStat.Stringify : string;
begin
	Result := Format( '{"name":"%s","mtu":%d}', [ Name, MTU ] );
end;

{ TConntrackStat }

function TConntrackStat.Stringify : string;
begin
	Result := Format( '{"entries":%d}', [ Entries ] );
end;

{ Core functions }

function Interfaces : TArray<TInterfaceStat>;
begin
	{$IFDEF MSWINDOWS}
	Result := WinInterfaces;
	{$ELSE}
	SetLength( Result, 0 );
	{$ENDIF}
end;

function IOCounters( ParaPernic : Boolean ) : TArray<TIOCountersStat>;
begin
	{$IFDEF MSWINDOWS}
	Result := WinIOCounters( ParaPernic );
	{$ELSE}
	SetLength( Result, 0 );
	{$ENDIF}
end;

function Connections( const ParaKind : string ) : TArray<TConnectionStat>;
begin
	{$IFDEF MSWINDOWS}
	Result := WinConnections( ParaKind );
	{$ELSE}
	SetLength( Result, 0 );
	{$ENDIF}
end;

end.
