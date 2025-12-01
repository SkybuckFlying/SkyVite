unit Pow.Remote.Response;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON.Serializers,
  System.JSON;

type
  TResponseJson = class
  private
    [JSONName('code')]
    mCode: Integer;
    [JSONName('data')]
    mData: TObject;
    [JSONName('error')]
    mError: string;
    [JSONName('msg')]
    mMsg: string;
  public
    property Code: Integer read mCode write mCode;
    property Data: TObject read mData write mData;
    property Error: string read mError write mError;
    property Msg: string read mMsg write mMsg;
  end;

  TWorkGenerateResult = class
  private
    [JSONName('work')]
    mWork: string;
  public
    property Work: string read mWork write mWork;
  end;

  TWorkCancelResult = class
  end;

  TWorkValidateResult = class
  private
    [JSONName('valid')]
    mValid: string;
  public
    property Valid: string read mValid write mValid;
  end;

implementation

end.
