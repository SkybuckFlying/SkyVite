unit Ledger.Chain.Index.Interface;

interface

uses
  System.SysUtils,
  Common.Types,
<<<<<<< HEAD
  Interfaces.Core;

type
  TIterateContractsFunc = reference to function(const ParaAddr: TAddress; const ParaMeta: IContractMeta; const ParaErr: Exception): Boolean;

  IChain = interface
    ['{B4D1E2C3-5A7B-4D9E-8A1D-3F4E7E2D1A8C}']
    procedure IterateContracts(ParaIterateFunc: TIterateContractsFunc);
=======
  Interfaces.Core.ContractMeta;

type
  TIterateContractsFunc = reference to function(addr: TAddress; meta: ^TContractMeta; err: Exception): boolean;

  IChain = interface
    ['{B4E7F8B8-3A7A-4C6D-8D3D-0E8E8D8D8D8D}']
    procedure IterateContracts(iterateFunc: TIterateContractsFunc);
>>>>>>> origin/AI0002
  end;

implementation

end.
