unit Common.Config.Net;

interface

uses
  Common.Config.Chain,
  Common.Config.Config,
  Common.Config.Genesis,
  Common.Config.Genesis.Json,
  Common.Config.Genesis.Mock.Json,
  Common.Config.Genesis.Test,
  Common.Config.Node.Reward,
  Common.Config.Producer,
  Common.Config.Subscribe,
  Common.Config.Upgrade,
  Common.Config.VM,
  Common.Config.Wallet,
  Crypto.Ed25519,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

const
  ConstDefaultSingle = false;
  ConstDefaultNodeName = 'vite-node';
  ConstDefaultNetID = 3;
  ConstDefaultListenInterface = '0.0.0.0';
  ConstDefaultPort = 8483;
  ConstDefaultFilePort = 8484;
  ConstDefaultDiscover = true;
  ConstDefaultMaxPeers = 60;
  ConstDefaultMaxInboundRatio = 2;
  ConstDefaultMinPeers = 5;
  ConstDefaultMaxPendingPeers = 10;
  ConstDefaultNetDirName = 'net';
  ConstPeerKeyFileName = 'peerKey';
  ConstDefaultForwardStrategy = 'cross';
  ConstDefaultAccessControl = 'any';

type
  TNet = class
  private
    mSingle: boolean;
    mName: string;
    mNetID: integer;
    mListenInterface: string;
    mPort: integer;
    mFilePort: integer;
    mPublicAddress: string;
    mFilePublicAddress: string;
    mDataDir: string;
    mPeerKey: string;
    mDiscover: boolean;
    mBootNodes: TArray<string>;
    mBootSeeds: TArray<string>;
    mStaticNodes: TArray<string>;
    mMaxPeers: integer;
    mMaxInboundRatio: integer;
    mMinPeers: integer;
    mMaxPendingPeers: integer;
    mForwardStrategy: string;
    mAccessControl: string;
    mAccessAllowKeys: TArray<string>;
    mAccessDenyKeys: TArray<string>;
    mBlackBlockHashList: TArray<string>;
    mWhiteBlockList: TArray<string>;
    mMineKey: TEd25519PrivateKey;

    function GetPeerKeyFromFile(const ParaFilename: string): TEd25519PrivateKey;
  public
    constructor Create;
    destructor Destroy; override;
    function Init: TEd25519PrivateKey;

    property Single: boolean read mSingle write mSingle;

    // Name is our node name, NO need to be unique in the whole network, just for readability, default is `vite-node`
    property Name: string read mName write mName;

    // NetID is to mark which network our node in, nodes from different network can`t connect each other
    property NetID: integer read mNetID write mNetID;

    property ListenInterface: string read mListenInterface write mListenInterface;
    property Port: integer read mPort write mPort;
    property FilePort: integer read mFilePort write mFilePort;

    // PublicAddress is the network address can be access by other nodes, usually is the public Internet address
    property PublicAddress: string read mPublicAddress write mPublicAddress;
    property FilePublicAddress: string read mFilePublicAddress write mFilePublicAddress;

    // DataDir is the directory to storing p2p data, if is null-string, will use memory as database
    property DataDir: string read mDataDir write mDataDir;

    // PeerKey is to encrypt message, the corresponding public key use for NodeID, MUST NOT be revealed
    property PeerKey: string read mPeerKey write mPeerKey;

    // Discover means whether discover other nodes in the networks, default true
    property Discover: boolean read mDiscover write mDiscover;

    // BootNodes are roles as network entrance. Node can discovery more other nodes by send UDP query BootNodes,
    // but not create a TCP connection to BootNodes directly
    property BootNodes: TArray<string> read mBootNodes write mBootNodes;

    // BootSeeds are the address where can query BootNodes, is a more flexible option than BootNodes
    property BootSeeds: TArray<string> read mBootSeeds write mBootSeeds;

    // StaticNodes will be connect directly
    property StaticNodes: TArray<string> read mStaticNodes write mStaticNodes;

    property MaxPeers: integer read mMaxPeers write mMaxPeers;
    property MaxInboundRatio: integer read mMaxInboundRatio write mMaxInboundRatio;

    // MinPeers server will keep finding nodes and try to connect until number of peers is larger than `MinPeers`, default 5
    property MinPeers: integer read mMinPeers write mMinPeers;

    // MaxPendingPeers how many inbound peers can be connect concurrently, more inbound connection will be blocked
    // this value is for defend DDOS attack, default 10
    property MaxPendingPeers: integer read mMaxPendingPeers write mMaxPendingPeers;

    property ForwardStrategy: string read mForwardStrategy write mForwardStrategy;
    property AccessControl: string read mAccessControl write mAccessControl;
    property AccessAllowKeys: TArray<string> read mAccessAllowKeys write mAccessAllowKeys;
    property AccessDenyKeys: TArray<string> read mAccessDenyKeys write mAccessDenyKeys;
    property BlackBlockHashList: TArray<string> read mBlackBlockHashList write mBlackBlockHashList;
    property WhiteBlockList: TArray<string> read mWhiteBlockList write mWhiteBlockList;

    property MineKey: TEd25519PrivateKey read mMineKey;
  end;

implementation

uses
  System.IOUtils;

{ TNet }

constructor TNet.Create;
begin
  inherited Create;
  mSingle := ConstDefaultSingle;
  mName := ConstDefaultNodeName;
  mNetID := ConstDefaultNetID;
  mListenInterface := ConstDefaultListenInterface;
  mPort := ConstDefaultPort;
  mFilePort := ConstDefaultFilePort;
  mDiscover := ConstDefaultDiscover;
  mMaxPeers := ConstDefaultMaxPeers;
  mMaxInboundRatio := ConstDefaultMaxInboundRatio;
  mMinPeers := ConstDefaultMinPeers;
  mMaxPendingPeers := ConstDefaultMaxPendingPeers;
  mForwardStrategy := ConstDefaultForwardStrategy;
  mAccessControl := ConstDefaultAccessControl;
  SetLength(mBootNodes, 0);
  SetLength(mBootSeeds, 0);
  SetLength(mStaticNodes, 0);
  SetLength(mAccessAllowKeys, 0);
  SetLength(mAccessDenyKeys, 0);
  SetLength(mBlackBlockHashList, 0);
  SetLength(mWhiteBlockList, 0);
end;

destructor TNet.Destroy;
begin
  mBootNodes := nil;
  mBootSeeds := nil;
  mStaticNodes := nil;
  mAccessAllowKeys := nil;
  mAccessDenyKeys := nil;
  mBlackBlockHashList := nil;
  mWhiteBlockList := nil;
  mMineKey := nil;
  inherited Destroy;
end;

function TNet.GetPeerKeyFromFile(const ParaFilename: string): TEd25519PrivateKey;
var
  vPrivateKeyBytes: TBytes;
begin
  Result := nil;
  // Try to read existing key
  if TFile.Exists(ParaFilename) then
  begin
    try
      vPrivateKeyBytes := TFile.ReadAllBytes(ParaFilename);
      if Length(vPrivateKeyBytes) = TEd25519.PrivateKeySize then
      begin
        Result := vPrivateKeyBytes;
        Exit;
      end;
    except
      // Ignore read errors, a new key will be generated.
    end;
  end;

  // If read failed or key is invalid, generate a new one.
  Result := TEd25519.GenerateKey(nil).PrivateKey;
  try
    TFile.WriteAllBytes(ParaFilename, Result);
  except
    on E: Exception do
    begin
      // If we can't save the key, we can't guarantee it will be the same on next run.
      // This is a critical error.
      raise Exception.Create(Format('Failed to save new peer key to file %s: %s', [ParaFilename, E.Message]));
    end;
  end;
end;

function TNet.Init: TEd25519PrivateKey;
var
  vKeyFile: string;
begin
  if mDataDir <> '' then
  begin
    try
      TDirectory.CreateDirectory(mDataDir);
    except
      on E: Exception do
      begin
        raise Exception.Create(Format('Failed to create data directory %s: %s', [mDataDir, E.Message]));
      end;
    end;
  end;

  if mPeerKey = '' then
  begin
    if mDataDir = '' then
    begin
      // No data directory, use an in-memory key
      Result := TEd25519.GenerateKey(nil).PrivateKey;
    end
    else
    begin
      // Use a key file in the data directory
      vKeyFile := TPath.Combine(mDataDir, ConstPeerKeyFileName);
      Result := GetPeerKeyFromFile(vKeyFile);
    end;
  end
  else
  begin
    // Use the key provided in the config
    try
      Result := TEd25519.HexToPrivateKey(mPeerKey);
    except
      on E: Exception do
      begin
        raise Exception.Create(Format('Failed to parse PeerKey: %s', [E.Message]));
      end;
    end;
  end;

  if Result = nil then
  begin
    raise Exception.Create('Fatal: Failed to generate or load peer key.');
  end;

  mMineKey := Result;
end;

end.
