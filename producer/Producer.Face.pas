unit Producer.Face;

interface

uses
  Common.Types,
  Producer.ProducerEvent;

type
  TAccountEventFunc = procedure(const ParaAccountEvent: TAccountEvent);

  IProducer = interface
    ['{B1B2B3B4-B5B6-B7B8-B9BA-BCBDBEBFC0C1}']
    procedure SetAccountEventFunc(const ParaFunc: TAccountEventFunc);
    function Init: Boolean;
    function Start: Boolean;
    function Stop: Boolean;
    function GetCoinBase: TAddress;
    function SnapshotOnce: Boolean;
  end;

implementation

end.
