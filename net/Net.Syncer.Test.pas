unit Net.Syncer.Test;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Generics.Collections,
	Common.Types,
	Interfaces.Core.Snapshot.Block,
	Interfaces.Core.Hash.Height,
	Net.Syncer,
	Net.Skeleton,
	Net.Interface;

procedure TestSplitChunks;
procedure TestHashHeightTree;
procedure TestConstructTasks;

implementation

uses
	Net.Vnode; // for RandomNodeID

function MockHash : THash;
var
	vBytes : TBytes;
begin
	SetLength( vBytes, 32 );
	// In a real test, we would use a proper random generator
	// Security.Random.Read(vBytes);
	Result := THash.Create( vBytes );
end;

function RandomHash : THash;
begin
	Result := MockHash;
end;

procedure TestSplitChunks;
type
	TSample = record
		From, ToVal, Size : UInt64;
		Cs : TArray<TArray<UInt64>>;
	end;
var
	vSamples : TArray<TSample>;
	vSamp : TSample;
	vCs : TArray<TArray<UInt64>>;
	vI, vJ : Integer;
begin
	// Implementation of SplitChunk test
	// vCs := SplitChunk(vSamp.From, vSamp.ToVal, vSamp.Size);
end;

procedure TestHashHeightTree;
var
	vHashHeightList1, vHashHeightList2, vHashHeightList3 : TList<THashHeightPoint>;
	vTree : THashHeightTree;
	vList : TArray<THashHeight>;
	vHHP : THashHeightPoint;
	vI : Integer;
begin
	vHashHeightList1 := TList<THashHeightPoint>.Create;
	vHashHeightList2 := TList<THashHeightPoint>.Create;
	vHashHeightList3 := TList<THashHeightPoint>.Create;
	try
		for vI := 1 to 4 do
		begin
			vHHP := THashHeightPoint.Create;
			vHHP.HashHeight := THashHeight.Create( vI * 100, MockHash );
			vHashHeightList1.Add( vHHP );
		end;

		for vI := 1 to 5 do
		begin
			vHHP := THashHeightPoint.Create;
			vHHP.HashHeight := THashHeight.Create( vI * 100, MockHash );
			vHashHeightList2.Add( vHHP );
		end;

		vHashHeightList3.AddRange( vHashHeightList1 );
		vHHP := THashHeightPoint.Create;
		vHHP.HashHeight := THashHeight.Create( 500, MockHash );
		vHashHeightList3.Add( vHHP );

		vTree := THashHeightTree.Create;
		try
			// vTree.AddBranch(vHashHeightList1.ToArray, TPeer.Create(RandomNodeID, 100));
			// vTree.AddBranch(vHashHeightList2.ToArray, TPeer.Create(RandomNodeID, 100));
			// vTree.AddBranch(vHashHeightList3.ToArray, TPeer.Create(RandomNodeID, 100));

			vList := vTree.BestBranch;

			if Length( vList ) <> vHashHeightList3.Count then
			begin
				raise Exception.Create( 'wrong length' );
			end;
		finally
			vTree.Free;
		end;
	finally
		vHashHeightList1.Free;
		vHashHeightList2.Free;
		vHashHeightList3.Free;
	end;
end;

procedure TestConstructTasks;
var
	vHhs : TList<THashHeightPoint>;
	vI : UInt64;
	vPoint : THashHeight;
	vTs : TArray<TDownloadTask>;
	vPrevTask : TDownloadTask;
	vTT : TDownloadTask;
begin
	vHhs := TList<THashHeightPoint>.Create;
	try
		for vI := 100 to 10000 do
		begin
			if vI mod 100 = 0 then
			begin
				vHhs.Add( THashHeightPoint.Create( THashHeight.Create( vI, RandomHash ) ) );
			end;
		end;

		vPoint := THashHeight.Create( 99, RandomHash );
		// vTs := ConstructTasks(vHhs.ToArray);

		// prevTask := TDownloadTask.Create(2, vPoint.Height, vPoint.Hash);
		// for vTT in vTs do
		// begin
		//     if vTT.From <> vPrevTask.ToVal + 1 or vTT.PrevHash <> vPrevTask.Hash then
		//         raise Exception.Create('not continuous');
		//     vPrevTask := vTT;
		// end;
	finally
		vHhs.Free;
	end;
end;

end.
