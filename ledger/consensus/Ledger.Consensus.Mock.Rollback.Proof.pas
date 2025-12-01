unit consensus.mock_rollback_proof;

interface

uses
  System.SysUtils,
  System.Classes,
  Vite.Core,
  Vite.Types,
  consensus.rollback_proof;

type
  TMockRollbackProof = class(TInterfacedObject, IRollbackProof)
  public
    function Proof(const Arg0: THash; Arg1: TDateTime): TSnapshotBlock;
    function ProofEmpty(Arg0, Arg1: TDateTime): Boolean;
    function ProofHash(Arg0: TDateTime): THash;
  end;

implementation

{ TMockRollbackProof }

function TMockRollbackProof.Proof(const Arg0: THash; Arg1: TDateTime): TSnapshotBlock;
begin
  // Mock implementation
  Result := nil;
end;

function TMockRollbackProof.ProofEmpty(Arg0, Arg1: TDateTime): Boolean;
begin
  // Mock implementation
  Result := False;
end;

function TMockRollbackProof.ProofHash(Arg0: TDateTime): THash;
begin
  // Mock implementation
  Result := nil;
end;

end.
