unit Vendor.Github.Com.Shirou.Gopsutil.Host.Types;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  Vendor.Github.Com.Shirou.Gopsutil.Host.Host,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostBsd,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostDarwin,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostDarwin386,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostDarwinAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostDarwinArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostDarwinCgo,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostDarwinNocgo,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostFallback,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostFreebsd,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostFreebsd386,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostFreebsdAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostFreebsdArm,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostFreebsdArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinux,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinux386,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxArm,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxMips,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxMips64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxMips64le,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxMipsle,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxPpc64le,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxRiscv64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxS390x,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostOpenbsd,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostOpenbsd386,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostOpenbsdAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostOpenbsdArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostPosix,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostSolaris,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostWindows;

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
