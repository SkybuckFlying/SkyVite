unit Common.VitePb.VmLogList;

interface

uses
  Common.VitePB.Account.Block.PB,
  Common.VitePB.Account.Blockmeta.PB,
  Common.VitePB.Account.PB,
  Common.VitePB.Consensus.Point.PB,
  Common.VitePB.Message.PB,
  Common.VitePB.Onroad.PB,
  Common.VitePB.Snapshot.Block.PB,
  Common.VitePB.Sync.Cache.PB,
  System.SysUtils System.Classes System.Generics.Collections;

type
  TVmLog = class;      // Forward declaration
  TVmLogList = class;  // Forward declaration

  {
    TVmLog corresponds to the VmLog message in vm_log_list.proto
  }
  TVmLog = class
  private
    mTopics: TArray<TBytes>;
    mData: TBytes;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property Topics: TArray<TBytes> read mTopics write mTopics;
    property Data: TBytes read mData write mData;
  end;

  {
    TVmLogList corresponds to the VmLogList message in vm_log_list.proto
  }
  TVmLogList = class
  private
    mList: TObjectList<TVmLog>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    property List: TObjectList<TVmLog> read mList;
  end;

implementation

{ TVmLog }

constructor TVmLog.Create;
begin
  inherited Create;
  Reset;
end;

destructor TVmLog.Destroy;
var
  vIndex: Integer;
begin
  for vIndex := 0 to High(mTopics) do
  begin
    mTopics[vIndex] := nil;
  end;
  mTopics := nil;
  mData := nil;
  inherited Destroy;
end;

procedure TVmLog.Reset;
begin
  SetLength(mTopics, 0);
  mData := nil;
end;

{ TVmLogList }

constructor TVmLogList.Create;
begin
  inherited Create;
  try
    mList := TObjectList<TVmLog>.Create(True);
  except
    on E: Exception do
    begin
      raise;
    end;
  end;
  Reset;
end;

destructor TVmLogList.Destroy;
begin
  mList.Free;
  inherited Destroy;
end;

procedure TVmLogList.Reset;
begin
  mList.Clear;
end;

end.
