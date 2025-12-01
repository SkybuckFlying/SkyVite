unit Cmd.Utils.CustomFlags;

interface

uses
	System.SysUtils,
	System.Classes,
	System.IOUtils,
	System.StrUtils,
	Cli,
	Common;

type
	TDirectoryString = class
	private
		mValue: string;
		function GetValue: string;
		procedure SetValue(const ParaValue: string);
	public
		property Value: string read GetValue write SetValue;
		function ToString: string; override;
	end;

	TDirectoryFlag = class(TFlag)
	private
		mValue: TDirectoryString;
	public
		constructor Create(const ParaName, ParaUsage, ParaDefaultValue: string);
		destructor Destroy; override;
		function GetName: string; override;
		function GetUsage: string; override;
		function ToString: string; override;
		property Value: TDirectoryString read mValue;
	end;

function ExpandPath(const ParaPath: string): string;

implementation

function ExpandPath(const ParaPath: string): string;
var
	vHome: string;
begin
	Result := ParaPath;
	if (Result.StartsWith('~/')) or (Result.StartsWith('~\')) then
	begin
		vHome := TCommon.HomeDir;
		if vHome <> '' then
		begin
			Result := vHome + Result.Substring(1);
		end;
	end;
	Result := TPath.GetFullPath(Result);
end;

function PrefixedNames(const ParaFullName: string): string;
var
	vParts: TStringDynArray;
	vName: string;
	vIndex: Integer;
begin
	vParts := ParaFullName.Split([',']);
	Result := '';
	for vIndex := 0 to High(vParts) do
	begin
		vName := Trim(vParts[vIndex]);
		Result := Result + Format('%s%s', [PrefixFor(vName), vName]);
		if vIndex < High(vParts) then
		begin
			Result := Result + ', ';
		end;
	end;
end;

function PrefixFor(const ParaName: string): string;
begin
	if Length(ParaName) = 1 then
	begin
		Result := '-';
	end
	else
	begin
		Result := '--';
	end;
end;

{ TDirectoryString }

function TDirectoryString.GetValue: string;
begin
	Result := mValue;
end;

procedure TDirectoryString.SetValue(const ParaValue: string);
begin
	mValue := ExpandPath(ParaValue);
end;

function TDirectoryString.ToString: string;
begin
	Result := mValue;
end;

{ TDirectoryFlag }

constructor TDirectoryFlag.Create(const ParaName, ParaUsage, ParaDefaultValue: string);
begin
	inherited Create(ParaName, ParaUsage);
	try
		mValue := TDirectoryString.Create;
		mValue.Value := ParaDefaultValue;
	except
		on E: EOutOfMemory do
		begin
			// Handle memory allocation failure
			raise;
		end;
	end;
end;

destructor TDirectoryFlag.Destroy;
begin
	mValue.Free;
	inherited;
end;

function TDirectoryFlag.GetName: string;
begin
	Result := inherited Name;
end;

function TDirectoryFlag.GetUsage: string;
begin
	Result := inherited Usage;
end;

function TDirectoryFlag.ToString: string;
var
	vFmtString: string;
begin
	vFmtString := '%s %s'#9'%s';
	if Length(mValue.Value) > 0 then
	begin
		vFmtString := '%s "%s"'#9'%s';
	end;
	Result := Format(vFmtString, [PrefixedNames(Name), mValue.Value, Usage]);
end;

end.