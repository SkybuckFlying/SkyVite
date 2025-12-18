unit Vendor.Github.Com.Pmezard.GoDifflib.Difflib.Difflib;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Generics.Collections,
	System.Math;

type
	TMatch = record
		A    : Integer;
		B    : Integer;
		Size : Integer;
	end;

	TOpCode = record
		Tag : Byte; // 'r', 'd', 'i', 'e'
		I1  : Integer;
		I2  : Integer;
		J1  : Integer;
		J2  : Integer;
	end;

	TIsJunkFunc = reference to function( const ParaS : string ) : Boolean;

	TSequenceMatcher = class
	private
		mA              : TArray<string>;
		mB              : TArray<string>;
		mB2j            : TDictionary<string, TArray<Integer>>;
		mIsJunk         : TIsJunkFunc;
		mAutoJunk       : Boolean;
		mBJunk          : THashSet<string>;
		mMatchingBlocks : TArray<TMatch>;
		mFullBCount     : TDictionary<string, Integer>;
		mBPopular       : THashSet<string>;
		mOpCodes        : TArray<TOpCode>;

		procedure ChainB;
		function IsBJunk( const ParaS : string ) : Boolean;
	public
		constructor Create( const ParaA, ParaB : TArray<string>; ParaAutoJunk : Boolean = True; ParaIsJunk : TIsJunkFunc = nil );
		destructor Destroy; override;

		procedure SetSeqs( const ParaA, ParaB : TArray<string> );
		procedure SetSeq1( const ParaA : TArray<string> );
		procedure SetSeq2( const ParaB : TArray<string> );

		function FindLongestMatch( ParaAlo, ParaAhi, ParaBlo, ParaBhi : Integer ) : TMatch;
		function GetMatchingBlocks : TArray<TMatch>;
		function GetOpCodes : TArray<TOpCode>;
		function GetGroupedOpCodes( ParaN : Integer = 3 ) : TArray<TArray<TOpCode>>;
		function Ratio : Double;
		function QuickRatio : Double;
		function RealQuickRatio : Double;
	end;

	TUnifiedDiff = record
		A        : TArray<string>;
		FromFile : string;
		FromDate : string;
		B        : TArray<string>;
		ToFile   : string;
		ToDate   : string;
		Eol      : string;
		Context  : Integer;
	end;

procedure WriteUnifiedDiff( ParaWriter : TStreamWriter; const ParaDiff : TUnifiedDiff );
function GetUnifiedDiffString( const ParaDiff : TUnifiedDiff ) : string;
function SplitLines( const ParaS : string ) : TArray<string>;

implementation

{ TSequenceMatcher }

constructor TSequenceMatcher.Create( const ParaA, ParaB : TArray<string>; ParaAutoJunk : Boolean; ParaIsJunk : TIsJunkFunc );
begin
	inherited Create;
	mAutoJunk := ParaAutoJunk;
	mIsJunk := ParaIsJunk;
	mB2j := TDictionary<string, TArray<Integer>>.Create;
	mBJunk := THashSet<string>.Create;
	mBPopular := THashSet<string>.Create;
	mFullBCount := TDictionary<string, Integer>.Create;
	SetSeqs( ParaA, ParaB );
end;

destructor TSequenceMatcher.Destroy;
begin
	mB2j.Free;
	mBJunk.Free;
	mBPopular.Free;
	mFullBCount.Free;
	inherited;
end;

procedure TSequenceMatcher.SetSeqs( const ParaA, ParaB : TArray<string> );
begin
	SetSeq1( ParaA );
	SetSeq2( ParaB );
end;

procedure TSequenceMatcher.SetSeq1( const ParaA : TArray<string> );
begin
	mA := ParaA;
	mMatchingBlocks := nil;
	mOpCodes := nil;
end;

procedure TSequenceMatcher.SetSeq2( const ParaB : TArray<string> );
begin
	mB := ParaB;
	mMatchingBlocks := nil;
	mOpCodes := nil;
	mFullBCount.Clear;
	ChainB;
end;

procedure TSequenceMatcher.ChainB;
var
	vI       : Integer;
	vS       : string;
	vIndices : TArray<Integer>;
	vN       : Integer;
	vNtest   : Integer;
	vKVP     : TPair<string, TArray<Integer>>;
	vKeys    : TArray<string>;
begin
	mB2j.Clear;
	for vI := 0 to Length( mB ) - 1 do
	begin
		vS := mB[ vI ];
		if not mB2j.TryGetValue( vS, vIndices ) then
			SetLength( vIndices, 0 );
		SetLength( vIndices, Length( vIndices ) + 1 );
		vIndices[ High( vIndices ) ] := vI;
		mB2j.AddOrSet( vS, vIndices );
	end;

	mBJunk.Clear;
	if Assigned( mIsJunk ) then
	begin
		vKeys := mB2j.Keys.ToArray;
		for vS in vKeys do
		begin
			if mIsJunk( vS ) then
			begin
				mBJunk.Add( vS );
				mB2j.Remove( vS );
			end;
		end;
	end;

	mBPopular.Clear;
	vN := Length( mB );
	if mAutoJunk and ( vN >= 200 ) then
	begin
		vNtest := ( vN div 100 ) + 1;
		vKeys := mB2j.Keys.ToArray;
		for vS in vKeys do
		begin
			if Length( mB2j[ vS ] ) > vNtest then
			begin
				mBPopular.Add( vS );
				mB2j.Remove( vS );
			end;
		end;
	end;
end;

function TSequenceMatcher.IsBJunk( const ParaS : string ) : Boolean;
begin
	Result := mBJunk.Contains( ParaS );
end;

function TSequenceMatcher.FindLongestMatch( ParaAlo, ParaAhi, ParaBlo, ParaBhi : Integer ) : TMatch;
var
	vBesti, vBestj, vBestsize : Integer;
	vJ2len, vNewj2len : TDictionary<Integer, Integer>;
	vI, vJ, vK : Integer;
	vIndices : TArray<Integer>;
begin
	vBesti := ParaAlo;
	vBestj := ParaBlo;
	vBestsize := 0;

	vJ2len := TDictionary<Integer, Integer>.Create;
	try
		for vI := ParaAlo to ParaAhi - 1 do
		begin
			vNewj2len := TDictionary<Integer, Integer>.Create;
			if mB2j.TryGetValue( mA[ vI ], vIndices ) then
			begin
				for vJ in vIndices do
				begin
					if vJ < ParaBlo then
						continue;
					if vJ >= ParaBhi then
						break;
					
					if vJ2len.TryGetValue( vJ - 1, vK ) then
						vK := vK + 1
					else
						vK := 1;
						
					vNewj2len.Add( vJ, vK );
					if vK > vBestsize then
					begin
						vBesti := vI - vK + 1;
						vBestj := vJ - vK + 1;
						vBestsize := vK;
					end;
				end;
			end;
			vJ2len.Free;
			vJ2len := vNewj2len;
		end;
	finally
		vJ2len.Free;
	end;

	while ( vBesti > ParaAlo ) and ( vBestj > ParaBlo ) and ( not IsBJunk( mB[ vBestj - 1 ] ) ) and ( mA[ vBesti - 1 ] = mB[ vBestj - 1 ] ) do
	begin
		vBesti := vBesti - 1;
		vBestj := vBestj - 1;
		vBestsize := vBestsize + 1;
	end;
	
	while ( vBesti + vBestsize < ParaAhi ) and ( vBestj + vBestsize < ParaBhi ) and ( not IsBJunk( mB[ vBestj + vBestsize ] ) ) and ( mA[ vBesti + vBestsize ] = mB[ vBestj + vBestsize ] ) do
	begin
		vBestsize := vBestsize + 1;
	end;

	while ( vBesti > ParaAlo ) and ( vBestj > ParaBlo ) and ( IsBJunk( mB[ vBestj - 1 ] ) ) and ( mA[ vBesti - 1 ] = mB[ vBestj - 1 ] ) do
	begin
		vBesti := vBesti - 1;
		vBestj := vBestj - 1;
		vBestsize := vBestsize + 1;
	end;
	
	while ( vBesti + vBestsize < ParaAhi ) and ( vBestj + vBestsize < ParaBhi ) and ( IsBJunk( mB[ vBestj + vBestsize ] ) ) and ( mA[ vBesti + vBestsize ] = mB[ vBestj + vBestsize ] ) do
	begin
		vBestsize := vBestsize + 1;
	end;

	Result.A := vBesti;
	Result.B := vBestj;
	Result.Size := vBestsize;
end;

function TSequenceMatcher.GetMatchingBlocks : TArray<TMatch>;
var
	vMatched : TList<TMatch>;
	vNonAdjacent : TList<TMatch>;
	vI1, vJ1, vK1 : Integer;
	vI2, vJ2, vK2 : Integer;
	vB : TMatch;

	procedure MatchBlocks( ParaAlo, ParaAhi, ParaBlo, ParaBhi : Integer );
	var
		vMatch : TMatch;
		vI, vJ, vK : Integer;
	begin
		vMatch := FindLongestMatch( ParaAlo, ParaAhi, ParaBlo, ParaBhi );
		vI := vMatch.A;
		vJ := vMatch.B;
		vK := vMatch.Size;
		if vK > 0 then
		begin
			if ( ParaAlo < vI ) and ( ParaBlo < vJ ) then
				MatchBlocks( ParaAlo, vI, ParaBlo, vJ );
			vMatched.Add( vMatch );
			if ( vI + vK < ParaAhi ) and ( vJ + vK < ParaBhi ) then
				MatchBlocks( vI + vK, ParaAhi, vJ + vK, ParaBhi );
		end;
	end;

begin
	if mMatchingBlocks <> nil then
		Exit( mMatchingBlocks );

	vMatched := TList<TMatch>.Create;
	try
		MatchBlocks( 0, Length( mA ), 0, Length( mB ) );

		vNonAdjacent := TList<TMatch>.Create;
		try
			vI1 := 0; vJ1 := 0; vK1 := 0;
			for vB in vMatched do
			begin
				vI2 := vB.A; vJ2 := vB.B; vK2 := vB.Size;
				if ( vI1 + vK1 = vI2 ) and ( vJ1 + vK1 = vJ2 ) then
					vK1 := vK1 + vK2
				else
				begin
					if vK1 > 0 then
						vNonAdjacent.Add( TMatch.Create( vI1, vJ1, vK1 ) );
					vI1 := vI2; vJ1 := vJ2; vK1 := vK2;
				end;
			end;
			if vK1 > 0 then
				vNonAdjacent.Add( TMatch.Create( vI1, vJ1, vK1 ) );
			
			vNonAdjacent.Add( TMatch.Create( Length( mA ), Length( mB ), 0 ) );
			mMatchingBlocks := vNonAdjacent.ToArray;
		finally
			vNonAdjacent.Free;
		end;
	finally
		vMatched.Free;
	end;
	Result := mMatchingBlocks;
end;

function TSequenceMatcher.GetOpCodes : TArray<TOpCode>;
var
	vI, vJ : Integer;
	vMatching : TArray<TMatch>;
	vOpCodes : TList<TOpCode>;
	vM : TMatch;
	vAi, vBj, vSize : Integer;
	vTag : Byte;
begin
	if mOpCodes <> nil then
		Exit( mOpCodes );
	
	vI := 0; vJ := 0;
	vMatching := GetMatchingBlocks;
	vOpCodes := TList<TOpCode>.Create;
	try
		for vM in vMatching do
		begin
			vAi := vM.A; vBj := vM.B; vSize := vM.Size;
			vTag := 0;
			if ( vI < vAi ) and ( vJ < vBj ) then
				vTag := Ord( 'r' )
			else if vI < vAi then
				vTag := Ord( 'd' )
			else if vJ < vBj then
				vTag := Ord( 'i' );
			
			if vTag > 0 then
				vOpCodes.Add( TOpCode.Create( vTag, vI, vAi, vJ, vBj ) );
			
			vI := vAi + vSize;
			vJ := vBj + vSize;
			if vSize > 0 then
				vOpCodes.Add( TOpCode.Create( Ord( 'e' ), vAi, vI, vBj, vJ ) );
		end;
		mOpCodes := vOpCodes.ToArray;
	finally
		vOpCodes.Free;
	end;
	Result := mOpCodes;
end;

function TSequenceMatcher.GetGroupedOpCodes( ParaN : Integer ) : TArray<TArray<TOpCode>>;
var
	vCodes : TArray<TOpCode>;
	vGroups : TList<TArray<TOpCode>>;
	vGroup : TList<TOpCode>;
	vC : TOpCode;
	vI1, vI2, vJ1, vJ2 : Integer;
	vNN : Integer;
begin
	if ParaN < 0 then
		ParaN := 3;
	vCodes := GetOpCodes;
	if Length( vCodes ) = 0 then
		vCodes := [ TOpCode.Create( Ord( 'e' ), 0, 1, 0, 1 ) ];
	
	if vCodes[ 0 ].Tag = Ord( 'e' ) then
	begin
		vC := vCodes[ 0 ];
		vI1 := vC.I1; vI2 := vC.I2; vJ1 := vC.J1; vJ2 := vC.J2;
		vCodes[ 0 ] := TOpCode.Create( vC.Tag, Max( vI1, vI2 - ParaN ), vI2, Max( vJ1, vJ2 - ParaN ), vJ2 );
	end;
	
	if vCodes[ High( vCodes ) ].Tag = Ord( 'e' ) then
	begin
		vC := vCodes[ High( vCodes ) ];
		vI1 := vC.I1; vI2 := vC.I2; vJ1 := vC.J1; vJ2 := vC.J2;
		vCodes[ High( vCodes ) ] := TOpCode.Create( vC.Tag, vI1, Min( vI2, vI1 + ParaN ), vJ1, Min( vJ2, vJ1 + ParaN ) );
	end;

	vNN := ParaN + ParaN;
	vGroups := TList<TArray<TOpCode>>.Create;
	vGroup := TList<TOpCode>.Create;
	try
		for vC in vCodes do
		begin
			vI1 := vC.I1; vI2 := vC.I2; vJ1 := vC.J1; vJ2 := vC.J2;
			if ( vC.Tag = Ord( 'e' ) ) and ( vI2 - vI1 > vNN ) then
			begin
				vGroup.Add( TOpCode.Create( vC.Tag, vI1, Min( vI2, vI1 + ParaN ), vJ1, Min( vJ2, vJ1 + ParaN ) ) );
				vGroups.Add( vGroup.ToArray );
				vGroup.Clear;
				vI1 := Max( vI1, vI2 - ParaN );
				vJ1 := Max( vJ1, vJ2 - ParaN );
			end;
			vGroup.Add( TOpCode.Create( vC.Tag, vI1, vI2, vJ1, vJ2 ) );
		end;
		if ( vGroup.Count > 0 ) and not ( ( vGroup.Count = 1 ) and ( vGroup[ 0 ].Tag = Ord( 'e' ) ) ) then
			vGroups.Add( vGroup.ToArray );
		Result := vGroups.ToArray;
	finally
		vGroup.Free;
		vGroups.Free;
	end;
end;

function TSequenceMatcher.Ratio : Double;
var
	vMatches : Integer;
	vM : TMatch;
begin
	vMatches := 0;
	for vM in GetMatchingBlocks do
		vMatches := vMatches + vM.Size;
	
	if Length( mA ) + Length( mB ) > 0 then
		Result := 2.0 * vMatches / ( Length( mA ) + Length( mB ) )
	else
		Result := 1.0;
end;

function TSequenceMatcher.QuickRatio : Double;
var
	vS : string;
	vN : Integer;
	vAvail : TDictionary<string, Integer>;
	vMatches : Integer;
	vOk : Boolean;
begin
	if mFullBCount.Count = 0 then
	begin
		for vS in mB do
			mFullBCount.AddOrSet( vS, mFullBCount.GetValueOrDefault( vS, 0 ) + 1 );
	end;

	vAvail := TDictionary<string, Integer>.Create;
	try
		vMatches := 0;
		for vS in mA do
		begin
			if not vAvail.TryGetValue( vS, vN ) then
				vN := mFullBCount.GetValueOrDefault( vS, 0 );
			vAvail.AddOrSet( vS, vN - 1 );
			if vN > 0 then
				vMatches := vMatches + 1;
		end;
		if Length( mA ) + Length( mB ) > 0 then
			Result := 2.0 * vMatches / ( Length( mA ) + Length( mB ) )
		else
			Result := 1.0;
	finally
		vAvail.Free;
	end;
end;

function TSequenceMatcher.RealQuickRatio : Double;
var
	vLa, vLb : Integer;
begin
	vLa := Length( mA );
	vLb := Length( mB );
	if vLa + vLb > 0 then
		Result := 2.0 * Min( vLa, vLb ) / ( vLa + vLb )
	else
		Result := 1.0;
end;

{ Helper Functions }

function FormatRangeUnified( ParaStart, ParaStop : Integer ) : string;
var
	vBeginning : Integer;
	vLength    : Integer;
begin
	vBeginning := ParaStart + 1;
	vLength := ParaStop - ParaStart;
	if vLength = 1 then
		Exit( IntToStr( vBeginning ) );
	if vLength = 0 then
		vBeginning := vBeginning - 1;
	Result := Format( '%d,%d', [ vBeginning, vLength ] );
end;

procedure WriteUnifiedDiff( ParaWriter : TStreamWriter; const ParaDiff : TUnifiedDiff );
var
	vStarted : Boolean;
	vM       : TSequenceMatcher;
	vG       : TArray<TOpCode>;
	vFirst   : TOpCode;
	vLast    : TOpCode;
	vRange1  : string;
	vRange2  : string;
	vC       : TOpCode;
	vI       : Integer;
	vLine    : string;
	vEol     : string;
	vFromDate : string;
	vToDate   : string;
begin
	vEol := ParaDiff.Eol;
	if vEol = '' then
		vEol := #10;
	
	vStarted := False;
	vM := TSequenceMatcher.Create( ParaDiff.A, ParaDiff.B );
	try
		for vG in vM.GetGroupedOpCodes( ParaDiff.Context ) do
		begin
			if not vStarted then
			begin
				vStarted := True;
				vFromDate := '';
				if ParaDiff.FromDate <> '' then
					vFromDate := #9 + ParaDiff.FromDate;
				vToDate := '';
				if ParaDiff.ToDate <> '' then
					vToDate := #9 + ParaDiff.ToDate;
				
				if ( ParaDiff.FromFile <> '' ) or ( ParaDiff.ToFile <> '' ) then
				begin
					ParaWriter.Write( Format( '--- %s%s%s', [ ParaDiff.FromFile, vFromDate, vEol ] ) );
					ParaWriter.Write( Format( '+++ %s%s%s', [ ParaDiff.ToFile, vToDate, vEol ] ) );
				end;
			end;
			
			vFirst := vG[ 0 ];
			vLast := vG[ High( vG ) ];
			vRange1 := FormatRangeUnified( vFirst.I1, vLast.I2 );
			vRange2 := FormatRangeUnified( vFirst.J1, vLast.J2 );
			ParaWriter.Write( Format( '@@ -%s +%s @@%s', [ vRange1, vRange2, vEol ] ) );
			
			for vC in vG do
			begin
				if vC.Tag = Ord( 'e' ) then
				begin
					for vI := vC.I1 to vC.I2 - 1 do
						ParaWriter.Write( ' ' + ParaDiff.A[ vI ] );
					continue;
				end;
				
				if ( vC.Tag = Ord( 'r' ) ) or ( vC.Tag = Ord( 'd' ) ) then
				begin
					for vI := vC.I1 to vC.I2 - 1 do
						ParaWriter.Write( '-' + ParaDiff.A[ vI ] );
				end;
				
				if ( vC.Tag = Ord( 'r' ) ) or ( vC.Tag = Ord( 'i' ) ) then
				begin
					for vI := vC.J1 to vC.J2 - 1 do
						ParaWriter.Write( '+' + ParaDiff.B[ vI ] );
				end;
			end;
		end;
	finally
		vM.Free;
	end;
end;

function GetUnifiedDiffString( const ParaDiff : TUnifiedDiff ) : string;
var
	vStream : TStringStream;
	vWriter : TStreamWriter;
begin
	vStream := TStringStream.Create;
	try
		vWriter := TStreamWriter.Create( vStream );
		try
			WriteUnifiedDiff( vWriter, ParaDiff );
		finally
			vWriter.Free;
		end;
		Result := vStream.DataString;
	finally
		vStream.Free;
	end;
end;

function SplitLines( const ParaS : string ) : TArray<string>;
var
	vLines : TStringList;
	vI     : Integer;
begin
	vLines := TStringList.Create;
	try
		vLines.Text := ParaS;
		SetLength( Result, vLines.Count );
		for vI := 0 to vLines.Count - 1 do
			Result[ vI ] := vLines[ vI ] + #10; // Simple approximation of SplitAfter in Go
	finally
		vLines.Free;
	end;
end;

end.
