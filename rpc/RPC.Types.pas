{
  Copyright 2022 The Delphi-Vite Authors
  This file is part of the Delphi-Vite library.

  The Delphi-Vite library is free software: you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  The Delphi-Vite library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with the Delphi-Vite library. If not, see <http://www.gnu.org/licenses/>.
}

unit Vite.Rpc.Types;

interface

uses
  System.SysUtils, System.Classes, System.Rtti,
  Vite.Rpc.Server, Vite.Rpc.Errors;

type
  TApi = record
    Namespace: string;
    Version: string;
    Service: TObject;
    Public: Boolean;
  end;

  TServerRequest = record
    Id: TValue;
    SvcName: string;
    Callb: TCallback;
    Args: TArray<TValue>;
    IsUnsubscribe: Boolean;
    Err: Exception;
  end;

implementation

end.
