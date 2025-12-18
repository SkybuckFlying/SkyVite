unit VM.ABI.Event.Test;

interface

procedure RunEventTests;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.BigInt, System.Rtti,
  GoVite.Types, GoVite.VM, VM.ABI.ABI, VM.ABI.Event, // Assumed units
  DUnitX.TestFramework;

const
  JSON_EVENT_TRANSFER =
    '{' +
    '  "anonymous": false,' +
    '  "inputs": [' +
    '    {' +
    '      "indexed": true, "name": "from", "type": "address"' +
    '    }, {' +
    '      "indexed": true, "name": "to", "type": "address"' +
    '    }, {' +
    '      "indexed": false, "name": "value", "type": "uint256"' +
    '  }],' +
    '  "name": "Transfer",' +
    '  "type": "event"' +
    '}';

procedure TestEventId;
const
  DEFINITION = '[' +
    '{ "type" : "event", "name" : "balance", "inputs": [{ "name" : "in", "type": "uint256" }] },' +
    '{ "type" : "event", "name" : "check", "inputs": [{ "name": "t", "type": "address" }, { "name": "b", "type": "uint256" }] }' +
    ']';
var
  ABI: TAbiContract;
  Expectations: TDictionary<string, THash>;
  Event: TEvent;
begin
  ABI := TAbiContract.Create(DEFINITION);
  Expectations := TDictionary<string, THash>.Create;
  try
    Expectations.Add('balance', THash.DataHash(TEncoding.UTF8.GetBytes('balance(uint256)')));
    Expectations.Add('check', THash.DataHash(TEncoding.UTF8.GetBytes('check(address,uint256)')));

    for Event in ABI.Events.Values do
    begin
      Assert.AreEqual(Expectations[Event.Name].ToString, Event.ID.ToString, 'Event ID mismatch for ' + Event.Name);
    end;
  finally
    ABI.Free;
    Expectations.Free;
  end;
end;

procedure TestEventUnpack;
type
  TReceivedEvent = record
    Sender: TAddress;
    Amount: TBigInteger;
    Memo: TBytes;
  end;
const
  ABI_JSON = '[{"anonymous":false,"inputs":[{"indexed":true,"name":"sender","type":"address"},{"indexed":false,"name":"amount","type":"uint256"},{"indexed":true,"name":"memo","type":"bytes"}],"name":"received","type":"event"}]';
var
  ABI: TAbiContract;
  Data: TBytes;
  Topics: TArray<THash>;
  EventValue: TValue;
  EventRec: TReceivedEvent;
  ExpectedAmount: TBigInteger;
begin
  ABI := TAbiContract.Create(ABI_JSON);
  try
    // Mock packed data. In a real scenario, this would come from a log.
    ExpectedAmount := 12345;
    Data := TArgument.PackValues(False, [TValue.From<TBigInteger>(ExpectedAmount)]);

    // Create mock topics for the indexed fields
    SetLength(Topics, 3);
    Topics[0] := ABI.Events['received'].ID; // Event signature topic
    Topics[1] := THash.FromAddress(TAddress.FromHexString('vite_376c47978271565f56deb45495afa69e59c16ab29386256f6e'));
    Topics[2] := THash.DataHash(TBytes.Create($58)); // 'X' for memo

    // Unpack non-indexed data
    EventValue := TValue.From<TReceivedEvent>;
    ABI.UnpackEvent(EventValue, 'received', Data);
    EventRec := EventValue.AsType<TReceivedEvent>;

    // We can't get indexed values from UnpackEvent, but we can from DirectUnpackEvent
    var UnpackedResult := ABI.DirectUnpackEvent(Topics, Data);
    var UnpackedValues := UnpackedResult.Item2;
    
    // Assert non-indexed value from UnpackEvent
    Assert.AreEqual(0, EventRec.Amount.CompareTo(ExpectedAmount), 'Unpacked amount mismatch');

    // Assert all values from DirectUnpackEvent
    Assert.AreEqual('event received(address indexed sender, uint256 amount, bytes indexed memo)', UnpackedResult.Item1);
    Assert.AreEqual(3, Length(UnpackedValues));
    Assert.AreEqual('vite_376c47978271565f56deb45495afa69e59c16ab29386256f6e', UnpackedValues[0].AsType<TAddress>.ToString);
    Assert.AreEqual(0, UnpackedValues[1].AsType<TBigInteger>.CompareTo(ExpectedAmount));
    Assert.AreEqual('X', TEncoding.UTF8.GetString(UnpackedValues[2].AsType<TBytes>));

  finally
    ABI.Free;
  end;
end;

procedure RunEventTests;
begin
  TestEventId;
  TestEventUnpack;
end;

end.
