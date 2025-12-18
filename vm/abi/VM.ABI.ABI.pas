unit VM.ABI.ABI;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  GoVite.Types, VM.ABI.Argument, VM.ABI.Method, VM.ABI.Event, VM.ABI.Variable;

type
  EAbiError = class(Exception);

  TAbiContract = class
  private
    FConstructor: TMethod;
    FMethods: TDictionary<string, TMethod>;
    FCallbacks: TDictionary<string, TMethod>;
    FOffChains: TDictionary<string, TMethod>;
    FEvents: TDictionary<string, TEvent>;
    FVariables: TDictionary<string, TVariable>;
    procedure LoadFromFields(const AFields: TArray<TJSONObject>);
    class function GetEventInputs(const AArgs: TArray<TArgument>): TPair<TArray<TArgument>, TArray<TArgument>>; static;
    class function GetCallbackName(const AName: string): string; static;
    function PackMethodInternal(const AMethod: TMethod; const AArgs: array of TValue): TBytes;
  public
    constructor Create; overload;
    constructor Create(const AJSON: string); overload;
    destructor Destroy; override;
    class function FromJSON(AReader: TTextReader): TAbiContract; static;

    function PackMethod(const AName: string; const AArgs: array of TValue): TBytes;
    function PackCallback(const AName: string; const AArgs: array of TValue): TBytes;
    function PackOffChain(const AName: string; const AArgs: array of TValue): TBytes;
    function PackVariable(const AName: string; const AArgs: array of TValue): TBytes;
    function PackEvent(const AName: string; const AArgs: array of TValue): TTuple<TArray<THash>, TBytes>;

    procedure UnpackMethod(var AValue: TValue; const AName: string; const AInput: TBytes);
    function DirectUnpackMethodInput(const AName: string; const AInput: TBytes): TArray<TValue>;
    function DirectUnpackOffchainOutput(const AName: string; const AOutput: TBytes): TArray<TValue>;
    procedure UnpackEvent(var AValue: TValue; const AName: string; const AInput: TBytes);
    function DirectUnpackEvent(const ATopics: TArray<THash>; const AData: TBytes): TTuple<string, TArray<TValue>>;
    procedure UnpackVariable(var AValue: TValue; const AName: string; const AInput: TBytes);

    function MethodById(const ASigData: TBytes): TMethod;
    function EventID(const AName: string): THash;

    property Constructor: TMethod read FConstructor;
    property Methods: TDictionary<string, TMethod> read FMethods;
    property Events: TDictionary<string, TEvent> read FEvents;
  end;

implementation

uses
  System.Rtti;

{ TAbiContract }

constructor TAbiContract.Create;
begin
  inherited;
  FMethods := TDictionary<string, TMethod>.Create;
  FCallbacks := TDictionary<string, TMethod>.Create;
  FOffChains := TDictionary<string, TMethod>.Create;
  FEvents := TDictionary<string, TEvent>.Create;
  FVariables := TDictionary<string, TVariable>.Create;
end;

constructor TAbiContract.Create(const AJSON: string);
var
  LJSON: TJSONArray;
  LFields: TArray<TJSONObject>;
  I: Integer;
  LValue: TJSONValue;
begin
  Create;
  LJSON := TJSONObject.ParseJSONValue(AJSON) as TJSONArray;
  if not Assigned(LJSON) then
    raise EAbiError.Create('Invalid ABI JSON format');
  try
    SetLength(LFields, LJSON.Count);
    for I := 0 to LJSON.Count - 1 do
    begin
       LValue := LJSON.Items[i];
       if LValue is TJSONObject then
          LFields[I] := LValue as TJSONObject;
    end;
    LoadFromFields(LFields);
  finally
    LJSON.Free;
  end;
end;

destructor TAbiContract.Destroy;
begin
  FMethods.Free;
  FCallbacks.Free;
  FOffChains.Free;
  FEvents.Free;
  FVariables.Free;
  inherited;
end;

class function TAbiContract.FromJSON(AReader: TTextReader): TAbiContract;
var
  LJsonStr: string;
begin
  LJsonStr := AReader.ReadToEnd;
  Result := TAbiContract.Create(LJsonStr);
end;

procedure TAbiContract.LoadFromFields(const AFields: TArray<TJSONObject>);
var
  Field: TJSONObject;
  FieldType, FieldName: string;
  Inputs, Outputs, Indexed, NonIndexed: TArray<TArgument>;
  Name: string;
begin
  for Field in AFields do
  begin
    FieldType := Field.GetValue<string>('type', '');
    FieldName := Field.GetValue<string>('name', '');
    Inputs := TArgument.FromJSONArray(Field.GetValue<TJSONArray>('inputs'));
    Outputs := TArgument.FromJSONArray(Field.GetValue<TJSONArray>('outputs'));

    case FieldType of
      'constructor': FConstructor := TMethod.Create('', Inputs, nil);
      'function', '': FMethods.Add(FieldName, TMethod.Create(FieldName, Inputs, nil));
      'callback':
        begin
          Name := GetCallbackName(FieldName);
          FCallbacks.Add(Name, TMethod.Create(Name, Inputs, nil));
        end;
      'offchain': FOffChains.Add(FieldName, TMethod.Create(FieldName, Inputs, Outputs));
      'event':
        begin
          var LEventInputs := GetEventInputs(Inputs);
          Indexed := LEventInputs.Item1;
          NonIndexed := LEventInputs.Item2;
          FEvents.Add(FieldName, TEvent.Create(FieldName, Inputs, Indexed, NonIndexed));
        end;
      'variable':
        begin
          if Length(Inputs) = 0 then
            raise EAbiError.Create('Invalid empty variable input');
          FVariables.Add(FieldName, TVariable.Create(FieldName, Inputs));
        end;
    end;
  end;
end;

function TAbiContract.PackMethod(const AName: string; const AArgs: array of TValue): TBytes;
var
  Method: TMethod;
begin
  if AName = '' then // Constructor
  begin
    Result := FConstructor.Inputs.Pack(AArgs);
  end
  else
  begin
    if not FMethods.TryGetValue(AName, Method) then
      raise EAbiError.CreateFmt('Method ''%s'' not found', [AName]);
    Result := PackMethodInternal(Method, AArgs);
  end;
end;

// ... other Pack/Unpack methods would be implemented similarly ...

function TAbiContract.MethodById(const ASigData: TBytes): TMethod;
var
  Pair: TPair<string, TMethod>;
begin
  if Length(ASigData) < 4 then
    raise EAbiError.Create('Method ID not specified');

  for Pair in FMethods do
  begin
    if TBytes.Equals(Pair.Value.ID, ASigData) then
      Exit(Pair.Value);
  end;
  raise EAbiError.CreateFmt('No method with ID %s', [THex.Encode(ASigData)]);
end;

end.
