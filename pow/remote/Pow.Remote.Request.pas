unit Pow.Remote.Request;

interface

uses
  Pow.Remote.Response,
  Pow.Remote.Service,
  Pow.Remote.Service.Test,
  System.Classes,
  System.JSON.Serializers,
  System.SysUtils;

type
  TWorkGenerate = class
  private
    [JSONName('hash')]
    mDataHash: string;
    [JSONName('threshold')]
    mThreshold: string;
  public
    property DataHash: string read mDataHash write mDataHash;
    property Threshold: string read mThreshold write mThreshold;
  end;

  TWorkValidate = class
  private
    [JSONName('hash')]
    mDataHash: string;
    [JSONName('threshold')]
    mThreshold: string;
    [JSONName('work')]
    mWork: string;
  public
    property DataHash: string read mDataHash write mDataHash;
    property Threshold: string read mThreshold write mThreshold;
    property Work: string read mWork write mWork;
  end;

  TWorkCancel = class
  private
    [JSONName('hash')]
    mDataHash: string;
  public
    property DataHash: string read mDataHash write mDataHash;
  end;

implementation

end.
