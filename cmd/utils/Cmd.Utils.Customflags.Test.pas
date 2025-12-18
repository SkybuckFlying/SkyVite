unit Cmd.Utils.CustomFlags.Test;

interface

uses
  Cmd.Utils.Cli,
  Cmd.Utils.Customflags,
  Cmd.Utils.Flags,
  Cmd.Utils.Path,
  DUnitX.TestFramework,
  System.IOUtils,
  System.SysUtils;

type
	[TestFixture]
	TCustomFlagsTests = class(TObject)
	public
		[Test]
		procedure TestPathExpansion;
	end;

implementation

uses
	Cmd.Utils.CustomFlags;

{ TCustomFlagsTests }

procedure TCustomFlagsTests.TestPathExpansion;
var
	vHomePath: string;
	vExpandedPath: string;
begin
	vHomePath := TPath.GetHomePath;
	Assert.IsFalse(vHomePath = '', 'Home path should not be empty');

	vExpandedPath := ExpandPath('~/test');
	Assert.AreEqual(TPath.Combine(vHomePath, 'test'), vExpandedPath);
end;

initialization
	RegisterTestFixture(TCustomFlagsTests);
end.
