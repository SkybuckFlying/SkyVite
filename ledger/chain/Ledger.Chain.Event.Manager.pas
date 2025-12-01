unit Ledger.Chain.EventManager;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  V2.Interfaces,
  V2.Interfaces.Core,
  V2.Ledger.Chain.Chain;

const
  ConstPrepareInsertAbsEvent = $01;
  ConstInsertAbsEvent        = $02;
  ConstPrepareInsertSbsEvent = $03;
  ConstInsertSbsEvent        = $04;
  ConstPrepareDeleteAbsEvent = $05;
  ConstDeleteAbsEvent        = $06;
  ConstPrepareDeleteSbsEvent = $07;
  ConstDeleteSbsEvent        = $08;

type
  TEventManager = class
  private
    mListenerList: TList<IEventListener>;
    mChain: TChain;
    mMaxHandlerId: Cardinal;
    mMutex: TCriticalSection;
    procedure SplitChunks(const ParaChunks: TArray<ISnapshotChunk>; out ParaSnapshotBlocks: TArray<ISnapshotBlock>; out ParaAccountBlocksList: TArray<TArray<IAccountBlock>>);
  public
    constructor Create(ParaChain: TChain);
    destructor Destroy; override;
    function TriggerInsertAbs(ParaEventType: Byte; const ParaVmAccountBlocks: TArray<IVmAccountBlock>): string;
    function TriggerDeleteAbs(ParaEventType: Byte; const ParaAccountBlocks: TArray<IAccountBlock>): string;
    function TriggerInsertSbs(ParaEventType: Byte; const ParaChunks: TArray<ISnapshotChunk>): string;
    function TriggerDeleteSbs(ParaEventType: Byte; const ParaChunks: TArray<ISnapshotChunk>): string;
    procedure Register(ParaListener: IEventListener);
    procedure UnRegister(ParaListener: IEventListener);
  end;

  TChainHelper = class helper for TChain
  public
    procedure Register(ParaListener: IEventListener);
    procedure UnRegister(ParaListener: IEventListener);
  end;

implementation

{ TEventManager }

constructor TEventManager.Create(ParaChain: TChain);
begin
  inherited Create;
  mChain := ParaChain;
  mMaxHandlerId := 0;
  mListenerList := TList<IEventListener>.Create;
  mMutex := TCriticalSection.Create;
end;

destructor TEventManager.Destroy;
begin
  mListenerList.Free;
  mMutex.Free;
  inherited;
end;

procedure TEventManager.SplitChunks(const ParaChunks: TArray<ISnapshotChunk>; out ParaSnapshotBlocks: TArray<ISnapshotBlock>; out ParaAccountBlocksList: TArray<TArray<IAccountBlock>>);
var
  vIndex: Integer;
begin
  SetLength(ParaSnapshotBlocks, Length(ParaChunks));
  SetLength(ParaAccountBlocksList, Length(ParaChunks));
  for vIndex := 0 to High(ParaChunks) do
  begin
    ParaSnapshotBlocks[vIndex] := ParaChunks[vIndex].SnapshotBlock;
    ParaAccountBlocksList[vIndex] := ParaChunks[vIndex].AccountBlocks;
  end;
end;

function TEventManager.TriggerInsertAbs(ParaEventType: Byte; const ParaVmAccountBlocks: TArray<IVmAccountBlock>): string;
var
  vListener: IEventListener;
  vErr: string;
begin
  Result := '';
  mMutex.Enter;
  try
    if mListenerList.Count = 0 then
    begin
      Exit;
    end;

    case ParaEventType of
      ConstPrepareInsertAbsEvent:
        begin
          for vListener in mListenerList do
          begin
            vErr := vListener.PrepareInsertAccountBlocks(ParaVmAccountBlocks);
            if vErr <> '' then
            begin
              Result := vErr;
              Exit;
            end;
          end;
        end;
      ConstInsertAbsEvent:
        begin
          for vListener in mListenerList do
          begin
            vErr := vListener.InsertAccountBlocks(ParaVmAccountBlocks);
            if vErr <> '' then
            begin
              mChain.FLog.Error('Insert Account Block trigger fail', 'err', vErr);
            end;
          end;
        end;
    end;
  finally
    mMutex.Leave;
  end;
end;

function TEventManager.TriggerDeleteAbs(ParaEventType: Byte; const ParaAccountBlocks: TArray<IAccountBlock>): string;
var
  vListener: IEventListener;
  vErr: string;
begin
  Result := '';
  mMutex.Enter;
  try
    if mListenerList.Count = 0 then
    begin
      Exit;
    end;

    case ParaEventType of
      ConstPrepareDeleteAbsEvent:
        begin
          for vListener in mListenerList do
          begin
            vErr := vListener.PrepareDeleteAccountBlocks(ParaAccountBlocks);
            if vErr <> '' then
            begin
              Result := vErr;
              Exit;
            end;
          end;
        end;
      ConstDeleteAbsEvent:
        begin
          for vListener in mListenerList do
          begin
            vErr := vListener.DeleteAccountBlocks(ParaAccountBlocks);
            if vErr <> '' then
            begin
              mChain.FLog.Error('Delete Account Block trigger fail', 'err', vErr);
            end;
          end;
        end;
    end;
  finally
    mMutex.Leave;
  end;
end;

function TEventManager.TriggerInsertSbs(ParaEventType: Byte; const ParaChunks: TArray<ISnapshotChunk>): string;
var
  vListener: IEventListener;
  vSnapshotBlocks: TArray<ISnapshotBlock>;
  vAccountBlocksList: TArray<TArray<IAccountBlock>>;
  vErr: string;
begin
  Result := '';
  mMutex.Enter;
  try
    if mListenerList.Count = 0 then
    begin
      Exit;
    end;

    case ParaEventType of
      ConstPrepareInsertSbsEvent:
        begin
          for vListener in mListenerList do
          begin
            vErr := vListener.PrepareInsertSnapshotBlocks(ParaChunks);
            if vErr <> '' then
            begin
              Result := vErr;
              Exit;
            end;
          end;
          SplitChunks(ParaChunks, vSnapshotBlocks, vAccountBlocksList);
        end;
      ConstInsertSbsEvent:
        begin
          for vListener in mListenerList do
          begin
            vListener.InsertSnapshotBlocks(ParaChunks);
          end;
          SplitChunks(ParaChunks, vSnapshotBlocks, vAccountBlocksList);
        end;
    end;
  finally
    mMutex.Leave;
  end;
end;

function TEventManager.TriggerDeleteSbs(ParaEventType: Byte; const ParaChunks: TArray<ISnapshotChunk>): string;
var
  vListener: IEventListener;
  vSnapshotBlocks: TArray<ISnapshotBlock>;
  vAccountBlocksList: TArray<TArray<IAccountBlock>>;
  vErr: string;
begin
  Result := '';
  mMutex.Enter;
  try
    if mListenerList.Count = 0 then
    begin
      Exit;
    end;

    case ParaEventType of
      ConstPrepareDeleteSbsEvent:
        begin
          for vListener in mListenerList do
          begin
            vErr := vListener.PrepareDeleteSnapshotBlocks(ParaChunks);
            if vErr <> '' then
            begin
              Result := vErr;
              Exit;
            end;
          end;
          SplitChunks(ParaChunks, vSnapshotBlocks, vAccountBlocksList);
        end;
      ConstDeleteSbsEvent:
        begin
          for vListener in mListenerList do
          begin
            vListener.DeleteSnapshotBlocks(ParaChunks);
          end;
          SplitChunks(ParaChunks, vSnapshotBlocks, vAccountBlocksList);
        end;
    end;
  finally
    mMutex.Leave;
  end;
end;

procedure TEventManager.Register(ParaListener: IEventListener);
begin
  mMutex.Enter;
  try
    mListenerList.Add(ParaListener);
  finally
    mMutex.Leave;
  end;
end;

procedure TEventManager.UnRegister(ParaListener: IEventListener);
var
  vIndex: Integer;
begin
  mMutex.Enter;
  try
    for vIndex := 0 to mListenerList.Count - 1 do
    begin
      if mListenerList[vIndex] = ParaListener then
      begin
        mListenerList.Delete(vIndex);
        Break;
      end;
    end;
  finally
    mMutex.Leave;
  end;
end;

{ TChainHelper }

procedure TChainHelper.Register(ParaListener: IEventListener);
begin
  Self.FEM.Register(ParaListener);
end;

procedure TChainHelper.UnRegister(ParaListener: IEventListener);
begin
  Self.FEM.UnRegister(ParaListener);
end;

end.