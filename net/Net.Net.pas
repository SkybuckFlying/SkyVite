unit Net;

interface

uses
  System.SysUtils,
  Common.Config,
  Ledger.Chain,
  Ledger.Verifier,
  Ledger.Consensus,
  Ledger.Pool;

type
  INet = interface(IInterface)
    ['{9D0E1F2A-3B4C-5D6E-7F8A-9B0C1D2E3F4A}']
    procedure Start;
    procedure Stop;
  end;

  TNet = class(TInterfacedObject, INet)
  public
    class function Create(ParaNetConfig: TNetConfig; ParaChain: IChain; ParaVerifier: IVerifier; ParaConsensus: IConsensus; ParaPool: IBlockPool): INet;
    procedure Start;
    procedure Stop;
  end;

implementation

{ TNet }

class function TNet.Create(ParaNetConfig: TNetConfig; ParaChain: IChain; ParaVerifier: IVerifier; ParaConsensus: IConsensus; ParaPool: IBlockPool): INet;
begin
  // not implemented
  Result := nil;
end;

procedure TNet.Start;
begin
  // not implemented
end;

procedure TNet.Stop;
begin
  // not implemented
end;

end.