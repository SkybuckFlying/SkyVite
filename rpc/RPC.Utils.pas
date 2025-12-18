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

unit Vite.Rpc.Utils;

interface

uses
  RPC.Client,
  RPC.Client.Example.Test,
  RPC.Client.Test,
  RPC.Doc,
  RPC.Endpoints,
  RPC.Errors,
  RPC.Health,
  RPC.Http,
  RPC.Http.Test,
  RPC.Inproc,
  RPC.IPC,
  RPC.IPC.Unix,
  RPC.IPC.Windows,
  RPC.Json,
  RPC.Json.Test,
  RPC.Server,
  RPC.Server.Test,
  RPC.Subscription,
  RPC.Subscription.Test,
  RPC.Types,
  RPC.Utils.Test,
  RPC.Websocket,
  System.SysUtils System.Classes System.Rtti,
  Vite.Rpc.Server Vite.Rpc.Subscription;

function IsExported(Name: string): Boolean;
function IsExportedOrBuiltinType(AType: TRttiType): Boolean;
function IsContextType(AType: TRttiType): Boolean;
function IsErrorType(AType: TRttiType): Boolean;
function IsSubscriptionType(AType: TRttiType): Boolean;
function IsPubSub(MethodType: TRttiMethod): Boolean;
function FormatName(Name: string): string;
function SuitableCallbacks(Rcvr: TValue; AType: TRttiType): TTuple<TDictionary<string, TCallback>, TDictionary<string, TCallback>>;
function NewId: TSubscriptionId;

implementation

uses
  System.Character, System.Generics.Collections, System.Math;

function IsExported(Name: string): Boolean;
begin
  if Name.IsEmpty then
    Result := False
  else
    Result := TChar.IsUpper(Name[1]);
end;

function IsExportedOrBuiltinType(AType: TRttiType): Boolean;
begin
  while AType.IsPointer do
    AType := AType.AsPointer.ElementType;
  Result := IsExported(AType.Name) or (AType.PackageName = '');
end;

function IsContextType(AType: TRttiType): Boolean;
begin
  while AType.IsPointer do
    AType := AType.AsPointer.ElementType;
  Result := AType.Handle = TypeInfo(TContext);
end;

function IsErrorType(AType: TRttiType): Boolean;
begin
  while AType.IsPointer do
    AType := AType.AsPointer.ElementType;
  Result := AType.IsInstance and AType.AsInstance.MetaclassType.InheritsFrom(Exception);
end;

function IsSubscriptionType(AType: TRttiType): Boolean;
begin
  while AType.IsPointer do
    AType := AType.AsPointer.ElementType;
  Result := AType.Handle = TypeInfo(TSubscription);
end;

function IsPubSub(MethodType: TRttiMethod): Boolean;
begin
  Result := (MethodType.MethodKind = mkFunction) and
    (Length(MethodType.GetParameters) >= 1) and
    IsContextType(MethodType.GetParameters[0].ParamType) and
    (MethodType.ReturnType.Handle = TypeInfo(TSubscription)) and
    (Length(MethodType.GetParameters) > 1) and
    IsErrorType(MethodType.GetParameters[1].ParamType);
end;

function FormatName(Name: string): string;
begin
  if Name.IsEmpty then
    Result := ''
  else
    Result := TChar.ToLower(Name[1]) + Name.Substring(1);
end;

function SuitableCallbacks(Rcvr: TValue; AType: TRttiType): TTuple<TDictionary<string, TCallback>, TDictionary<string, TCallback>>;
var
  Callbacks, Subscriptions: TDictionary<string, TCallback>;
  Methods: TArray<TRttiMethod>;
  Method: TRttiMethod;
  Callback: TCallback;
  I: Integer;
  ArgType: TRttiType;
begin
  Callbacks := TDictionary<string, TCallback>.Create;
  Subscriptions := TDictionary<string, TCallback>.Create;

  Methods := AType.GetMethods;
  for Method in Methods do
  begin
    if Method.IsPublic then
    begin
      Callback := TCallback.Create;
      Callback.FMethod := Method;
      Callback.FReceiver := Rcvr;
      Callback.FIsSubscribe := IsPubSub(Method);

      // TODO: Complete the implementation
    end;
  end;

  Result := TTuple.Create(Callbacks, Subscriptions);
end;

function NewId: TSubscriptionId;
var
  Guid: TGuid;
begin
  Guid := TGuid.NewGuid;
  Result := '0x' + Guid.ToString.Replace('{', '').Replace('}', '').Replace('-', '');
end;

end.
