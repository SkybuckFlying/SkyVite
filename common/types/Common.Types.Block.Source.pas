unit Common.Types.BlockSource;

interface

uses
  Common.Types.Address,
  Common.Types.Address.Test,
  Common.Types.Contracts,
  Common.Types.Enum,
  Common.Types.Error,
  Common.Types.Gid,
  Common.Types.Hash,
  Common.Types.Hash.Test,
  Common.Types.Height,
  Common.Types.Jsonutils,
  Common.Types.Quota,
  Common.Types.TokenTypeID,
  Common.Types.TokenTypeID.Test,
  System.SysUtils;

type
  TBlockSourceType = type Word;

  TBlockSourceHelper = record helper for TBlockSourceType
  public
    function ToString: string;
    function MarshalText: TBytes;
    function UnmarshalText(const ParaText: TBytes): Boolean;
  end;

const
  bstUnknown: TBlockSourceType = 0;
  bstRemoteBroadcast: TBlockSourceType = 10;
  bstRemoteFetch: TBlockSourceType = 20;
  bstLocal: TBlockSourceType = 30;
  bstRollbackChain: TBlockSourceType = 40;
  bstQueryChain: TBlockSourceType = 41;
  bstRemoteSync: TBlockSourceType = 50;
  bstRemoteCache: TBlockSourceType = 60;

function BlockSourceFromString(const ParaString: string; out ParaSource: TBlockSourceType): Boolean;

implementation

function BlockSourceFromString(const ParaString: string; out ParaSource: TBlockSourceType): Boolean;
begin
  Result := True;
  if ParaString = 'RemoteBroadcast' then
  begin
    ParaSource := bstRemoteBroadcast;
  end
  else if ParaString = 'RemoteFetch' then
  begin
    ParaSource := bstRemoteFetch;
  end
  else if ParaString = 'Local' then
  begin
    ParaSource := bstLocal;
  end
  else if ParaString = 'RollbackChain' then
  begin
    ParaSource := bstRollbackChain;
  end
  else if ParaString = 'QueryChain' then
  begin
    ParaSource := bstQueryChain;
  end
  else if ParaString = 'RemoteSync' then
  begin
    ParaSource := bstRemoteSync;
  end
  else if ParaString = 'RemoteCache' then
  begin
    ParaSource := bstRemoteCache;
  end
  else
  begin
    ParaSource := bstUnknown;
    Result := False; // Indicate that the string was not found, but still assign a default
  end;
end;

{ TBlockSourceHelper }

function TBlockSourceHelper.ToString: string;
begin
  case Self of
    bstRemoteBroadcast:
      Result := 'RemoteBroadcast';
    bstRemoteFetch:
      Result := 'RemoteFetch';
    bstLocal:
      Result := 'Local';
    bstRollbackChain:
      Result := 'RollbackChain';
    bstQueryChain:
      Result := 'QueryChain';
    bstRemoteSync:
      Result := 'RemoteSync';
    bstRemoteCache:
      Result := 'RemoteCache';
  else
    Result := 'Unknown';
  end;
end;

function TBlockSourceHelper.MarshalText: TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(Self.ToString);
end;

function TBlockSourceHelper.UnmarshalText(const ParaText: TBytes): Boolean;
var
  vSource: TBlockSourceType;
  vString: string;
begin
  vString := TEncoding.UTF8.GetString(ParaText);
  Result := BlockSourceFromString(vString, vSource);
  if Result then
  begin
    Self := vSource;
  end;
end;

end.
