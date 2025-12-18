unit RPC_Json_Test;

interface

procedure RunJsonTest;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.TypInfo,
  System.Rtti,
  System.JSON,
  RPC, // Assuming TServer, TJSONCodec are here
  DUnitX.TestFramework; // Assuming a testing framework for Assert

type
  TTestService = class
  public
    function Add(A, B: Integer): Integer;
  end;

function TTestService.Add(A, B: Integer): Integer;
begin
  Result := A + B;
end;

procedure TestJSONRequestParsing;
var
  LServer: TServer;
  LService: TTestService;
  LRequestStream, LReplyStream: TStringStream;
  LReader: TStreamReader;
  LWriter: TStreamWriter;
  LCodec: TJSONCodec;
  LRequests: TArray<TRPCRequest>;
  LIsBatch: Boolean;
  LArgs: TArray<PTypeInfo>;
  LVals: TArray<TValue>;
  LId: Int64;
begin
  LServer := TServer.Create;
  LService := TTestService.Create;
  try
    LServer.RegisterName('calc', LService);

    LRequestStream := TStringStream.Create('{"id": 1234, "jsonrpc": "2.0", "method": "calc_add", "params": [11, 22]}');
    LReplyStream := TStringStream.Create('');
    try
      // Assuming TJSONCodec can be created from streams or reader/writers
      LReader := TStreamReader.Create(LRequestStream);
      LWriter := TStreamWriter.Create(LReplyStream);
      LCodec := TJSONCodec.Create(LReader, LWriter);
      try
        LRequests := LCodec.ReadRequestHeaders(LIsBatch);

        Assert.IsFalse(LIsBatch, 'Request should not be a batch');
        Assert.AreEqual(1, Length(LRequests), 'Expected 1 request');
        Assert.AreEqual('calc', LRequests[0].Service, 'Expected service "calc"');
        Assert.AreEqual('add', LRequests[0].Method, 'Expected method "add"');

        // Check ID
        Assert.IsTrue(LRequests[0].Id is TJSONNumber);
        LId := (LRequests[0].Id as TJSONNumber).AsInt64;
        Assert.AreEqual(1234, LId, 'Expected id 1234');

        // Check Params
        SetLength(LArgs, 2);
        LArgs[0] := TypeInfo(Integer);
        LArgs[1] := TypeInfo(Integer);

        LVals := LCodec.ParseRequestArguments(LArgs, LRequests[0].Params);

        Assert.AreEqual(2, Length(LVals), 'Expected 2 arguments');
        Assert.AreEqual(11, LVals[0].AsInteger, 'Expected first arg to be 11');
        Assert.AreEqual(22, LVals[1].AsInteger, 'Expected second arg to be 22');

      finally
        LCodec.Free;
      end;
    finally
      LRequestStream.Free;
      LReplyStream.Free;
    end;
  finally
    LService.Free;
    LServer.Free;
  end;
end;

procedure TestJSONRequestParamsParsing;
var
  LCodec: TJSONCodec;
  LParams: TJSONArray;
  LArgs: TArray<PTypeInfo>;
  LVals: TArray<TValue>;
  i: Integer;
begin
  LCodec := TJSONCodec.Create(nil, nil); // Create for parsing method only
  try
    // --- Valid Tests ---
    
    // Test case: `[]`, []reflect.Type{}, []reflect.Value{}
    LParams := TJSONArray.Create;
    SetLength(LArgs, 0);
    LVals := LCodec.ParseRequestArguments(LArgs, LParams);
    Assert.AreEqual(0, Length(LVals));
    LParams.Free;

    // Test case: `[1]`, []reflect.Type{intT}, []reflect.Value{intV}
    LParams := TJSONArray.Create;
    LParams.Add(1);
    SetLength(LArgs, 1);
    LArgs[0] := TypeInfo(Integer);
    LVals := LCodec.ParseRequestArguments(LArgs, LParams);
    Assert.AreEqual(1, Length(LVals));
    Assert.AreEqual(1, LVals[0].AsInteger);
    LParams.Free;

    // Test case: `[1,"abc"]`, []reflect.Type{intT, stringT}, []reflect.Value{intV, stringV}
    LParams := TJSONArray.Create;
    LParams.Add(1);
    LParams.Add('abc');
    SetLength(LArgs, 2);
    LArgs[0] := TypeInfo(Integer);
    LArgs[1] := TypeInfo(String);
    LVals := LCodec.ParseRequestArguments(LArgs, LParams);
    Assert.AreEqual(2, Length(LVals));
    Assert.AreEqual(1, LVals[0].AsInteger);
    Assert.AreEqual('abc', LVals[1].AsString);
    LParams.Free;
    
    // Test case for optional pointer: `[null]`, []reflect.Type{intPtrT}, []reflect.Value{intPtrV}}
    LParams := TJSONArray.Create;
    LParams.Add(TJSONNull.Create);
    SetLength(LArgs, 1);
    LArgs[0] := TypeInfo(Pointer); // Representing optional arg
    LVals := LCodec.ParseRequestArguments(LArgs, LParams);
    Assert.AreEqual(1, Length(LVals));
    Assert.IsTrue(LVals[0].IsNil);
    LParams.Free;

    // --- Invalid Tests ---
    
    // Test case: `[]`, []reflect.Type{intT}
    Assert.WillRaise(procedure
      begin
        LParams := TJSONArray.Create;
        SetLength(LArgs, 1);
        LArgs[0] := TypeInfo(Integer);
        LCodec.ParseRequestArguments(LArgs, LParams);
        LParams.Free;
      end, EJSONRPCError);
      
    // Test case: `[null]`, []reflect.Type{intT}
    Assert.WillRaise(procedure
      begin
        LParams := TJSONArray.Create;
        LParams.Add(TJSONNull.Create);
        SetLength(LArgs, 1);
        LArgs[0] := TypeInfo(Integer);
        LCodec.ParseRequestArguments(LArgs, LParams);
        LParams.Free;
      end, EJSONRPCError);

    // Test case: `[1]`, []reflect.Type{stringT}
    Assert.WillRaise(procedure
      begin
        LParams := TJSONArray.Create;
        LParams.Add(1);
        SetLength(LArgs, 1);
        LArgs[0] := TypeInfo(String);
        LCodec.ParseRequestArguments(LArgs, LParams);
        LParams.Free;
      end, EJSONRPCError);

  finally
    LCodec.Free;
  end;
end;


procedure RunJsonTest;
begin
  TestJSONRequestParsing;
  TestJSONRequestParamsParsing;
end;

end.
