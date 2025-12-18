unit Common.Config.Chain;

interface

uses
  Common.Config.Config,
  Common.Config.Genesis,
  Common.Config.Genesis.Json,
  Common.Config.Genesis.Mock.Json,
  Common.Config.Genesis.Test,
  Common.Config.Net,
  Common.Config.Node.Reward,
  Common.Config.Producer,
  Common.Config.Subscribe,
  Common.Config.Upgrade,
  Common.Config.VM,
  Common.Config.Wallet,
  Common.Types,
  System.Generics.Collections,
  System.SysUtils;

/*
 * Copyright 2019 The go-vite Authors
 * This file is part of the go-vite library.
 *
 * The go-vite library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The go-vite library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with the go-vite library. If not, see <http://www.gnu.org/licenses/>.
 */

type
  // TChain represents the chain configuration
  TChain = class
  private
    mLedgerGcRetain: UInt64;
    mGenesisFile: string;
    mLedgerGc: boolean;
    mOpenPlugins: boolean;
    mVmLogWhiteList: TArray<TAddress>;
    mVmLogAll: boolean;
    procedure Reset;
  public
    constructor Create;
    destructor Destroy; override;

    property LedgerGcRetain: UInt64 read mLedgerGcRetain write mLedgerGcRetain; // no use
    property GenesisFile: string read mGenesisFile write mGenesisFile; // genesis file path
    property LedgerGc: boolean read mLedgerGc write mLedgerGc; // open or close ledger garbage collector
    property OpenPlugins: boolean read mOpenPlugins write mOpenPlugins; // open or close chain plugins. eg, filter account blocks by token.
    property VmLogWhiteList: TArray<TAddress> read mVmLogWhiteList write mVmLogWhiteList; // contract address white list which save VM logs
    property VmLogAll: boolean read mVmLogAll write mVmLogAll; // save all VM logs, it will cost more disk space
  end;

implementation

{ TChain }

constructor TChain.Create;
begin
  inherited Create;
  Reset;
end;

destructor TChain.Destroy;
begin
  mVmLogWhiteList := nil;
  inherited Destroy;
end;

procedure TChain.Reset;
begin
  mLedgerGcRetain := 0;
  mGenesisFile := '';
  mLedgerGc := False;
  mOpenPlugins := False;
  SetLength(mVmLogWhiteList, 0);
  mVmLogAll := False;
end;

end.
