unit Ledger.Consensus.RollbackProof;

interface

uses
  System.SysUtils,
  System.Classes,
  Common.Types,
  V2.Interfaces.Core,
  Ledger.Consensus.ChainRw;

type
  IRollbackProof = interface
    ['{E3B8B3B3-3B3B-4B3B-8B3B-4B3B3B3B3B46}']
    function Proof(const ParaHash: THash; ParaT: TDateTime): TTuple<ISnapshotBlock, Exception>;
    function ProofEmpty(const ParaStime, ParaEtime: TDateTime): TTuple<Boolean, Exception>;
    function ProofHash(const ParaTime: TDateTime): TTuple<THash, Exception>;
  end;

  TRollbackProof = class(TInterfacedObject, IRollbackProof)
  private
    FRw: IChain;
  public
    constructor Create(ParaRw: IChain);
    function Proof(const ParaHash: THash; ParaT: TDateTime): TTuple<ISnapshotBlock, Exception>;
    function ProofEmpty(const ParaStime, ParaEtime: TDateTime): TTuple<Boolean, Exception>;
    function ProofHash(const ParaTime: TDateTime): TTuple<THash, Exception>;
  end;

function NewRollbackProof(ParaRw: IChain): IRollbackProof;

implementation

uses
  System.DateUtils;

{ TRollbackProof }

constructor TRollbackProof.Create(ParaRw: IChain);
begin
  FRw := ParaRw;
end;

function TRollbackProof.Proof(const ParaHash: THash; ParaT: TDateTime): TTuple<ISnapshotBlock, Exception>;
var
  Block: ISnapshotBlock;
  Err: Exception;
begin
  TValue.Make(FRw.GetSnapshotHeaderBeforeTime(ParaT), Block, Err);
  if Err <> nil then
    Exit(TTuple<ISnapshotBlock, Exception>.Create(nil, Err));
  if Block = nil then
    Exit(TTuple<ISnapshotBlock, Exception>.Create(nil, Exception.Create('before time[' + DateTimeToStr(ParaT) + '] block not exist')));
  if Block.Hash <> ParaHash then
    Exit(TTuple<ISnapshotBlock, Exception>.Create(nil, Exception.Create(Format('block[%s][%s] proof fail.', [ParaHash.ToString, Block.Hash.ToString]))));
  Result := TTuple<ISnapshotBlock, Exception>.Create(Block, nil);
end;

function TRollbackProof.ProofEmpty(const ParaStime, ParaEtime: TDateTime): TTuple<Boolean, Exception>;
var
  Block: ISnapshotBlock;
  Err: Exception;
begin
  TValue.Make(FRw.GetSnapshotHeaderBeforeTime(ParaEtime), Block, Err);
  if Err <> nil then
    Exit(TTuple<Boolean, Exception>.Create(False, Err));
  if Block = nil then
    Exit(TTuple<Boolean, Exception>.Create(False, Exception.Create(Format('before time[%s] block not exist', [DateTimeToStr(ParaEtime)]))));
  if ParaEtime <= Block.Timestamp then
    Exit(TTuple<Boolean, Exception>.Create(False, Exception.Create(Format('GetSnapshotHeaderBeforeTime fail. [%s]-[%s]', [DateTimeToStr(ParaEtime), DateTimeToStr(Block.Timestamp)]))));
  Result := TTuple<Boolean, Exception>.Create(Block.Timestamp < ParaStime, nil);
end;

function TRollbackProof.ProofHash(const ParaTime: TDateTime): TTuple<THash, Exception>;
var
  Block: ISnapshotBlock;
  Err: Exception;
begin
  TValue.Make(FRw.GetSnapshotHeaderBeforeTime(ParaTime), Block, Err);
  if Err <> nil then
    Exit(TTuple<THash, Exception>.Create(Default(THash), Err));
  if Block = nil then
    Exit(TTuple<THash, Exception>.Create(Default(THash), Exception.Create('before time[' + DateTimeToStr(ParaTime) + '] block not exist')));
  Result := TTuple<THash, Exception>.Create(Block.Hash, nil);
end;

function NewRollbackProof(ParaRw: IChain): IRollbackProof;
begin
  Result := TRollbackProof.Create(ParaRw);
end;

end.