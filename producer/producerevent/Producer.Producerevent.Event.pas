unit Producer.ProducerEvent;

interface

uses
  System.SysUtils,
  System.Classes,
  Common.Types;

type
  IAccountEvent = interface(IUnknown)
    ['{C0B8E3A4-8D7C-4F7E-A6A4-3B8D1E4A3B3C}']
  end;

  TAccountStartEvent = class(TInterfacedObject, IAccountEvent)
  private
    mGid: TGid;
    mAddress: TAddress;
    mStime: TDateTime;
    mEtime: TDateTime;
  public
    property Gid: TGid read mGid write mGid;
    property Address: TAddress read mAddress write mAddress;
    property Stime: TDateTime read mStime write mStime;
    property Etime: TDateTime read mEtime write mEtime;
  end;

implementation

end.
