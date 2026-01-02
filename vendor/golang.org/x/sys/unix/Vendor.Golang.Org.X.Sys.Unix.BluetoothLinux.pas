unit Vendor.Golang.Org.X.Sys.Unix.BluetoothLinux;

interface

const
  BTPROTO_L2CAP  = 0;
  BTPROTO_HCI    = 1;
  BTPROTO_SCO    = 2;
  BTPROTO_RFCOMM = 3;
  BTPROTO_BNEP   = 4;
  BTPROTO_CMTP   = 5;
  BTPROTO_HIDP   = 6;
  BTPROTO_AVDTP  = 7;

  HCI_CHANNEL_RAW     = 0;
  HCI_CHANNEL_USER    = 1;
  HCI_CHANNEL_MONITOR = 2;
  HCI_CHANNEL_CONTROL = 3;
  HCI_CHANNEL_LOGGING = 4;

  SOL_BLUETOOTH = $112;
  SOL_HCI       = $0;
  SOL_L2CAP     = $6;
  SOL_RFCOMM    = $12;
  SOL_SCO       = $11;

implementation

end.
