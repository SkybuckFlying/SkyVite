unit VM.Contract;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Vite.Common.Types,
  Vite.Interfaces,
  Vite.Interfaces.Core,
  Vite.Log15,
  Vite.Vm.Util,
  VM.Destination,
  VM.Opcodes;

type
  IVM = interface; // Forward declaration

  IContract = interface
    ['{C3A2A8B7-0B4A-4E2D-8F1A-3B6C1E5D7F6A}']
    function GetOp(ParaN: UInt64): TOpCode;
    function GetByte(ParaN: UInt64): Byte;
    procedure SetCallCode(ParaAddr: TAddress; ParaCode: TBytes);
    function Run(ParaVm: IVM): TBytes;
    function GetJumpDests: TDestinations;
    function GetData: TBytes;
    function GetCode: TBytes;
    function GetCodeAddr: TAddress;
    function GetBlock: IAccountBlock;
    function GetDb: IVmDb;
    function GetSendBlock: IAccountBlock;
    function GetQuotaLeft: UInt64;
    procedure SetQuotaLeft(ParaValue: UInt64);
    function GetIntPool: IIntPool;
    function GetReturnData: TBytes;
    procedure SetReturnData(ParaValue: TBytes);
    function GetStorageModified: TDictionary<string, TObject>;
  end;

  TContract = class(TInterfacedObject, IContract)
  private
    mJumpDests: TDestinations;
    mData: TBytes;
    mCode: TBytes;
    mCodeAddr: TAddress;
    mBlock: IAccountBlock;
    mDb: IVmDb;
    mSendBlock: IAccountBlock;
    mQuotaLeft: UInt64;
    mIntPool: IIntPool;
    mReturnData: TBytes;
    mStorageModified: TDictionary<string, TObject>;
    function GetJumpDests: TDestinations;
    function GetData: TBytes;
    function GetCode: TBytes;
    function GetCodeAddr: TAddress;
    function GetBlock: IAccountBlock;
    function GetDb: IVmDb;
    function GetSendBlock: IAccountBlock;
    function GetQuotaLeft: UInt64;
    procedure SetQuotaLeft(ParaValue: UInt64);
    function GetIntPool: IIntPool;
    function GetReturnData: TBytes;
    procedure SetReturnData(ParaValue: TBytes);
    function GetStorageModified: TDictionary<string, TObject>;
  public
    constructor Create(ParaBlock: IAccountBlock; ParaDb: IVmDb; ParaSendBlock: IAccountBlock; ParaData: TBytes; ParaQuotaLeft: UInt64);
    destructor Destroy; override;
    function GetOp(ParaN: UInt64): TOpCode;
    function GetByte(ParaN: UInt64): Byte;
    procedure SetCallCode(ParaAddr: TAddress; ParaCode: TBytes);
    function Run(ParaVm: IVM): TBytes;
  end;

function NewContract(ParaBlock: IAccountBlock; ParaDb: IVmDb; ParaSendBlock: IAccountBlock; ParaData: TBytes; ParaQuotaLeft: UInt64): IContract;

var
  Logger: ILogger;

implementation

uses
  VM.Interpreter;

{ TContract }

constructor TContract.Create(ParaBlock: IAccountBlock; ParaDb: IVmDb; ParaSendBlock: IAccountBlock; ParaData: TBytes; ParaQuotaLeft: UInt64);
begin
  mBlock := ParaBlock;
  mDb := ParaDb;
  mSendBlock := ParaSendBlock;
  mData := ParaData;
  mQuotaLeft := ParaQuotaLeft;
  mJumpDests := TDestinations.Create;
  mStorageModified := TDictionary<string, TObject>.Create;
end;

destructor TContract.Destroy;
begin
  mJumpDests.Free;
  mStorageModified.Free;
  inherited;
end;

function TContract.GetOp(ParaN: UInt64): TOpCode;
begin
  Result := TOpCode(GetByte(ParaN));
end;

function TContract.GetByte(ParaN: UInt64): Byte;
begin
  if ParaN < Length(mCode) then
  begin
    Result := mCode[ParaN];
  end
  else
  begin
    Result := 0;
  end;
end;

procedure TContract.SetCallCode(ParaAddr: TAddress; ParaCode: TBytes);
begin
  mCode := ParaCode;
  mCodeAddr := ParaAddr;
end;

function TContract.Run(ParaVm: IVM): TBytes;
begin
  mIntPool := TPoolOfIntPools.Get;
  try
    Result := (ParaVm as TVm).Interpreter.RunLoop(ParaVm, Self);
  finally
    TPoolOfIntPools.Put(mIntPool);
    mIntPool := nil;
  end;
end;

function TContract.GetJumpDests: TDestinations;
begin
  Result := mJumpDests;
end;

function TContract.GetData: TBytes;
begin
  Result := mData;
end;

function TContract.GetCode: TBytes;
begin
  Result := mCode;
end;

function TContract.GetCodeAddr: TAddress;
begin
  Result := mCodeAddr;
end;

function TContract.GetBlock: IAccountBlock;
begin
  Result := mBlock;
end;

function TContract.GetDb: IVmDb;
begin
  Result := mDb;
end;

function TContract.GetSendBlock: IAccountBlock;
begin
  Result := mSendBlock;
end;

function TContract.GetQuotaLeft: UInt64;
begin
  Result := mQuotaLeft;
end;

procedure TContract.SetQuotaLeft(ParaValue: UInt64);
begin
  mQuotaLeft := ParaValue;
end;

function TContract.GetIntPool: IIntPool;
begin
  Result := mIntPool;
end;

function TContract.GetReturnData: TBytes;
begin
  Result := mReturnData;
end;

procedure TContract.SetReturnData(ParaValue: TBytes);
begin
  mReturnData := ParaValue;
end;

function TContract.GetStorageModified: TDictionary<string, TObject>;
begin
  Result := mStorageModified;
end;

function NewContract(ParaBlock: IAccountBlock; ParaDb: IVmDb; ParaSendBlock: IAccountBlock; ParaData: TBytes; ParaQuotaLeft: UInt64): IContract;
begin
  Result := TContract.Create(ParaBlock, ParaDb, ParaSendBlock, ParaData, ParaQuotaLeft);
end;

initialization
  Logger := TLogger.Create('type', '1', 'appkey', 'govite', 'group', 'msg', 'name', 'effectivemsg', 'metric', '1', 'class', 'vm');
end.
