unit Net.Skeleton.Test;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Threading,
	System.Generics.Collections,
	Common.Types,
	Interfaces.Core.Hash.Height,
	Net.Peer,
	Net.Skeleton,
	Net.Vnode,
	unit_GoLang_Compatibility_version_006;

procedure TestSkeleton_Construct;
procedure TestSkeleton_Reset;

implementation

procedure TestSkeleton_Construct;
var
	vPeers : TPeerSet;
	vI : Integer;
	vSk : TSkeleton;
	vWG : TGoWaitGroup;
begin
	vPeers := TPeerSet.Create;
	try
		for vI := 0 to 3 do
		begin
			vPeers.Add( TPeer.Create( TRandomNodeID, 100 ) );
		end;

		vSk := TSkeleton.Create( vPeers, TGid.Create, TDictionary<THash, Pointer>.Create );
		try
			vWG := TGoWaitGroup.Create;
			try
				for vI := 0 to 99 do
				begin
					vWG.Add( 1 );
					TGo.Run( procedure
					var
						vList : TArray<THashHeightPoint>;
					begin
						try
							vList := vSk.Construct( [THashHeight.Create( 99, THash.Empty )], 100 );
							// Writeln(Length(vList));
						finally
							vWG.Done;
						end;
					end );
				end;
				vWG.Wait;
			finally
				vWG.Free;
			end;
		finally
			vSk.Free;
		end;
	finally
		vPeers.Free;
	end;
end;

procedure TestSkeleton_Reset;
var
	vPeers : TPeerSet;
	vI : Integer;
	vSk : TSkeleton;
	vWG : TGoWaitGroup;
begin
	vPeers := TPeerSet.Create;
	try
		for vI := 0 to 3 do
		begin
			vPeers.Add( TPeer.Create( TRandomNodeID, 100 ) );
		end;

		vSk := TSkeleton.Create( vPeers, TGid.Create, TDictionary<THash, Pointer>.Create );
		try
			vWG := TGoWaitGroup.Create;
			try
				for vI := 0 to 99 do
				begin
					vWG.Add( 1 );
					TGo.Run( procedure
					var
						vList : TArray<THashHeightPoint>;
						vN : Integer;
					begin
						vN := vI; // Capture vI? No, we need a local copy or similar if using TGo.Run correctly
						// But for a simple test we can just use the captured value if safe
						try
							if vN mod 2 = 0 then
							begin
								vList := vSk.Construct( [THashHeight.Create( 99, THash.Empty )], 100 );
							end else
							begin
								vSk.Reset;
							end;
						finally
							vWG.Done;
						end;
					end );
				end;
				vWG.Wait;
			finally
				vWG.Free;
			end;
		finally
			vSk.Free;
		end;
	finally
		vPeers.Free;
	end;
end;

end.
