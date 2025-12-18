unit Wallet.EntropyStore.Utils;

interface

uses
  Classes,
  GoToDelphi.Helpers.TBytes,
  SysUtils,
  Vite.Common.Types,
  Vite.Log15,
  Wallet.EntropyStore.Crypto.Store,
  Wallet.EntropyStore.Crypto.Store.Test,
  Wallet.EntropyStore.Manager,
  Wallet.EntropyStore.Manager.Test,
  Wallet.EntropyStore.Models;

type
  TWalletUtils = class
  public
    class function IsMayValidEntropystoreFile(const ParaPath: string; out ParaAddr: TAddress): Boolean; static;
    class function FullKeyFileName(const ParaKeysDirPath: string; const ParaKeyAddr: TAddress): string; static;
    class function ReadAndFixAddressFile(const ParaPath: string; out ParaAddr: TAddress; out ParaKeyJSON: TEntropyJSON): Boolean; static;
    class function AddressFromKeyPath(const ParaKeyFile: string): TAddress; static;
    class function FullKeyFileNameV0(const ParaKeysDirPath: string; const ParaKeyAddr: TAddress): string; static;
    class function AddressFromKeyPathV0(const ParaKeyFile: string): TAddress; static;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  System.NetEncoding;

class function TWalletUtils.IsMayValidEntropystoreFile(const ParaPath: string; out ParaAddr: TAddress): Boolean;
var
  vFileInfo: TSearchRec;
  vBytes: TBytes;
  vK: TEntropyJSON;
  vCipherData, vNonce, vSalt: TBytes;
begin
  Result := False;
  if TFile.GetAttributes(ParaPath) * [faDirectory] <> [] then
  begin
    Exit;
  end;

  if TFile.GetSize(ParaPath) > 2 * 1024 then
  begin
    Exit;
  end;

  vBytes := TFile.ReadAllBytes(ParaPath);
  try
    Result := TCryptoStore.ParseJson(vBytes, vK, ParaAddr, vCipherData, vNonce, vSalt);
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

class function TWalletUtils.FullKeyFileName(const ParaKeysDirPath: string; const ParaKeyAddr: TAddress): string;
begin
  Result := TPath.Combine(ParaKeysDirPath, ParaKeyAddr.ToHex);
end;

class function TWalletUtils.ReadAndFixAddressFile(const ParaPath: string; out ParaAddr: TAddress; out ParaKeyJSON: TEntropyJSON): Boolean;
var
  vLog: ILog15Logger;
  vBytes: TBytes;
  vCipherData, vNonce, vSalt: TBytes;
  vStandFileName: string;
begin
  vLog := TLog15Logger.New('method', 'wallet/keystore/utils/readAndFixAddressFile');
  Result := False;
  try
    vBytes := TFile.ReadAllBytes(ParaPath);
    if not TCryptoStore.ParseJson(vBytes, ParaKeyJSON, ParaAddr, vCipherData, vNonce, vSalt) then
    begin
      vLog.Error('Decode keystore file failed', 'path', ParaPath);
      Exit;
    end;

    vStandFileName := FullKeyFileName(TPath.GetDirectoryName(ParaPath), ParaAddr);
    if vStandFileName <> ParaPath then
    begin
      try
        TFile.Move(ParaPath, vStandFileName);
        vLog.Info('readAndFixAddressFile success');
      except
        on E: Exception do
        begin
          vLog.Error('readAndFixAddressFile', 'err', E.Message);
        end;
      end;
    end;
    Result := True;
  except
    on E: Exception do
    begin
      vLog.Error('Can not to open', 'path', ParaPath, 'err', E.Message);
    end;
  end;
end;

class function TWalletUtils.AddressFromKeyPath(const ParaKeyFile: string): TAddress;
var
  vFileName: string;
begin
  vFileName := TPath.GetFileName(ParaKeyFile);
  Result := TViteTypes.HexToAddress(vFileName);
end;

class function TWalletUtils.FullKeyFileNameV0(const ParaKeysDirPath: string; const ParaKeyAddr: TAddress): string;
begin
  Result := TPath.Combine(ParaKeysDirPath, '/v-i-t-e-' + TNetEncoding.Base16.EncodeBytesToString(ParaKeyAddr.Bytes));
end;

class function TWalletUtils.AddressFromKeyPathV0(const ParaKeyFile: string): TAddress;
var
  vFileName: string;
  vBytes: TBytes;
begin
  vFileName := TPath.GetFileName(ParaKeyFile);
  if not vFileName.StartsWith('v-i-t-e-') then
  begin
    raise Exception.CreateFmt('not valid key file name %v', [ParaKeyFile]);
  end;
  vBytes := TNetEncoding.Base16.Decode(vFileName.Substring(Length('v-i-t-e-')));
  if Length(vBytes) <> TViteAddress.AddressSize then
  begin
    raise Exception.CreateFmt('not valid key file name %v error', [ParaKeyFile]);
  end;
  Result := TViteTypes.BytesToAddress(vBytes);
end;

end.
