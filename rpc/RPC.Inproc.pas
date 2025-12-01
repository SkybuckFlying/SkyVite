unit Rpc.Inproc;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Net.Sockets,
  Rpc.Server,
  Rpc.Client,
  Rpc.Json,
  Rpc.Connection;

function DialInProc(const ParaHandler: TRpcServer): TRpcClient;

implementation

uses
  System.Threading,
  System.IOUtils;

type
  TPipeConnection = class(TInterfacedObject, IConnection)
  private
    mInput, mOutput: TStream;
  public
    constructor Create(const ParaInput, ParaOutput: TStream);
    function Read(const ParaBuffer: TBytes; const ParaOffset, ParaCount: Integer): Integer;
    function Write(const ParaBuffer: TBytes; const ParaOffset, ParaCount: Integer): Integer;
    procedure Close;
    function GetStream: TStream;
    function GetRemoteAddress: string;
  end;

{ TPipeConnection }

constructor TPipeConnection.Create(const ParaInput, ParaOutput: TStream);
begin
  mInput := ParaInput;
  mOutput := ParaOutput;
end;

function TPipeConnection.Read(const ParaBuffer: TBytes; const ParaOffset, ParaCount: Integer): Integer;
begin
  Result := mInput.Read(ParaBuffer, ParaOffset, ParaCount);
end;

function TPipeConnection.Write(const ParaBuffer: TBytes; const ParaOffset, ParaCount: Integer): Integer;
begin
  Result := mOutput.Write(ParaBuffer, ParaOffset, ParaCount);
end;

procedure TPipeConnection.Close;
begin
  // Do nothing
end;

function TPipeConnection.GetStream: TStream;
begin
  Result := mInput;
end;

function TPipeConnection.GetRemoteAddress: string;
begin
  Result := 'inproc';
end;

function DialInProc(const ParaHandler: TRpcServer): TRpcClient;
var
  vPipe1, vPipe2: TStream;
  vConn1, vConn2: IConnection;
begin
  // This is a simplified pipe implementation for in-process communication.
  // A more robust implementation would use anonymous pipes or a similar mechanism.
  vPipe1 := TMemoryStream.Create;
  vPipe2 := TMemoryStream.Create;
  vConn1 := TPipeConnection.Create(vPipe1, vPipe2);
  vConn2 := TPipeConnection.Create(vPipe2, vPipe1);
  TTask.Run(
    procedure
    var
      vCodec: TJsonCodec;
    begin
      vCodec := TJsonCodec.Create(vConn1);
      try
        ParaHandler.ServeCodec(vCodec, [omMethodInvocation, omSubscriptions]);
      finally
        vCodec.Free;
      end;
    end);
  Result := TRpcClient.Create(
    function: IConnection
    begin
      Result := vConn2;
    end);
end;

end.
