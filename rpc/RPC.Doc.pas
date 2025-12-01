{
  Copyright 2022 The Delphi-Vite Authors
  This file is part of the Delphi-Vite library.

  The Delphi-Vite library is free software: you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  The Delphi-Vite library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with the Delphi-Vite library. If not, see <http://www.gnu.org/licenses/>.
}

unit Rpc.Doc;

interface

{
  Package rpc provides access to the exported methods of an object across a network
  or other I/O connection. After creating a server instance objects can be registered,
  making it visible from the outside. Exported methods that follow specific
  conventions can be called remotely. It also has support for the publish/subscribe
  pattern.

  Methods that satisfy the following criteria are made available for remote access:
   - object must be exported
   - method must be exported
   - method returns 0, 1 (response or error) or 2 (response and error) values
   - method argument(s) must be exported or builtin types
   - method returned value(s) must be exported or builtin types

  An example method:
   function TCalcService.Add(const ParaA, ParaB: Integer): Integer;

  When the returned error isn't nil the returned integer is ignored and the error is
  send back to the client. Otherwise the returned integer is send back to the client.

  Optional arguments are supported by accepting pointer values as arguments. E.g.
  if we want to do the addition in an optional finite field we can accept a mod
  argument as pointer value.

   function TCalService.Add(const ParaA, ParaB: Integer; const ParaMod: PInteger): Integer;

  This RPC method can be called with 2 integers and a null value as third argument.
  In that case the mod argument will be nil. Or it can be called with 3 integers,
  in that case mod will be pointing to the given third argument. Since the optional
  argument is the last argument the RPC package will also accept 2 integers as
  arguments. It will pass the mod argument as nil to the RPC method.

  The server offers the ServeCodec method which accepts a ServerCodec instance. It will
  read requests from the codec, process the request and sends the response back to the
  client using the codec. The server can execute requests concurrently. Responses
  can be sent back to the client out of order.

  An example server which uses the JSON codec:
   type
     TCalculatorService = class
     public
       function Add(const ParaA, ParaB: Integer): Integer;
       function Div(const ParaA, ParaB: Integer): Integer;
     end;

   function TCalculatorService.Add(const ParaA, ParaB: Integer): Integer;
   begin
     Result := ParaA + ParaB;
   end;

   function TCalculatorService.Div(const ParaA, ParaB: Integer): Integer;
   begin
     if ParaB = 0 then
     begin
       raise EDivByZero.Create('divide by zero');
     end;
     Result := ParaA div ParaB;
   end;

   var
     vCalculator: TCalculatorService;
     vServer: TRpcServer;
     vListener: TSocket;
     vConn: TSocket;
     vCodec: TJsonCodec;
   begin
     vCalculator := TCalculatorService.Create;
     vServer := TRpcServer.Create;
     vServer.RegisterName('calculator', vCalculator);

     vListener := TSocket.Create(TTcp.Create);
     vListener.Bind('127.0.0.1', 8545);
     vListener.Listen;
     while True do
     begin
       vConn := vListener.Accept;
       vCodec := TJsonCodec.Create(vConn);
       TTask.Run(
         procedure
         begin
           vServer.ServeCodec(vCodec);
         end);
     end;
   end;

  The package also supports the publish subscribe pattern through the use of subscriptions.
  A method that is considered eligible for notifications must satisfy the following criteria:
   - object must be exported
   - method must be exported
   - first method argument type must be TContext
   - method argument(s) must be exported or builtin types
   - method must return the tuple TSubscription, Exception

  An example method:
   function TBlockChainService.NewBlocks(const ParaCtx: TContext): TPair<TSubscription, Exception>;

  Subscriptions are deleted when:
   - the user sends an unsubscribe request
   - the connection which was used to create the subscription is closed. This can be initiated
     by the client and server. The server will close the connection on a write error or when
     the queue of buffered notifications gets too big.
}

implementation

end.
