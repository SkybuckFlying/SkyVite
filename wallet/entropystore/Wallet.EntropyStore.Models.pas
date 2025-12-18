unit Wallet.EntropyStore.Models;

interface

uses
  System.JSON,
  Wallet.EntropyStore.Crypto.Store,
  Wallet.EntropyStore.Crypto.Store.Test,
  Wallet.EntropyStore.Manager,
  Wallet.EntropyStore.Manager.Test,
  Wallet.EntropyStore.Utils;

const
  CryptoStoreVersion = 1;

type
  TScryptParams = class
  private
    mN: Integer;
    mR: Integer;
    mP: Integer;
    mKeyLen: Integer;
    mSalt: string;
  public
    property N: Integer read mN write mN;
    property R: Integer read mR write mR;
    property P: Integer read mP write mP;
    property KeyLen: Integer read mKeyLen write mKeyLen;
    property Salt: string read mSalt write mSalt;
    function ToJSONObject: TJSONObject;
  end;

  TCryptoJSON = class
  private
    mCipherName: string;
    mCipherText: string;
    mNonce: string;
    mKDF: string;
    mScryptParams: TScryptParams;
  public
    constructor Create;
    destructor Destroy; override;
    property CipherName: string read mCipherName write mCipherName;
    property CipherText: string read mCipherText write mCipherText;
    property Nonce: string read mNonce write mNonce;
    property KDF: string read mKDF write mKDF;
    property ScryptParams: TScryptParams read mScryptParams write mScryptParams;
    function ToJSONObject: TJSONObject;
  end;

  TEntropyJSON = class
  private
    mPrimaryAddress: string;
    mCrypto: TCryptoJSON;
    mVersion: Integer;
    mTimestamp: Int64;
  public
    constructor Create;
    destructor Destroy; override;
    property PrimaryAddress: string read mPrimaryAddress write mPrimaryAddress;
    property Crypto: TCryptoJSON read mCrypto write mCrypto;
    property Version: Integer read mVersion write mVersion;
    property Timestamp: Int64 read mTimestamp write mTimestamp;
    function ToJSONObject: TJSONObject;
  end;

implementation

{ TScryptParams }

function TScryptParams.ToJSONObject: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('n', TJSONNumber.Create(mN));
  Result.AddPair('r', TJSONNumber.Create(mR));
  Result.AddPair('p', TJSONNumber.Create(mP));
  Result.AddPair('keylen', TJSONNumber.Create(mKeyLen));
  Result.AddPair('salt', TJSONString.Create(mSalt));
end;

{ TCryptoJSON }

constructor TCryptoJSON.Create;
begin
  inherited;
  mScryptParams := TScryptParams.Create;
end;

destructor TCryptoJSON.Destroy;
begin
  mScryptParams.Free;
  inherited;
end;

function TCryptoJSON.ToJSONObject: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('ciphername', TJSONString.Create(mCipherName));
  Result.AddPair('ciphertext', TJSONString.Create(mCipherText));
  Result.AddPair('nonce', TJSONString.Create(mNonce));
  Result.AddPair('kdf', TJSONString.Create(mKDF));
  Result.AddPair('scryptparams', mScryptParams.ToJSONObject);
end;

{ TEntropyJSON }

constructor TEntropyJSON.Create;
begin
  inherited;
  mCrypto := TCryptoJSON.Create;
end;

destructor TEntropyJSON.Destroy;
begin
  mCrypto.Free;
  inherited;
end;

function TEntropyJSON.ToJSONObject: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('primaryAddress', TJSONString.Create(mPrimaryAddress));
  Result.AddPair('crypto', mCrypto.ToJSONObject);
  Result.AddPair('seedstoreversion', TJSONNumber.Create(mVersion));
  Result.AddPair('timestamp', TJSONNumber.Create(mTimestamp));
end;

end.
