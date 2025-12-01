unit Common.Config.Producer;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  Common.Types;

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
  TProducer = class
  private
    mProducer: boolean;
    mCoinbase: string;
    mEntropyStorePath: string;
    mCoinbaseAddress: TAddress;
    mIndex: cardinal;
    mVirtualSnapshotVerifier: boolean;
    procedure ParseCoinbase(const ParaCoinbaseCfg: string; out ParaAddr: TAddress; out ParaIndex: cardinal);
    procedure Reset;
  public
    constructor Create;
    destructor Destroy; override;

    [JsonName('Producer')]
    property Producer: boolean read mProducer write mProducer;
    [JsonName('Coinbase')]
    property Coinbase: string read mCoinbase write mCoinbase;
    [JsonName('EntropyStorePath')]
    property EntropyStorePath: string read mEntropyStorePath write mEntropyStorePath;
    [JsonName('VirtualSnapshotVerifier')]
    property VirtualSnapshotVerifier: boolean read mVirtualSnapshotVerifier write mVirtualSnapshotVerifier;

    function IsMine: boolean;
    function GetCoinbase: TAddress;
    function GetIndex: cardinal;
    procedure Parse;
  end;

implementation

uses
  System.StrUtils,
  Common.HexUtil;

{ TProducer }

constructor TProducer.Create;
begin
  inherited Create;
  Reset;
end;

destructor TProducer.Destroy;
begin
  inherited Destroy;
end;

procedure TProducer.Reset;
begin
  mProducer := false;
  mCoinbase := '';
  mEntropyStorePath := '';
  mCoinbaseAddress := nil;
  mIndex := 0;
  mVirtualSnapshotVerifier := false;
end;

function TProducer.IsMine: boolean;
begin
  Result := mProducer and (mCoinbase <> '');
end;

function TProducer.GetCoinbase: TAddress;
begin
  Result := mCoinbaseAddress;
end;

function TProducer.GetIndex: cardinal;
begin
  Result := mIndex;
end;

procedure TProducer.Parse;
begin
  if mCoinbase <> '' then
  begin
    ParseCoinbase(mCoinbase, mCoinbaseAddress, mIndex);
  end;
end;

procedure TProducer.ParseCoinbase(const ParaCoinbaseCfg: string; out ParaAddr: TAddress; out ParaIndex: cardinal);
var
  vSplits: TStringDynArray;
  vI: integer;
begin
  ParaAddr := nil;
  ParaIndex := 0;

  vSplits := ParaCoinbaseCfg.Split([':']);
  if Length(vSplits) <> 2 then
  begin
    raise Exception.Create('Invalid Coinbase format: expected "index:address"');
  end;

  if not TryStrToInt(vSplits[0], vI) then
  begin
    raise Exception.Create('Invalid Coinbase index format');
  end;
  ParaIndex := cardinal(vI);

  try
    ParaAddr := THexUtil.HexToAddress(vSplits[1]);
  except
    on E: Exception do
    begin
      raise Exception.Create('Invalid Coinbase address format: ' + E.Message);
    end;
  end;
end;

end.
