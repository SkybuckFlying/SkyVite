unit Vm.Memory;

interface

uses
  System.SysUtils System.Classes System.Math.BigInteger,
  Vite.Common.Helper Vite.Vm.Util,
  VM.Contract,
  VM.Contract.Test,
  VM.Contracts.Dex.Fund.Test,
  VM.Contracts.Dex.Trade.Test,
  VM.Contracts.Test,
  VM.Database.Memory.Test,
  VM.Database.Test,
  VM.Destination,
  VM.Destination.Test,
  VM.Gas.Table,
  VM.Gas.Table.Test,
  VM.Instructions,
  VM.Instructions.Test,
  VM.Interpreter,
  VM.Jump.Table,
  VM.Memory.Table,
  VM.Memory.Test,
  VM.Mock.DB,
  VM.Opcodes,
  VM.Params,
  VM.Stack,
  VM.Stack.Table,
  VM.Stack.Test,
  VM.VM,
  VM.VM.Run.Test,
  VM.VM.Test;

type
  IMemory = interface
    ['{2A9C436D-3257-4B71-B274-A03658A1E395}']
    procedure Resize(Size: UInt64);
    function GetLen: Integer;
    function Get(Offset, Size: Int64): TBytes;
    function GetPtr(Offset, Size: Int64): TBytes;
    procedure Set(Offset, Size: UInt64; Value: TBytes);
    procedure Set32(Offset: UInt64; Val: TBigInteger);
    function Print: string;
    function GetLastGasCost: UInt64;
    procedure SetLastGasCost(Value: UInt64);
  end;

  TMemory = class(TInterfacedObject, IMemory)
  private
    FStore: TBytes;
    FLastGasCost: UInt64;
    function GetLastGasCost: UInt64;
    procedure SetLastGasCost(Value: UInt64);
  public
    constructor Create;
    procedure Resize(Size: UInt64);
    function GetLen: Integer;
    function Get(Offset, Size: Int64): TBytes;
    function GetPtr(Offset, Size: Int64): TBytes;
    procedure Set(Offset, Size: UInt64; Value: TBytes);
    procedure Set32(Offset: UInt64; Val: TBigInteger);
    function Print: string;
  end;

function NewMemory: IMemory;

implementation

uses
  System.SysUtils;

{ TMemory }

constructor TMemory.Create;
begin
  // FStore is initialized to nil (empty dynamic array)
end;

procedure TMemory.Resize(Size: UInt64);
begin
  if GetLen < Size then
    SetLength(FStore, Size);
end;

function TMemory.GetLen: Integer;
begin
  Result := Length(FStore);
end;

function TMemory.Get(Offset, Size: Int64): TBytes;
begin
  if Size = 0 then
  begin
    Result := nil;
    Exit;
  end;

  if GetLen > Offset then
  begin
    Result := Copy(FStore, Offset, Size);
  end
  else
    Result := nil;
end;

function TMemory.GetPtr(Offset, Size: Int64): TBytes;
begin
  if Size = 0 then
  begin
    Result := nil;
    Exit;
  end;

  if GetLen > Offset then
    Result := Copy(FStore, Offset, Size)
  else
    Result := nil;
end;

procedure TMemory.Set(Offset, Size: UInt64; Value: TBytes);
begin
  if Size > 0 then
  begin
    if Offset + Size > GetLen then
      raise Exception.Create('invalid memory: store empty');
    System.Move(Value[0], FStore[Offset], Size);
  end;
end;

procedure TMemory.Set32(Offset: UInt64; Val: TBigInteger);
var
  valBytes: TBytes;
  i: Integer;
begin
  if Offset + 32 > GetLen then
    raise Exception.Create('invalid memory: store empty');

  // Zero the memory area
  for i := 0 to 31 do
    FStore[Offset + i] := 0;

  // Fill in relevant bits
  valBytes := Val.ToBytes;
  if Length(valBytes) > 0 then
    System.Move(valBytes[0], FStore[Offset + 32 - Length(valBytes)], Length(valBytes));
end;

function TMemory.Print: string;
var
  Addr, I: Integer;
  WordSize: Integer;
  S: TStringBuilder;

  function BytesToHex(const B: TBytes): string;
  var
    J: Integer;
  begin
    Result := '';
    for J := 0 to Length(B) - 1 do
      Result := Result + System.SysUtils.Format('%.2x', [B[J]]);
  end;

begin
  Result := '';
  if GetLen = 0 then
    Exit;

  WordSize := 32; // from helper.WordSize

  if GetLen < 200 then
  begin
    S := TStringBuilder.Create;
    try
      Addr := 0;
      I := 0;
      while I + WordSize <= GetLen do
      begin
        if S.Length > 0 then
          S.Append(', ');
        S.Append(IntToHex(Addr, 0));
        S.Append('=>');
        S.Append(BytesToHex(Copy(FStore, I, WordSize)));

        Inc(Addr);
        I := I + WordSize;
      end;
      Result := S.ToString;
    finally
      S.Free;
    end;
  end
  else
    Result := 'omitted';
end;

function TMemory.GetLastGasCost: UInt64;
begin
  Result := FLastGasCost;
end;

procedure TMemory.SetLastGasCost(Value: UInt64);
begin
  FLastGasCost := Value;
end;

function NewMemory: IMemory;
begin
  Result := TMemory.Create;
end;

end.
