unit Net.BlockFeed;

interface

uses
  System.SysUtils, Classes, System.Generics.Collections,
  GoToDelphi.Helpers.TChannel, Common.Types, Event;

type
  TBlockEvent = record
    Block: TBlock;
  end;

  IBlockSubscription = interface
    ['{A5B3E7C9-8D4F-4A6B-9F2C-3D1E0F1A3B2D}']
    procedure Unsubscribe;
    function Err: TChannel<TObject>;
  end;

  IBlockFeed = interface
    ['{B4C2D6E8-7C3E-4B5A-8E1D-2C0F9A8B7D6C}']
    function Subscribe(ParaCh: TChannel<TBlockEvent>): IBlockSubscription;
    procedure SetHead(ParaBlock: TBlock);
  end;

  TBlockFeed = class(TInterfacedObject, IBlockFeed)
  private
    mFeed: TEventFeed;
    mNewHead: TChannel<TBlock>;
    mUpdateTask: ITask;
    mCancelToken: TCancellationTokenSource;
    procedure Update;
  public
    constructor Create;
    destructor Destroy; override;
    function Subscribe(ParaCh: TChannel<TBlockEvent>): IBlockSubscription;
    procedure SetHead(ParaBlock: TBlock);
  end;

  TBlockSubscription = class(TInterfacedObject, IBlockSubscription)
  private
    mFeed: TEventFeed;
    mCh: TChannel<TBlockEvent>;
    mErr: TChannel<TObject>;
    mSub: ISubscription;
  public
    constructor Create(ParaFeed: TEventFeed; ParaCh: TChannel<TBlockEvent>);
    destructor Destroy; override;
    procedure Unsubscribe;
    function Err: TChannel<TObject>;
  end;

implementation

{ TBlockFeed }

constructor TBlockFeed.Create;
begin
  inherited Create;
  mFeed := TEventFeed.Create;
  mNewHead := TChannel<TBlock>.Create;
  mCancelToken := TCancellationTokenSource.Create;
  mUpdateTask := TTask.Run(Update, mCancelToken.Token);
end;

destructor TBlockFeed.Destroy;
begin
  mCancelToken.Cancel;
  mNewHead.Close;
  mUpdateTask.Wait;
  mFeed.Free;
  mNewHead.Free;
  mCancelToken.Free;
  inherited Destroy;
end;

procedure TBlockFeed.SetHead(ParaBlock: TBlock);
begin
  mNewHead.Send(ParaBlock);
end;

function TBlockFeed.Subscribe(ParaCh: TChannel<TBlockEvent>): IBlockSubscription;
begin
  Result := TBlockSubscription.Create(mFeed, ParaCh);
end;

procedure TBlockFeed.Update;
var
  vHead: TBlock;
  vEvent: TBlockEvent;
begin
  while not mCancelToken.IsCancellationRequested do
  begin
    if mNewHead.Receive(vHead) then
    begin
      vEvent.Block := vHead;
      mFeed.Send(vEvent);
    end
    else
    begin
      // Channel was closed
      Break;
    end;
  end;
end;

{ TBlockSubscription }

constructor TBlockSubscription.Create(ParaFeed: TEventFeed; ParaCh: TChannel<TBlockEvent>);
begin
  inherited Create;
  mFeed := ParaFeed;
  mCh := ParaCh;
  mErr := TChannel<TObject>.Create;
  mSub := mFeed.Subscribe(mCh);
end;

destructor TBlockSubscription.Destroy;
begin
  mSub.Unsubscribe;
  mErr.Free;
  inherited Destroy;
end;

function TBlockSubscription.Err: TChannel<TObject>;
begin
  Result := mErr;
end;

procedure TBlockSubscription.Unsubscribe;
begin
  mSub.Unsubscribe;
end;

end.