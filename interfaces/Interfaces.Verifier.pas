unit Interfaces.Verifier;

interface

uses
  SysUtils, Classes, Generics.Collections,
  Common.Types,
  Interfaces.Core;

type
  // ConsensusVerifier is the interface that can verify block consensus.
  IConsensusVerifier = interface(IInterface)
    ['{E1F6F6F6-6F6F-6F6F-BF6F-6F6F6F6F6F6F}']
    function VerifyAccountProducer(ParaBlock: IAccountBlock; out ParaError: Exception): Boolean;
    function VerifyABsProducer(ParaAbs: TDictionary<TGid, TArray<IAccountBlock>>; out ParaError: Exception): TArray<IAccountBlock>;
    function VerifySnapshotProducer(ParaBlock: ISnapshotBlock; out ParaError: Exception): Boolean;
  end;

implementation

end.
