unit VM.Contracts.Dex.Matcher;

interface

uses
  System.SysUtils, System.Generics.Collections, System.BigInt,
  GoVite.Types, GoVite.Interfaces, GoVite.Ledger,
  VM.Contracts.Dex.Proto, VM.Contracts.Dex.Order, VM.Contracts.Dex.Storage,
  VM.Contracts.Dex.Leveldb.Book;

const
  MaxTxsCountPerTaker = 100;
  TimeoutSecond = 30 * 24 * 3600;
  TxIdLength = 20;
  BigFloatPrec = 120;

type
  TMatcher = class
  private
    FDb: IVmDb;
    FFundSettles: TDictionary<TAddress, TDictionary<Boolean, TAccountSettle>>;
    FFeeSettles: TDictionary<TAddress, TFeeSettle>;
    FMarketInfo: TMarketInfo;

    procedure DoMatchTaker(ATaker: TOrder; AMakerBook: TLevelDbBook; APreHash: THash);
    function RecursiveTakeOrder(ATaker, AMaker: TOrder; AMakerBook: TLevelDbBook; AModifiedMakers: TList<TOrder>; ATxs: TList<TOrderTx>; AHeightPoint: THeightPoint): TError;
    procedure HandleTakerRes(ATaker: TOrder);
    procedure HandleModifiedMakers(AMakers: TList<TOrder>);
    procedure HandleRefund(AOrder: TOrder);
    procedure EmitNewOrder(ATaker: TOrder);
    procedure EmitOrderUpdate(AOrder: TOrder);
    procedure HandleTxs(ATxs: TList<TOrderTx>);
    procedure HandleTxFundSettle(ATx: TOrderTx);
    procedure UpdateFundSettle(AAddressBytes: TBytes; ASettle: TAccountSettle);
    procedure UpdateFee(AAddress: TBytes; AFeeAmt, AOperatorFee: TBytes);
    function GetOrderBookForTaker(ATakerSide: Boolean): TLevelDbBook;
    procedure SaveOrder(AOrder: TOrder; AIsTaker: Boolean);
    procedure DeleteOrder(AOrder: TOrder);
  public
    constructor Create(const ADB: IVmDb; AMarketId: Int32);
    constructor CreateWithMarketInfo(const ADB: IVmDb; AMarketInfo: TMarketInfo);
    constructor CreateRaw(const ADB: IVmDb);
    destructor Destroy; override;
    function MatchOrder(ATaker: TOrder; APreHash: THash): TError;
    function GetFundSettles: TDictionary<TAddress, TDictionary<Boolean, TAccountSettle>>;
    function GetFees: TDictionary<TAddress, TFeeSettle>;
    function GetOrderById(AOrderId: TBytes): TOrder;
    function GetOrdersFromMarket(ASide: Boolean; ABegin, AEnd: Integer): TPair<TArray<TOrder>, Integer>;
    procedure CancelOrderById(AOrder: TOrder);
    property MarketInfo: TMarketInfo read FMarketInfo;
  end;

  TOrderTx = class(TTransaction)
  public
    TakerAddress: TBytes;
    MakerAddress: TBytes;
    TradeToken: TBytes;
    QuoteToken: TBytes;
  end;

var
  BaseFeeRate: Int32 = 200;
  VipReduceFeeRate: Int32 = 100;
  MaxOperatorFeeRate: Int32 = 200;
  PerPeriodDividendRate: Int32 = 1000;
  InviterBonusRate: Int32 = 5000;
  InviteeBonusRate: Int32 = 2500;
  RateCardinalNum: Int32 = 100000;

implementation

uses
  GoVite.Crypto, VM.Contracts.Dex.Events, VM.Contracts.Dex.Utils;

{ TMatcher }

constructor TMatcher.Create(const ADB: IVmDb; AMarketId: Int32);
begin
  CreateRaw(ADB);
  FMarketInfo := GetMarketInfoById(FDb, AMarketId);
  if not Assigned(FMarketInfo) then
    raise Exception.Create(TradeMarketNotExistsErr);
end;

// ... other constructor implementations ...

// ... method implementations ...

end.
