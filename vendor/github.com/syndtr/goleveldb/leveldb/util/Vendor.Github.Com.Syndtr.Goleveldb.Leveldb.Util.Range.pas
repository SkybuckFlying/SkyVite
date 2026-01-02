unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Range;

interface

uses
  System.SysUtils;

type
  /// <summary>
  /// Range is a key range.
  /// </summary>
  TRange = record
    /// <summary>
    /// Start of the key range, include in the range.
    /// </summary>
    Start: TBytes;

    /// <summary>
    /// Limit of the key range, not include in the range.
    /// </summary>
    Limit: TBytes;
  end;
  PRange = ^TRange;

/// <summary>
/// BytesPrefix returns key range that satisfy the given prefix.
/// This only applicable for the standard 'bytes comparer'.
/// </summary>
function BytesPrefix(const prefix: TBytes): TRange;

implementation

function BytesPrefix(const prefix: TBytes): TRange;
var
  limit: TBytes;
  i: Integer;
  c: Byte;
begin
  limit := nil;
  for i := Length(prefix) - 1 downto 0 do
  begin
    c := prefix[i];
    if c < $FF then
    begin
      SetLength(limit, i + 1);
      if i > 0 then
        Move(prefix[0], limit[0], i);
      limit[i] := c + 1;
      break;
    end;
  end;
  Result.Start := prefix;
  Result.Limit := limit;
end;

end.
