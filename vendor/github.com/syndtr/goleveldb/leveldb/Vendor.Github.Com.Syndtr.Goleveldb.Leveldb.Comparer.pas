unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer;

interface

uses
	System.SysUtils,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer.Comparer,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Key;

type
	IInternalComparer = interface( IComparer )
		['{F5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F76}']
		function UCompare( const a, b : TBytes ) : Integer;
		function USeparator( const dst, a, b : TBytes ) : TBytes;
		function USuccessor( const dst, b : TBytes ) : TBytes;
	end;

	TInternalComparer = class( TInterfacedObject, IBasicComparer, IComparer, IInternalComparer )
	private
		mUcmp : IComparer;
	public
		constructor Create( const ParaUcmp : IComparer );
		function Name : string;
		function Compare( const a, b : TBytes ) : Integer;
		function Separator( const dst, a, b : TBytes ) : TBytes;
		function Successor( const dst, b : TBytes ) : TBytes;
		
		function UCompare( const a, b : TBytes ) : Integer;
		function USeparator( const dst, a, b : TBytes ) : TBytes;
		function USuccessor( const dst, b : TBytes ) : TBytes;
	end;

implementation

{ TInternalComparer }

constructor TInternalComparer.Create( const ParaUcmp : IComparer );
begin
	inherited Create;
	mUcmp := ParaUcmp;
end;

function TInternalComparer.Name : string;
begin
	Result := mUcmp.Name;
end;

function TInternalComparer.Compare( const a, b : TBytes ) : Integer;
var
	x : Integer;
	seqA, seqB : UInt64;
	ktA, ktB : TKeyType;
begin
	x := UCompare( TInternalKey( a ).Ukey, TInternalKey( b ).Ukey );
	if x = 0 then
	begin
		TInternalKey( a ).ParseNum( seqA, ktA );
		TInternalKey( b ).ParseNum( seqB, ktB );
		// Sequence numbers are compared in reverse order
		if seqA > seqB then
			Result := -1
		else if seqA < seqB then
			Result := 1
		else
			Result := 0;
	end
	else
		Result := x;
end;

function TInternalComparer.Separator( const dst, a, b : TBytes ) : TBytes;
var
	ua, ub : TBytes;
begin
	ua := TInternalKey( a ).Ukey;
	ub := TInternalKey( b ).Ukey;
	Result := mUcmp.Separator( dst, ua, ub );
	if ( Result <> nil ) and ( Length( Result ) < Length( ua ) ) and ( UCompare( ua, Result ) < 0 ) then
	begin
		Result := Result + KeyMaxNumBytes;
	end
	else
		Result := nil;
end;

function TInternalComparer.Successor( const dst, b : TBytes ) : TBytes;
var
	ub : TBytes;
begin
	ub := TInternalKey( b ).Ukey;
	Result := mUcmp.Successor( dst, ub );
	if ( Result <> nil ) and ( Length( Result ) < Length( ub ) ) and ( UCompare( ub, Result ) < 0 ) then
	begin
		Result := Result + KeyMaxNumBytes;
	end
	else
		Result := nil;
end;

function TInternalComparer.UCompare( const a, b : TBytes ) : Integer;
begin
	Result := mUcmp.Compare( a, b );
end;

function TInternalComparer.USeparator( const dst, a, b : TBytes ) : TBytes;
begin
	Result := mUcmp.Separator( dst, a, b );
end;

function TInternalComparer.USuccessor( const dst, b : TBytes ) : TBytes;
begin
	Result := mUcmp.Successor( dst, b );
end;

end.
