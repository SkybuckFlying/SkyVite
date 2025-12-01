unit Ledger.Pool.Context;

interface

type
  TPoolContext = class
  private
    mCompactDirty: boolean;
  public
    procedure SetCompactDirty(ParaDirty: boolean);
    property CompactDirty: boolean read mCompactDirty;
  end;

implementation

{ TPoolContext }

procedure TPoolContext.SetCompactDirty(ParaDirty: boolean);
begin
  mCompactDirty := ParaDirty;
end;

end.
