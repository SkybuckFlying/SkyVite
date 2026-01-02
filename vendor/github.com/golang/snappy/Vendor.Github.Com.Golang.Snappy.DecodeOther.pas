{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Golang.Snappy.DecodeOther;

interface

function decode( ParaDst, ParaSrc : TArray<Byte> ) : Integer;

implementation

const
	tagLiteral = $00;
	tagCopy1   = $01;
	tagCopy2   = $02;
	tagCopy4   = $03;

	decodeErrCodeCorrupt = -1;
	decodeErrCodeUnsupportedLiteralLength = -2;

function decode( ParaDst, ParaSrc : TArray<Byte> ) : Integer;
var
	vD, vS, vOffset, vLength : Integer;
	vX : Cardinal;
	vIndex : Integer;
begin
	vD := 0;
	vS := 0;
	while vS < Length( ParaSrc ) do
	begin
		case ParaSrc[ vS ] and $03 of
			tagLiteral:
			begin
				vX := ParaSrc[ vS ] shr 2;
				if vX < 60 then
				begin
					Inc( vS );
				end else if vX = 60 then
				begin
					vS := vS + 2;
					if vS > Length( ParaSrc ) then Exit( decodeErrCodeCorrupt );
					vX := ParaSrc[ vS - 1 ];
				end else if vX = 61 then
				begin
					vS := vS + 3;
					if vS > Length( ParaSrc ) then Exit( decodeErrCodeCorrupt );
					vX := ParaSrc[ vS - 2 ] or ( ParaSrc[ vS - 1 ] shl 8 );
				end else if vX = 62 then
				begin
					vS := vS + 4;
					if vS > Length( ParaSrc ) then Exit( decodeErrCodeCorrupt );
					vX := ParaSrc[ vS - 3 ] or ( ParaSrc[ vS - 2 ] shl 8 ) or ( ParaSrc[ vS - 1 ] shl 16 );
				end else if vX = 63 then
				begin
					vS := vS + 5;
					if vS > Length( ParaSrc ) then Exit( decodeErrCodeCorrupt );
					vX := ParaSrc[ vS - 4 ] or ( ParaSrc[ vS - 3 ] shl 8 ) or ( ParaSrc[ vS - 2 ] shl 16 ) or ( ParaSrc[ vS - 1 ] shl 24 );
				end;

				vLength := vX + 1;
				if ( vLength <= 0 ) or ( vLength > Length( ParaDst ) - vD ) or ( vLength > Length( ParaSrc ) - vS ) then
					Exit( decodeErrCodeCorrupt );

				Move( ParaSrc[ vS ], ParaDst[ vD ], vLength );
				vD := vD + vLength;
				vS := vS + vLength;
				Continue;
			end;

			tagCopy1:
			begin
				vS := vS + 2;
				if vS > Length( ParaSrc ) then Exit( decodeErrCodeCorrupt );
				vLength := 4 + ( ( ParaSrc[ vS - 2 ] shr 2 ) and $07 );
				vOffset := ( ( ParaSrc[ vS - 2 ] and $E0 ) shl 3 ) or ParaSrc[ vS - 1 ];
			end;

			tagCopy2:
			begin
				vS := vS + 3;
				if vS > Length( ParaSrc ) then Exit( decodeErrCodeCorrupt );
				vLength := 1 + ( ParaSrc[ vS - 3 ] shr 2 );
				vOffset := ParaSrc[ vS - 2 ] or ( ParaSrc[ vS - 1 ] shl 8 );
			end;

			tagCopy4:
			begin
				vS := vS + 5;
				if vS > Length( ParaSrc ) then Exit( decodeErrCodeCorrupt );
				vLength := 1 + ( ParaSrc[ vS - 5 ] shr 2 );
				vOffset := ParaSrc[ vS - 4 ] or ( ParaSrc[ vS - 3 ] shl 8 ) or ( ParaSrc[ vS - 2 ] shl 16 ) or ( ParaSrc[ vS - 1 ] shl 24 );
			end;
		end;

		if ( vOffset <= 0 ) or ( vD < vOffset ) or ( vLength > Length( ParaDst ) - vD ) then
			Exit( decodeErrCodeCorrupt );

		if vOffset >= vLength then
		begin
			Move( ParaDst[ vD - vOffset ], ParaDst[ vD ], vLength );
		end else
		begin
			for vIndex := 0 to vLength - 1 do
				ParaDst[ vD + vIndex ] := ParaDst[ vD - vOffset + vIndex ];
		end;
		vD := vD + vLength;
	end;

	if vD <> Length( ParaDst ) then Exit( decodeErrCodeCorrupt );
	Result := 0;
end;

end.
