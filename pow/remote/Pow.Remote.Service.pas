unit Pow.Remote.Service;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math.BigInt,
  System.Net.HttpClient,
  System.JSON,
  Pow.Pow,
  Pow.Remote.Request,
  Pow.Remote.Response,
  Common.Log;

const
  ConstApiActionGenerate = '/api/generate_work';
  ConstApiActionValidate = '/api/validate_work';
  ConstApiActionCancel = '/api/cancel_work';

var
  gRequestUrl: string;
  gWorking: Boolean;
  gPowClientLog: ILogger;

procedure InitRawUrl(const ParaRawUrl: string);
function Working: Boolean;
function GenerateWork(const ParaDataHash: TBytes; const ParaDifficulty: TBigInteger; out ParaWork: string): Boolean;
function CancelWork(const ParaDataHash: TBytes): Boolean;
function VaildateWork(const ParaDataHash: TBytes; const ParaThreshold: TBigInteger; const ParaWork: TBytes): Boolean;

implementation

uses
  System.Net.HttpClientComponent,
  System.JSON.Serializers;

procedure InitRawUrl(const ParaRawUrl: string);
begin
  gRequestUrl := ParaRawUrl;
end;

function Working: Boolean;
begin
  Result := gRequestUrl <> '';
end;

function HttpRequest(const ParaRequestPath: string; const ParaBytesData: TBytes; const ParaResponseInterface: TObject): Boolean;
var
  vHttpClient: TNetHTTPClient;
  vHttpRequest: TNetHTTPRequest;
  vHttpResponse: IHTTPResponse;
  vResponseJson: TResponseJson;
  vJsonSerializer: TJsonSerializer;
begin
  Result := False;
  vHttpClient := TNetHTTPClient.Create(nil);
  try
    vHttpRequest := TNetHTTPRequest.Create(nil);
    try
      vHttpRequest.Client := vHttpClient;
      vHttpRequest.MethodString := 'POST';
      vHttpRequest.URL := ParaRequestPath;
      vHttpRequest.ContentType := 'application/json';
      vHttpRequest.Body.LoadFromBytes(ParaBytesData);
      vHttpResponse := vHttpRequest.Execute;
      gPowClientLog.Info('Response Status:', ['status', vHttpResponse.StatusText]);
      vJsonSerializer := TJsonSerializer.Create;
      try
        vResponseJson := vJsonSerializer.Deserialize<TResponseJson>(vHttpResponse.ContentAsString);
        if vResponseJson.Code <> 0 then
        begin
          raise Exception.Create(vResponseJson.Error);
        end;
        // The deserialization of the Data field needs to be handled carefully.
        // This is a simplified version.
        if ParaResponseInterface is TWorkGenerateResult then
        begin
          TWorkGenerateResult(ParaResponseInterface).Work := TJSONObject(vResponseJson.Data).GetValue<string>('work');
        end
        else if ParaResponseInterface is TWorkValidateResult then
        begin
          TWorkValidateResult(ParaResponseInterface).Valid := TJSONObject(vResponseJson.Data).GetValue<string>('valid');
        end;
        Result := True;
      finally
        vJsonSerializer.Free;
      end;
    finally
      vHttpRequest.Free;
    end;
  finally
    vHttpClient.Free;
  end;
end;

function GenerateWork(const ParaDataHash: TBytes; const ParaDifficulty: TBigInteger; out ParaWork: string): Boolean;
var
  vThreshold: TBigInteger;
  vWorkGenerate: TWorkGenerate;
  vBytesData: TBytes;
  vWorkResult: TWorkGenerateResult;
  vJsonSerializer: TJsonSerializer;
begin
  Result := False;
  if not Working then
  begin
    raise Exception.Create('not supported');
  end;
  vThreshold := DifficultyToTarget(ParaDifficulty);
  vWorkGenerate := TWorkGenerate.Create;
  try
    vWorkGenerate.Threshold := vThreshold.ToString(16);
    vWorkGenerate.DataHash := TEncoding.Default.GetString(ParaDataHash);
    vJsonSerializer := TJsonSerializer.Create;
    try
      vBytesData := TEncoding.Default.GetBytes(vJsonSerializer.Serialize(vWorkGenerate));
    finally
      vJsonSerializer.Free;
    end;
    vWorkResult := TWorkGenerateResult.Create;
    try
      if HttpRequest(gRequestUrl + ConstApiActionGenerate, vBytesData, vWorkResult) then
      begin
        ParaWork := vWorkResult.Work;
        Result := True;
      end;
    finally
      vWorkResult.Free;
    end;
  finally
    vWorkGenerate.Free;
  end;
end;

function CancelWork(const ParaDataHash: TBytes): Boolean;
var
  vWorkCancel: TWorkCancel;
  vBytesData: TBytes;
  vWorkResult: TWorkCancelResult;
  vJsonSerializer: TJsonSerializer;
begin
  Result := False;
  if not Working then
  begin
    Exit;
  end;
  vWorkCancel := TWorkCancel.Create;
  try
    vWorkCancel.DataHash := TEncoding.Default.GetString(ParaDataHash);
    vJsonSerializer := TJsonSerializer.Create;
    try
      vBytesData := TEncoding.Default.GetBytes(vJsonSerializer.Serialize(vWorkCancel));
    finally
      vJsonSerializer.Free;
    end;
    vWorkResult := TWorkCancelResult.Create;
    try
      if HttpRequest(gRequestUrl + ConstApiActionCancel, vBytesData, vWorkResult) then
      begin
        Result := True;
      end;
    finally
      vWorkResult.Free;
    end;
  finally
    vWorkCancel.Free;
  end;
end;

function VaildateWork(const ParaDataHash: TBytes; const ParaThreshold: TBigInteger; const ParaWork: TBytes): Boolean;
var
  vWorkValidate: TWorkValidate;
  vBytesData: TBytes;
  vValidateResult: TWorkValidateResult;
  vJsonSerializer: TJsonSerializer;
begin
  Result := False;
  vWorkValidate := TWorkValidate.Create;
  try
    vWorkValidate.DataHash := TEncoding.Default.GetString(ParaDataHash);
    vWorkValidate.Threshold := ParaThreshold.ToString(16);
    vWorkValidate.Work := TEncoding.Default.GetString(ParaWork);
    vJsonSerializer := TJsonSerializer.Create;
    try
      vBytesData := TEncoding.Default.GetBytes(vJsonSerializer.Serialize(vWorkValidate));
    finally
      vJsonSerializer.Free;
    end;
    vValidateResult := TWorkValidateResult.Create;
    try
      if HttpRequest(gRequestUrl + ConstApiActionValidate, vBytesData, vValidateResult) then
      begin
        if vValidateResult.Valid = '1' then
        begin
          Result := True;
        end;
      end;
    finally
      vValidateResult.Free;
    end;
  finally
    vWorkValidate.Free;
  end;
end;

initialization
  gPowClientLog := TLog15.New(['module', 'pow_request']);
end.
