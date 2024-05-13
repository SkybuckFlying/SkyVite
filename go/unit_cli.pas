unit unit_cli;

{

This is a Delphi Pascal code that implements an application with a command-line interface (CLI). The app allows users to define commands, flags, and actions. Here's a breakdown of the code:

**Main App Class**

The `TApp` class represents the main application. It has several properties and methods for managing commands, flags, and actions.

* `FCommands`: an array of `TCommand` objects that represent individual commands.
* `FFlags`: an array of `TFlag` objects that represent command-line flags (e.g., `-h`, `--help`).
* `FCategories`: an array of `TCommandCategory` objects that group related commands together.
* `FAction`: a procedure that will be executed when a command is run.
* `FDidSetup`: a boolean flag indicating whether the app has been set up (initialized).

**Setup Method**

The `Setup` method initializes the app by setting up the command-line interface, including parsing the app's metadata and configuring the commands, flags, and categories.

**Run Method**

The `Run` method is the entry point for the app. It takes an array of strings as input representing the command-line arguments. The method:



}

interface

uses
  SysUtils,
  Classes,
  Generics.Collections;

type
  TFlag = record
	Name: string;
	Usage: string;
	Value: string;
	Hidden: Boolean;
  end;

  TCommand = record
	Name: string;
	Usage: string;
	Hidden: Boolean;
  end;

  TCommandCategory = record
	Name: string;
	Commands: array of TCommand;
  end;

  TAuthor = record
	Name: string;
	Email: string;
  end;

  TApp = class
  private
	FName: string;
    FHelpName: string;
    FUsage: string;
    FUsageText: string;
	FArgsUsage: string;
    FVersion: string;
    FDescription: string;
	FCommands: TArray<TCommand>;
	FFlags: TArray<TFlag>;
    FEnableBashCompletion: Boolean;
    FHideHelp: Boolean;
    FHideVersion: Boolean;
	FCategories: array of TCommandCategory;
	FBashComplete: TProc;
	FBefore: TProc;
	FAfter: TProc;
	FAction: TProc;
	FCommandNotFound: TProc;
	FOnUsageError: TProc;
	FCompiled: TDateTime;
	FAuthors: TArray<TAuthor>;
    FCopyright: string;
    FWriter: TTextWriter;
    FErrWriter: TTextWriter;
	FMetadata: TDictionary<string, TObject>;
    FExtraInfo: TFunc<TDictionary<string, string>>;
    FCustomAppHelpTemplate: string;
	FDidSetup: Boolean;
	function GetCategories: TArray<TCommandCategory>;
	function GetVisibleCategories: TArray<TCommandCategory>;
	function GetVisibleCommands: TArray<TCommand>;
	function GetVisibleFlags: TArray<TFlag>;
	function HasFlag(const Flag: TFlag): Boolean;
//	function ErrWriter: TTextWriter;
	procedure AppendFlag(const Flag: TFlag);
  public
	constructor Create;
	procedure Setup;
	procedure Run(const Arguments: TArray<string>);
	procedure RunAndExitOnError;
	procedure RunAsSubcommand(const Context: TObject);
	function Command(const Name: string): TCommand;
	property Name: string read FName write FName;
	property HelpName: string read FHelpName write FHelpName;
	property Usage: string read FUsage write FUsage;
	property UsageText: string read FUsageText write FUsageText;
	property ArgsUsage: string read FArgsUsage write FArgsUsage;
	property Version: string read FVersion write FVersion;
	property Description: string read FDescription write FDescription;
	property Commands: TArray<TCommand> read FCommands write FCommands;
	property Flags: TArray<TFlag> read FFlags write FFlags;
	property EnableBashCompletion: Boolean read FEnableBashCompletion write FEnableBashCompletion;
	property HideHelp: Boolean read FHideHelp write FHideHelp;
	property HideVersion: Boolean read FHideVersion write FHideVersion;
	property Categories: TArray<TCommandCategory> read GetCategories;
	property VisibleCategories: TArray<TCommandCategory> read GetVisibleCategories;
	property VisibleCommands: TArray<TCommand> read GetVisibleCommands;
	property VisibleFlags: TArray<TFlag> read GetVisibleFlags;
	property BashComplete: TProc read FBashComplete write FBashComplete;
	property Before: TProc read FBefore write FBefore;
	property After: TProc read FAfter write FAfter;
	property Action: TProc read FAction write FAction;
	property CommandNotFound: TProc read FCommandNotFound write FCommandNotFound;
	property OnUsageError: TProc read FOnUsageError write FOnUsageError;
	property Compiled: TDateTime read FCompiled write FCompiled;
	property Authors: TArray<TAuthor> read FAuthors write FAuthors;
	property Copyright: string read FCopyright write FCopyright;
	property Writer: TTextWriter read FWriter write FWriter;
//	property ErrWriter: TTextWriter read FErrWriter write FErrWriter;
	property Metadata: TDictionary<string, TObject> read FMetadata write FMetadata;
	property ExtraInfo: TFunc<TDictionary<string, string>> read FExtraInfo write FExtraInfo;
	property CustomAppHelpTemplate: string read FCustomAppHelpTemplate write FCustomAppHelpTemplate;
  end;

implementation

uses
  DateUtils;

constructor TApp.Create;
begin
  FName := ExtractFileName(ParamStr(0));
  FHelpName := ExtractFileName(ParamStr(0));
  FUsage := 'A new cli application';
  FUsageText := '';
  FVersion := '0.0.0';
  FCompiled := Now;
  FWriter := TTextWriter.Create;
end;

procedure TApp.Setup;
var
  I: Integer;
  C: TCommand;
  Category: TCommandCategory;
begin
  if FDidSetup then
    Exit;

  FDidSetup := True;

  if FAuthors <> nil then
  begin
    for I := 0 to Length(FAuthors) - 1 do
      FAuthors[I].Name := FAuthors[I].Name;
  end;

  SetLength(FCommands, Length(FCommands) + 1);
  C := FCommands[Length(FCommands) - 1];
  if C.HelpName = '' then
    C.HelpName := Format('%s %s', [FHelpName, C.Name]);

  if FCommandNotFound = nil then
	FCommandNotFound := procedure
      begin
        Writeln('Command not found');
      end;

  if FWriter = nil then
    FWriter := TTextWriter.Create;

  if FErrWriter = nil then
    FErrWriter := TTextWriter.Create;

  if FMetadata = nil then
    FMetadata := TDictionary<string, TObject>.Create;

  if FExtraInfo = nil then
    FExtraInfo := function: TDictionary<string, string>
      begin
        Result := TDictionary<string, string>.Create;
      end;

  if FCustomAppHelpTemplate = '' then
    FCustomAppHelpTemplate := '';

  if FCommandNotFound = nil then
    FCommandNotFound := procedure
      begin
        Writeln('Command not found');
	  end;

  if FWriter = nil then
    FWriter := TTextWriter.Create;

  if FErrWriter = nil then
    FErrWriter := TTextWriter.Create;

  if FMetadata = nil then
    FMetadata := TDictionary<string, TObject>.Create;

  if FExtraInfo = nil then
    FExtraInfo := function: TDictionary<string, string>
      begin
        Result := TDictionary<string, string>.Create;
      end;

  if FCustomAppHelpTemplate = '' then
    FCustomAppHelpTemplate := '';

  SetLength(FCategories, Length(FCategories) + 1);
  Category := FCategories[Length(FCategories) - 1];
  for I := 0 to Length(FCommands) - 1 do
  begin
    if FCommands[I].Category = Category.Name then
    begin
      SetLength(Category.Commands, Length(Category.Commands) + 1);
      Category.Commands[Length(Category.Commands) - 1] := FCommands[I];
    end;
  end;
end;

procedure TApp.Run(const Arguments: TArray<string>);
var
  I: Integer;
  ShellComplete: Boolean;
  Set: TDictionary<string, string>;
  Err: Exception;
  Context: TObject;
  Args: TArray<string>;
  Name: string;
  C: TCommand;
begin
  Setup;

  ShellComplete := False;
  Set := TDictionary<string, string>.Create;
  try
    for I := 1 to Length(Arguments) - 1 do
    begin
      if Arguments[I] = '--completion' then
      begin
        ShellComplete := True;
        Break;
      end;
      Set.Add(Arguments[I], '');
    end;

    if ShellComplete then
    begin
      if Assigned(FBashComplete) then
        FBashComplete;
      Exit;
    end;

    if Set.Count > 0 then
    begin
      for I := 0 to Length(FFlags) - 1 do
      begin
        if Set.ContainsKey(FFlags[I].Name) then
          FFlags[I].Value := Set[FFlags[I].Name];
      end;
    end;

    Context := TObject.Create;
    try
      Args := TArray<string>.Create;
      for I := 1 to Length(Arguments) - 1 do
        Args := Args + [Arguments[I]];
      if Length(Args) > 0 then
      begin
        Name := Args[0];
        C := Command(Name);
        if Assigned(C) then
        begin
          Context := C;
          C.Run(Context);
          Exit;
        end;
      end;

      if Assigned(FAction) then
        FAction(Context);
    finally
      Context.Free;
    end;
  finally
    Set.Free;
  end;
end;

procedure TApp.RunAndExitOnError;
begin
  try
    Run(ParamStr(0));
  except
    on E: Exception do
    begin
      Writeln(E.Message);
      Halt(1);
    end;
  end;
end;

procedure TApp.RunAsSubcommand(const Context: TObject);
var
  I: Integer;
  Set: TDictionary<string, string>;
  Err: Exception;
  Args: TArray<string>;
  Name: string;
  C: TCommand;
begin
  Setup;

  Set := TDictionary<string, string>.Create;
  try
    Args := TArray<string>.Create;
    for I := 1 to Length(Arguments) - 1 do
      Args := Args + [Arguments[I]];
    if Length(Args) > 0 then
    begin
	  Name := Args[0];
      C := Command(Name);
      if Assigned(C) then
      begin
        Context := C;
        C.Run(Context);
		Exit;
	  end;
    end;

    if Assigned(FAction) then
      FAction(Context);
  finally
    Set.Free;
  end;
end;

function TApp.Command(const Name: string): TCommand;
var
  I: Integer;
begin
  for I := 0 to Length(FCommands) - 1 do
  begin
    if FCommands[I].Name = Name then
      Exit(FCommands[I]);
  end;
  Result := nil;
end;

function TApp.GetCategories: TArray<TCommandCategory>;
begin
  Result := FCategories;
end;

function TApp.GetVisibleCategories: TArray<TCommandCategory>;
var
  I: Integer;
  Category: TCommandCategory;
begin
  Result := [];
  for I := 0 to Length(FCategories) - 1 do
  begin
    Category := FCategories[I];
    if Length(Category.Commands) > 0 then
      Result := Result + [Category];
  end;
end;

function TApp.GetVisibleCommands: TArray<TCommand>;
var
  I: Integer;
begin
  Result := [];
  for I := 0 to Length(FCommands) - 1 do
  begin
    if not FCommands[I].Hidden then
      Result := Result + [FCommands[I]];
  end;
end;

function TApp.GetVisibleFlags: TArray<TFlag>;
var
  I: Integer;
begin
  Result := [];
  for I := 0 to Length(FFlags) - 1 do
  begin
    if not FFlags[I].Hidden then
      Result := Result + [FFlags[I]];
  end;
end;

function TApp.HasFlag(const Flag: TFlag): Boolean;
var
  I: Integer;
begin
  for I := 0 to Length(FFlags) - 1 do
  begin
    if Flag = FFlags[I] then
      Exit(True);
  end;
  Result := False;
end;

function TApp.ErrWriter: TTextWriter;
begin
  if Assigned(FErrWriter) then
    Result := FErrWriter
  else
    Result := ErrOutput;
end;

procedure TApp.AppendFlag(const Flag: TFlag);
begin
  if not HasFlag(Flag) then
  begin
    SetLength(FFlags, Length(FFlags) + 1);
    FFlags[Length(FFlags) - 1] := Flag;
  end;
end;

procedure HandleAction(const Action: TProc; const Context: TObject);
begin
  if Assigned(Action) then
    Action(Context);
end;


end.
