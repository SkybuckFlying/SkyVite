unit Interfaces.Core.Serializable;

interface

uses
  System.SysUtils;

type
  ISerializable = interface(IInterface)
    ['{B8F5F3E9-449B-473F-B52F-3833927A56C1}']
    function Serialize(out ParaError: Exception): TBytes;
    function Deserialize(const ParaBuf: TBytes): Exception;
  end;

implementation

end.
