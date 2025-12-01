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

unit Vite.Rpc.Subscription;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vite.Rpc.Server;

type
  TSubscriptionId = type string;

  ESubscriptionError = class(Exception);

  TSubscription = class
  private
    FId: TSubscriptionId;
    FNamespace: string;
    FErr: TChannel<Exception>;
  public
    constructor Create;
    destructor Destroy; override;
    function Err: TChannel<Exception>;
    property Id: TSubscriptionId read FId;
  end;

  TNotifier = class
  private
    FCodec: IServerCodec;
    FActive: TDictionary<TSubscriptionId, TSubscription>;
    FInactive: TDictionary<TSubscriptionId, TSubscription>;
    FSubMu: TMutex;
  public
    constructor Create(ACodec: IServerCodec);
    destructor Destroy; override;
    function CreateSubscription: TSubscription;
    procedure Notify(Id: TSubscriptionId; Data: TObject);
    function Closed: THandle;
    procedure Unsubscribe(Id: TSubscriptionId);
    procedure Activate(Id: TSubscriptionId; Namespace: string);
  end;

function NotifierFromContext(Ctx: TContext): TNotifier;

implementation

uses
  System.Threading, System.Rtti;

var
  GNotifierKey: TContextKey;

function NotifierFromContext(Ctx: TContext): TNotifier;
var
  Val: TValue;
begin
  if Ctx.TryGetValue(GNotifierKey, Val) then
    Result := Val.AsType<TNotifier>
  else
    Result := nil;
end;

{ TSubscription }

constructor TSubscription.Create;
begin
  FId := TGuid.NewGuid.ToString;
  FErr := TChannel<Exception>.Create(1);
end;

destructor TSubscription.Destroy;
begin
  FErr.Free;
  inherited;
end;

function TSubscription.Err: TChannel<Exception>;
begin
  Result := FErr;
end;

{ TNotifier }

constructor TNotifier.Create(ACodec: IServerCodec);
begin
  FCodec := ACodec;
  FActive := TDictionary<TSubscriptionId, TSubscription>.Create;
  FInactive := TDictionary<TSubscriptionId, TSubscription>.Create;
  FSubMu := TMutex.Create;
end;

destructor TNotifier.Destroy;
begin
  FActive.Free;
  FInactive.Free;
  FSubMu.Free;
  inherited;
end;

function TNotifier.CreateSubscription: TSubscription;
begin
  Result := TSubscription.Create;
  FSubMu.Acquire;
  try
    FInactive.Add(Result.Id, Result);
  finally
    FSubMu.Release;
  end;
end;

procedure TNotifier.Notify(Id: TSubscriptionId; Data: TObject);
var
  Sub: TSubscription;
  Notification: TObject;
begin
  FSubMu.Acquire;
  try
    if FActive.TryGetValue(Id, Sub) then
    begin
      Notification := FCodec.CreateNotification(Sub.Id, Sub.FNamespace, Data);
      FCodec.Write(Notification);
    end;
  finally
    FSubMu.Release;
  end;
end;

function TNotifier.Closed: THandle;
begin
  Result := FCodec.Closed;
end;

procedure TNotifier.Unsubscribe(Id: TSubscriptionId);
var
  Sub: TSubscription;
begin
  FSubMu.Acquire;
  try
    if FActive.TryGetValue(Id, Sub) then
    begin
      Sub.FErr.Close;
      FActive.Remove(Id);
    end
    else
      raise ESubscriptionError.Create('Subscription not found');
  finally
    FSubMu.Release;
  end;
end;

procedure TNotifier.Activate(Id: TSubscriptionId; Namespace: string);
var
  Sub: TSubscription;
begin
  FSubMu.Acquire;
  try
    if FInactive.TryGetValue(Id, Sub) then
    begin
      Sub.FNamespace := Namespace;
      FActive.Add(Id, Sub);
      FInactive.Remove(Id);
    end;
  finally
    FSubMu.Release;
  end;
end;

initialization
  GNotifierKey := TContext.GenerateKey;

end.
