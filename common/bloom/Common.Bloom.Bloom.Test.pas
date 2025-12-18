unit Common.Bloom.Bloom.Test;

interface

uses
  Common.Bloom.Bloom,
  Common.Bloom.Bucket,
  Common.Bloom.Util,
  Common.Types,
  DUnitX.TestFramework,
  System.SysUtils;

type
	[TestFixture]
	TFilterTests = class(TObject)
	public
		[Test]
		procedure TestFilter_record;
		[Test]
		procedure TestFilter_LookAndRecord;
	end;

implementation

uses
	System.Math,
	System.Generics.Collections;

procedure TFilterTests.TestFilter_record;
var
	vCount: Integer;
	vFilter: IFilter;
	vMap: TDictionary<THash, Boolean>;
	vIndex: Integer;
	vHash: THash;
	vFailed: Integer;
begin
	vCount := 10000;
	vFilter := NewFilter(vCount, 0.01);
	vMap := TDictionary<THash, Boolean>.Create;
	try
		for vIndex := 0 to vCount - 1 do
		begin
			SetLength(vHash, THashSize);
			Randomize;
			Tether.Context.Random.NextBytes(vHash);
			if not vMap.ContainsKey(vHash) then
			begin
				vMap.Add(vHash, True);
				vFilter.Add(vHash);
			end;
		end;

		vFailed := 0;
		for vHash in vMap.Keys do
		begin
			if not vFilter.Test(vHash) then
			begin
				Inc(vFailed);
			end;
		end;
		Assert.AreEqual(0, vFailed, Format('failed %d, total: %d', [vFailed, vCount]));
	finally
		vMap.Free;
	end;
end;

procedure TFilterTests.TestFilter_LookAndRecord;
var
	vCount: Integer;
	vFilter: IFilter;
	vMap: TDictionary<THash, Boolean>;
	vIndex: Integer;
	vHash: THash;
	vFailed: Integer;
	vExist: Boolean;
begin
	vCount := 10000;
	vFilter := NewFilter(vCount, 0.01);
	vCount := vCount * 10;
	vMap := TDictionary<THash, Boolean>.Create;
	try
		vFailed := 0;
		for vIndex := 0 to vCount - 1 do
		begin
			SetLength(vHash, THashSize);
			Randomize;
			Tether.Context.Random.NextBytes(vHash);
			if not vMap.ContainsKey(vHash) then
			begin
				vMap.Add(vHash, True);
				vExist := vFilter.TestAndAdd(vHash);
				if vExist then
				begin
					Inc(vFailed);
				end;

				vExist := vFilter.TestAndAdd(vHash);
				if not vExist then
				begin
					Inc(vFailed);
				end;
			end;
		end;
		Log.d(Format('failed %d, count: %d', [vFailed, vCount]));
	finally
		vMap.Free;
	end;
end;

initialization
	TDUnitX.RegisterTestFixture(TFilterTests);
end.
