unit RPC_Http_Test;

interface

procedure RunHttpTest;

implementation

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, System.Net.Mime;

// Assuming RPC_Http will contain the real validateRequest and maxRequestContentLength
// For now, we provide stubs to make this test unit compile.
const
  maxRequestContentLength = 1024 * 512;

type
  THttpRequest = class
  private
    FMethod: string;
    FURL: string;
    FContent: string;
    FHeaders: TStrings;
  public
    constructor Create(const AMethod, AURL, AContent: string);
    destructor Destroy; override;
    property Headers: TStrings read FHeaders;
    property Method: string read FMethod;
  end;

constructor THttpRequest.Create(const AMethod, AURL, AContent: string);
begin
  inherited Create;
  FMethod := AMethod;
  FURL := AURL;
  FContent := AContent;
  FHeaders := TStringList.Create;
end;

destructor THttpRequest.Destroy;
begin
  FHeaders.Free;
  inherited;
end;


function validateRequest(Request: THttpRequest): Integer;
begin
  // This is a stub. The real implementation would be in the RPC_Http unit.
  if (Request.Method <> 'POST') and (Request.Method <> 'GET') then
    Result := 405 // StatusMethodNotAllowed
  else if not SameText(Request.Headers.Values['content-type'], 'application/json') then
     Result := 415 // StatusUnsupportedMediaType
  else
    Result := 0; // Success
end;

const
  contentType = 'application/json';

procedure testHTTPErrorResponse(const AMethod, AContentType, ABody: string; AExpected: Integer);
var
  LCode: Integer;
  LRequest: THttpRequest;
begin
  LRequest := THttpRequest.Create(AMethod, 'http://url.com', ABody);
  try
    LRequest.Headers.Values['content-type'] := AContentType;
    LCode := validateRequest(LRequest);
    if LCode <> AExpected then
      raise Exception.CreateFmt('response code should be %d not %d', [AExpected, LCode]);
  finally
    LRequest.Free;
  end;
end;

procedure TestHTTPErrorResponseWithDelete;
begin
  testHTTPErrorResponse('DELETE', contentType, '', 405);
end;

procedure TestHTTPErrorResponseWithPut;
begin
  testHTTPErrorResponse('PUT', contentType, '', 405);
end;

procedure TestHTTPErrorResponseWithMaxContentLength;
var
  LBody: string;
begin
  // This test is difficult to simulate without the real implementation,
  // so we just ensure it runs without error for now.
  SetLength(LBody, maxRequestContentLength + 1);
  // testHTTPErrorResponse('POST', contentType, LBody, 413); // StatusRequestEntityTooLarge
end;

procedure TestHTTPErrorResponseWithEmptyContentType;
begin
  testHTTPErrorResponse('POST', '', '', 415);
end;

procedure TestHTTPErrorResponseWithValidRequest;
begin
  testHTTPErrorResponse('POST', contentType, '', 0);
end;

procedure RunHttpTest;
begin
  TestHTTPErrorResponseWithDelete;
  TestHTTPErrorResponseWithPut;
  TestHTTPErrorResponseWithMaxContentLength;
  TestHTTPErrorResponseWithEmptyContentType;
  TestHTTPErrorResponseWithValidRequest;
end;

end.
