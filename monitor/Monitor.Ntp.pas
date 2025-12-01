unit Monitor.NTP;

interface

uses
  System.SysUtils, System.Classes, Log15;

type
  TNTPChecker = class
  private
    mLogger: ILogger;
    mCheckTask: ITask;
    mCancelToken: TCancellationTokenSource;
    mAvailIndex: Integer;
    mServers: TArray<string>;
    mThreshold: TTimeSpan;
    function Request(ParaTimes: Integer; const ParaHost: string; ParaPort: Word; out ParaDrift: TTimeSpan): Boolean;
    procedure CheckTime;
    procedure CheckLoop;
  public
    constructor Create(ParaLogger: ILogger);
    destructor Destroy; override;
  end;

implementation

uses
  System.Threading, System.Net.UDPClient, System.Net.DNS, System.Generics.Defaults, System.Generics.Collections;

const
  ConstTimes = 3;

{ TNTPChecker }

constructor TNTPChecker.Create(ParaLogger: ILogger);
begin
  inherited Create;
  mLogger := ParaLogger.New(['module', 'ntp']);
  mServers := [
    'ntp.ntsc.ac.cn', 'time1.aliyun.com', 'time2.aliyun.com', 'time3.aliyun.com',
    'time4.aliyun.com', 'time5.aliyun.com', 'time6.aliyun.com', 'time7.aliyun.com',
    'time.google.com', 'time1.google.com', 'time2.google.com', 'time3.google.com',
    'time4.google.com', 'time.cloudflare.com'
  ];
  mAvailIndex := 0;
  mThreshold := TTimeSpan.FromSeconds(10);
  mCancelToken := TCancellationTokenSource.Create;
  mCheckTask := TTask.Run(CheckLoop, mCancelToken.Token);
end;

destructor TNTPChecker.Destroy;
begin
  if mCancelToken <> nil then
  begin
    mCancelToken.Cancel;
    mCheckTask.Wait;
    mCancelToken.Free;
  end;
  inherited Destroy;
end;

procedure TNTPChecker.CheckLoop;
begin
  while not mCancelToken.IsCancellationRequested do
  begin
    CheckTime;
    mCancelToken.Token.WaitFor(60000);
  end;
end;

procedure TNTPChecker.CheckTime;
var
  vDrift: TTimeSpan;
  vRetry: Integer;
  vAddr: string;
begin
  vRetry := 0;
  while not mCancelToken.IsCancellationRequested do
  begin
    vAddr := mServers[mAvailIndex] + ':123';
    if Request(ConstTimes, vAddr, 123, vDrift) then
    begin
      if (vDrift < -mThreshold) or (vDrift > mThreshold) then
        mLogger.Error(Format('too much delta to ntp server: %s', [vDrift.ToString]))
      else
        mLogger.Info(Format('time delta to ntp server: %s', [vDrift.ToString]));
      Break;
    end
    else
    begin
      mLogger.Error(Format('can not get ntp server time from %s', [mServers[mAvailIndex]]));
      Inc(mAvailIndex);
      mAvailIndex := mAvailIndex mod Length(mServers);
      Inc(vRetry);
      if vRetry > 2 * Length(mServers) then
      begin
        mLogger.Error('can`t find available ntp server');
        Exit;
      end;
    end;
  end;
end;

function TNTPChecker.Request(ParaTimes: Integer; const ParaHost: string; ParaPort: Word; out ParaDrift: TTimeSpan): Boolean;
var
  vRequestData: TBytes;
  vDs: TList<TTimeSpan>;
  vIndex: Integer;
  vUdpClient: TUDPClient;
  vSent: TDateTime;
  vReply: TBytes;
  vElapsed: TTimeSpan;
  vSec, vFrac, vNanoSec: UInt64;
  vServerTime: TDateTime;
  vTotalDrift: TTimeSpan;
  vIPs: TArray<TIPAddress>;
  vHostName: string;
  vPort: Word;
  vParts: TArray<string>;
begin
  Result := False;
  ParaDrift := TTimeSpan.Zero;
  SetLength(vRequestData, 48);
  vRequestData[0] := (4 shl 3) or 3;

  vDs := TList<TTimeSpan>.Create;
  try
    vParts := ParaHost.Split([':']);
    vHostName := vParts[0];
    vPort := StrToInt(vParts[1]);

    vIPs := TDNS.GetHostAddresses(vHostName);
    if Length(vIPs) = 0 then
      Exit;

    vUdpClient := TUDPClient.Create(nil);
    try
      vUdpClient.RemoteHost := vIPs[0].ToString;
      vUdpClient.RemotePort := vPort;
      vUdpClient.ReceiveTimeout := 10000;

      for vIndex := 0 to ParaTimes + 1 do
      begin
        try
          vSent := Now;
          vUdpClient.Send(vRequestData);
          vReply := vUdpClient.Receive;
          vElapsed := Now - vSent;

          if Length(vReply) < 48 then
            Continue;

          vSec := (UInt64(vReply[43])) or (UInt64(vReply[42]) shl 8) or (UInt64(vReply[41]) shl 16) or (UInt64(vReply[40]) shl 24);
          vFrac := (UInt64(vReply[47])) or (UInt64(vReply[46]) shl 8) or (UInt64(vReply[45]) shl 16) or (UInt64(vReply[44]) shl 24);
          vNanoSec := vSec * 1000000000 + (vFrac * 1000000000) shr 32;
          vServerTime := TDateTime.Create(1900, 1, 1, 0, 0, 0, 0) + TTimeSpan.FromTicks(vNanoSec div 100);

          vDs.Add(vSent - vServerTime + TTimeSpan.FromTicks(vElapsed.Ticks div 2));
        except
          // Ignore exceptions and try again
        end;
      end;
    finally
      vUdpClient.Free;
    end;

    if vDs.Count < 3 then
      Exit;

    vDs.Sort;
    vTotalDrift := TTimeSpan.Zero;
    for vIndex := 1 to vDs.Count - 2 do
      vTotalDrift := vTotalDrift + vDs[vIndex];

    ParaDrift := TTimeSpan.FromTicks(vTotalDrift.Ticks div (vDs.Count - 2));
    Result := True;
  finally
    vDs.Free;
  end;
end;

end.