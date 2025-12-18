unit Rpc.Errors;

interface

uses
  RPC.Client,
  RPC.Client.Example.Test,
  RPC.Client.Test,
  RPC.Doc,
  RPC.Endpoints,
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
  RPC.Utils,
  RPC.Utils.Test,
  RPC.Websocket,
  System.Rtti,
  System.SysUtils;

type
  ERpcError = class(Exception)
  public
    function ErrorCode: Integer; virtual; abstract;
  end;

  EShutdownError = class(ERpcError)
  public
    function ErrorCode: Integer; override;
    constructor Create;
  end;

  EExecutePanicError = class(ERpcError)
  public
    function ErrorCode: Integer; override;
    constructor Create;
  end;

  ECallbackError = class(ERpcError)
  public
    function ErrorCode: Integer; override;
    constructor Create(const ParaMessage: string);
  end;

  EInvalidRequestError = class(ERpcError)
  private
    mId: TValue;
  public
    function ErrorCode: Integer; override;
    function GetId: TValue;
    constructor Create(const ParaMessage: string; const ParaId: TValue);
  end;

  EMethodNotFoundError = class(ERpcError)
  private
    mService: string;
    mMethod: string;
    mId: TValue;
  public
    function ErrorCode: Integer; override;
    function GetId: TValue;
    constructor Create(const ParaService, ParaMethod: string; const ParaId: TValue);
  end;

  EInvalidParamsError = class(ERpcError)
  public
    function ErrorCode: Integer; override;
    constructor Create(const ParaMessage: string);
  end;

  EInvalidMessageError = class(ERpcError)
  public
    function ErrorCode: Integer; override;
    constructor Create(const ParaMessage: string);
  end;

implementation

{ EShutdownError }

constructor EShutdownError.Create;
begin
  inherited Create('server is shutting down');
end;

function EShutdownError.ErrorCode: Integer;
begin
  Result := -32000;
end;

{ EExecutePanicError }

constructor EExecutePanicError.Create;
begin
  inherited Create('server execute panic');
end;

function EExecutePanicError.ErrorCode: Integer;
begin
  Result := -32001;
end;

{ ECallbackError }

constructor ECallbackError.Create(const ParaMessage: string);
begin
  inherited Create(ParaMessage);
end;

function ECallbackError.ErrorCode: Integer;
begin
  Result := -32002;
end;

{ EInvalidRequestError }

constructor EInvalidRequestError.Create(const ParaMessage: string; const ParaId: TValue);
begin
  inherited Create(ParaMessage);
  mId := ParaId;
end;

function EInvalidRequestError.ErrorCode: Integer;
begin
  Result := -32600;
end;

function EInvalidRequestError.GetId: TValue;
begin
  Result := mId;
end;

{ EMethodNotFoundError }

constructor EMethodNotFoundError.Create(const ParaService, ParaMethod: string; const ParaId: TValue);
begin
  inherited CreateFmt('The method %s.%s does not exist/is not available', [ParaService, ParaMethod]);
  mService := ParaService;
  mMethod := ParaMethod;
  mId := ParaId;
end;

function EMethodNotFoundError.ErrorCode: Integer;
begin
  Result := -32601;
end;

function EMethodNotFoundError.GetId: TValue;
begin
  Result := mId;
end;

{ EInvalidParamsError }

constructor EInvalidParamsError.Create(const ParaMessage: string);
begin
  inherited Create(ParaMessage);
end;

function EInvalidParamsError.ErrorCode: Integer;
begin
  Result := -32602;
end;

{ EInvalidMessageError }

constructor EInvalidMessageError.Create(const ParaMessage: string);
begin
  inherited Create(ParaMessage);
end;

function EInvalidMessageError.ErrorCode: Integer;
begin
  Result := -32700;
end;

end.
