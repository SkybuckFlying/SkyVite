unit Log15.Handler.Go13;

interface

uses
  Log15.Doc,
  Log15.Format,
  Log15.Handler,
  Log15.Handler.Go14,
  Log15.Logger,
  Log15.Root,
  Log15.Syslog,
  System.SyncObjs;

type
	TSwapHandler = class(TInterfacedObject, IHandler)
	private
		mHandler : IHandler;
	public
		function Log( ParaR : TRecord ) : Boolean;
		function Get : IHandler;
		procedure Swap( ParaNewHandler : IHandler );
	end;

implementation

{ TSwapHandler }

function TSwapHandler.Log( ParaR : TRecord ) : Boolean;
begin
	Result := Get.Log( ParaR );
end;

function TSwapHandler.Get : IHandler;
begin
	TMonitor.Enter( Self );
	try
		Result := mHandler;
	finally
		TMonitor.Exit( Self );
	end;
end;

procedure TSwapHandler.Swap( ParaNewHandler : IHandler );
begin
	TMonitor.Enter( Self );
	try
		mHandler := ParaNewHandler;
	finally
		TMonitor.Exit( Self );
	end;
end;

end.
