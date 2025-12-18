unit VM.ABI.ABI.Test;

interface

procedure RunAbiTests;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.BigInt, System.StrUtils,
  GoVite.Types, GoVite.VM, VM.ABI.ABI, VM.ABI.Argument, VM.ABI.Method, VM.ABI.Event,
  DUnitX.TestFramework;

const
  JSON_DATA =
    '['+
    '{ "type" : "constructor", "inputs" : [ { "name" : "owner", "type" : "address" } ] },' +
    '{ "type" : "function", "name" : "balance", "constant" : true },' +
    '{ "type" : "function", "name" : "send", "constant" : false, "inputs" : [ { "name" : "amount", "type" : "uint256" } ] },' +
    '{ "type" : "event", "name" : "Transfer", "anonymous" : false, "inputs" : [ { "indexed" : true, "name" : "from", "type" : "address" }, { "indexed" : true, "name" : "to", "type" : "address" }, { "name" : "value", "type" : "uint256" } ] }' +
    ']';

procedure TestReader;
var
  ABI: TAbiContract;
  Method: TMethod;
  Event: TEvent;
begin
  ABI := TAbiContract.Create(JSON_DATA);
  try
    // Test Constructor
    Assert.AreEqual(1, Length(ABI.Constructor.Inputs), 'Constructor should have 1 input');
    Assert.AreEqual('owner', ABI.Constructor.Inputs[0].Name, 'Constructor input name mismatch');

    // Test Methods
    Assert.AreEqual(2, ABI.Methods.Count, 'Should have 2 methods');
    Assert.IsTrue(ABI.Methods.TryGetValue('balance', Method), 'Method "balance" not found');
    Assert.IsTrue(ABI.Methods.TryGetValue('send', Method), 'Method "send" not found');
    Assert.AreEqual(1, Length(Method.Inputs), 'Method "send" should have 1 input');
    Assert.AreEqual('amount', Method.Inputs[0].Name, 'Method "send" input name mismatch');

    // Test Events
    Assert.AreEqual(1, ABI.Events.Count, 'Should have 1 event');
    Assert.IsTrue(ABI.Events.TryGetValue('Transfer', Event), 'Event "Transfer" not found');
    Assert.AreEqual(3, Length(Event.Inputs), 'Event "Transfer" should have 3 inputs');
    Assert.IsTrue(Event.Inputs[0].Indexed, 'Event "Transfer" input 0 should be indexed');
    Assert.IsTrue(Event.Inputs[1].Indexed, 'Event "Transfer" input 1 should be indexed');
    Assert.IsFalse(Event.Inputs[2].Indexed, 'Event "Transfer" input 2 should not be indexed');

  finally
    ABI.Free;
  end;
end;

procedure TestPackMethod;
const
  DEFINITION = '[{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"isBar","type":"function"}]';
var
  ABI: TAbiContract;
  Addr: TAddress;
  Packed: TBytes;
  Expected: string;
begin
  ABI := TAbiContract.Create(DEFINITION);
  try
    Addr := TAddress.FromBytes(TBytes.Create($01));
    Packed := ABI.PackMethod('isBar', [TValue.From<TAddress>(Addr)]);

    Expected := '65591c8e0000000000000000000000000000000000000000000000000000000000000001';
    Assert.AreEqual(Expected, THex.Encode(Packed), 'Packed data mismatch');
  finally
    ABI.Free;
  end;
end;

procedure TestUnpackEvent;
const
  ABI_JSON = '[{"anonymous":false,"inputs":[{"indexed":false,"name":"sender","type":"address"},{"indexed":false,"name":"amount","type":"uint256"},{"indexed":false,"name":"memo","type":"bytes"}],"name":"received","type":"event"}]';
type
  TReceivedEvent = record
    Sender: TAddress;
    Amount: TBigInteger;
    Memo: TBytes;
  end;
var
  ABI: TAbiContract;
  HexData: string;
  Data: TBytes;
  EventValue: TValue;
  EventRec: TReceivedEvent;
begin
  ABI := TAbiContract.Create(ABI_JSON);
  try
    HexData := '000000000000000000000000376c47978271565f56deb45495afa69e59c16ab2' +
               '0000000000000000000000000000000000000000000000000000000000000001' +
               '0000000000000000000000000000000000000000000000000000000000000060' +
               '0000000000000000000000000000000000000000000000000000000000000001' +
               '58'; // Hex for 'X'
    Data := THex.Decode(HexData);

    EventValue := TValue.From<TReceivedEvent>;
    ABI.UnpackEvent(EventValue, 'received', Data);
    EventRec := EventValue.AsType<TReceivedEvent>;

    Assert.AreEqual('vite_376c47978271565f56deb45495afa69e59c16ab29386256f6e', EventRec.Sender.ToString, 'Unpacked sender address mismatch');
    Assert.AreEqual(0, EventRec.Amount.CompareTo(1), 'Unpacked amount mismatch');
    Assert.AreEqual('X', TEncoding.UTF8.GetString(EventRec.Memo), 'Unpacked memo mismatch');

  finally
    ABI.Free;
  end;
end;

procedure RunAbiTests;
begin
  TestReader;
  TestPackMethod;
  TestUnpackEvent;
  // Other tests from abi_test.go would be added here...
end;

end.
