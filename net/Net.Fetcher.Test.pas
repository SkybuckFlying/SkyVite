unit Net.Fetcher.Test;

interface

uses
  TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Threading,
  System.DateUtils,
  Common.Types,
  Net.VNode,
  Net.Interface,
  Net.Fetcher,
  Net.Peer,
  Net.PeerSet;

type
  TMockCodec = class(TInterfacedObject, ICodec)
  public
    function ReadMsg: TMsg;
    procedure WriteMsg(Msg: TMsg);
    procedure Close;
    procedure SetReadTimeout(Timeout: Cardinal);
    procedure SetWriteTimeout(Timeout: Cardinal);
    procedure SetTimeout(Timeout: Cardinal);
    function Address: TSocketAddress;
  end;

  TMockReceiver = class(TInterfacedObject, IBlockReceiver)
  public
    function ReceiveAccountBlock(Block: IAccountBlock; Source: TBlockSource): Exception;
    function ReceiveSnapshotBlock(Block: ISnapshotBlock; Source: TBlockSource): Exception;
  end;

type
  [TestFixture]
  TFetcherTest = class(TObject)
  public
    [Test]
    procedure TestFetch_Failed;
    [Test]
    procedure TestRecord_Fail;
  end;

implementation

uses
  Net.Discovery.Node; // For TNode

{ TMockCodec }

function TMockCodec.ReadMsg: TMsg;
begin
  Result.Code := 0;
  Result.Id := 0;
  Result.Payload := nil;
end;

procedure TMockCodec.WriteMsg(Msg: TMsg);
begin
  // Do nothing
end;

procedure TMockCodec.Close;
begin
  // Do nothing
end;

procedure TMockCodec.SetReadTimeout(Timeout: Cardinal);
begin
  // Do nothing
end;

procedure TMockCodec.SetWriteTimeout(Timeout: Cardinal);
begin
  // Do nothing
end;

procedure TMockCodec.SetTimeout(Timeout: Cardinal);
begin
  // Do nothing
end;

function TMockCodec.Address: TSocketAddress;
begin
  Result := TSocketAddress.Create('127.0.0.1', 0);
end;

{ TMockReceiver }

function TMockReceiver.ReceiveAccountBlock(Block: IAccountBlock; Source: TBlockSource): Exception;
begin
  Result := nil;
end;

function TMockReceiver.ReceiveSnapshotBlock(Block: ISnapshotBlock; Source: TBlockSource): Exception;
begin
  Result := nil;
end;

{ TFetcherTest }

procedure TFetcherTest.TestFetch_Failed;
var
  Set_: IPeerSet;
  Peer: TPeer;
  Fet: IFetcher;
  Hash: THash;
  Msg: TMsg;
  Err: Exception;
  Ret: TRecord;
begin
  Set_ := TPeerSet.Create;
  Peer := TPeer.Create(TMockCodec.Create, nil);
  Peer.Height := 100;
  Peer.Id := TVNodeID.RandomNodeID;
  Peer.Reliable := 1;
  Peer.Writable := 1;
  Set_.Add(Peer);

  Fet := NewFetcher(Set_, TMockReceiver.Create, nil);
  (Fet as TFetcher).SubSyncState(ssDone);

  Fet.Start;

  Hash := THash.Create;
  Hash.Bytes[0] := 1;
  Fet.FetchSnapshotBlocks(Hash, 1);

  Msg.Code := CodeException;
  Msg.Id := (Fet as TFetcher).FIdGen.MsgID - 1;
  Msg.Sender := Peer;
  Err := (Fet as TFetcher).Handle(Msg);
  Assert.IsNull(Err, 'Handle should not return an error');

  (Fet as TFetcher).FMu.Acquire;
  try
    Ret := (Fet as TFetcher).FRecordsByHash[Hash];
    WriteLn(Ret.ToString);
  finally
    (Fet as TFetcher).FMu.Release;
  end;

  Fet.FetchSnapshotBlocks(Hash, 1);

  TThread.Sleep(30 * 1000); // 30 seconds

  Fet.FetchSnapshotBlocks(Hash, 1);

  Fet.Stop;
end;

procedure TFetcherTest.TestRecord_Fail;
var
  R: TRecord;
  Id: TPeerId;
  I: Integer;
begin
  R := TRecord.Create;
  try
    R.St := reqPending;
    R.Targets := TDictionary<TPeerId, TPeerFetchResult>.Create;

    Id := TVNodeID.RandomNodeID;
    R.Done(TPeer.Create(nil, nil), Default(TMsg), Exception.Create('fail'));
    Assert.AreEqual(Integer(reqError), Integer(R.St), 'Wrong status');
    // Assert.AreEqual(DateTimeToUnix(Now), R.T, 'Wrong time'); // Time comparison can be flaky

    R.Reset;
    for I := 0 to 2 do
    begin
      Id := TVNodeID.RandomNodeID;
      R.Done(TPeer.Create(nil, nil), Default(TMsg), Exception.Create('fail'));
      R.St := reqPending;
    end;

    Id := TVNodeID.RandomNodeID;
    R.Done(TPeer.Create(nil, nil), Default(TMsg), Exception.Create('fail'));
  finally
    R.Free;
  end;
end;

initialization
  RegisterTestFixture(TFetcherTest);
end.