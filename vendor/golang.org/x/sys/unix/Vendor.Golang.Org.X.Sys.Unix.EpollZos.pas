unit Vendor.Golang.Org.X.Sys.Unix.EpollZos;

interface

uses
  System.SysUtils, System.SyncObjs;

type
  TEpollEvent = record
    Events: UInt32;
    Fd: Int32;
    Pad: Int32;
  end;
  PEpollEvent = ^TEpollEvent;

const
  EPOLLERR      = $8;
  EPOLLHUP      = $10;
  EPOLLIN       = $1;
  EPOLLMSG      = $400;
  EPOLLOUT      = $4;
  EPOLLPRI      = $2;
  EPOLLRDBAND   = $80;
  EPOLLRDNORM   = $40;
  EPOLLWRBAND   = $200;
  EPOLLWRNORM   = $100;
  EPOLL_CTL_ADD = $1;
  EPOLL_CTL_DEL = $2;
  EPOLL_CTL_MOD = $3;

function EpollCreate(Size: Integer): TTuple<Int32, Exception>;
function EpollCtl(Epfd, Op, Fd: Integer; Event: PEpollEvent): Exception;
function EpollWait(Epfd: Integer; var Events: array of TEpollEvent; Msec: Integer): TTuple<Integer, Exception>;

implementation

function EpollCreate(Size: Integer): TTuple<Int32, Exception>;
begin
  Result := Default(TTuple<Int32, Exception>);
end;

function EpollCtl(Epfd, Op, Fd: Integer; Event: PEpollEvent): Exception;
begin
  Result := nil;
end;

function EpollWait(Epfd: Integer; var Events: array of TEpollEvent; Msec: Integer): TTuple<Integer, Exception>;
begin
  Result := Default(TTuple<Integer, Exception>);
end;

end.
