unit common.config.genesis_json;

interface
uses
  Common.Config.Chain,
  Common.Config.Config,
  Common.Config.Genesis,
  Common.Config.Genesis.Mock.Json,
  Common.Config.Genesis.Test,
  Common.Config.Net,
  Common.Config.Node.Reward,
  Common.Config.Producer,
  Common.Config.Subscribe,
  Common.Config.Upgrade,
  Common.Config.VM,
  Common.Config.Wallet;

// This unit is a placeholder for the large genesis_json.go file.
// The actual content (JSON string) would be embedded or loaded at runtime.

const
  MainnetGenesisJson = ''; // Placeholder for the large JSON string

implementation

end.
