package nodemanager

import (
	"encoding/json"
	"fmt"

	"gopkg.in/urfave/cli.v1"

	"github.com/vitelabs/go-vite/v2/node"
	nodeconfig "github.com/vitelabs/go-vite/v2/node/config"
)

type LocalNodeMaker struct {
}

func (maker LocalNodeMaker) MakeNode(ctx *cli.Context) (*node.Node, error) {
	// 1: Make Node.Config
	nodeConfig, err := maker.MakeNodeConfig(ctx)
	if err != nil {
		return nil, err
	}
	nodeConfigBytes, _ := json.MarshalIndent(nodeConfig, "", "  ")
	log.Info(fmt.Sprintf("NodeConfig info:\n%s", string(nodeConfigBytes)))
	// 2: New Node
	node, err := node.New(nodeConfig)

	if err != nil {
		log.Error("Failed to create the node: %v", err)
		return nil, err
	}
	return node, nil
}

func (maker LocalNodeMaker) MakeNodeConfig(ctx *cli.Context) (*nodeconfig.Config, error) {
	cfg := &nodeconfig.DefaultNodeConfig
	cfgBytes, _ := json.MarshalIndent(cfg, "", "  ")
	log.Info(fmt.Sprintf("DefaultNodeconfig:\n%s", string(cfgBytes)))

	// 1: Load config file.
	err := loadNodeConfigFromFile(ctx, cfg)
	if err != nil {
		return nil, err
	}
	cfgBytes, _ = json.MarshalIndent(cfg, "", "  ")
	log.Info(fmt.Sprintf("After load config file:\n%s", string(cfgBytes)))

	// 2: Apply flags, Overwrite the configuration file configuration
	mappingNodeConfig(ctx, cfg)
	cfgBytes, _ = json.MarshalIndent(cfg, "", "  ")
	log.Info(fmt.Sprintf("After mapping cmd input:\n%s", string(cfgBytes)))

	// 3: Override any default configs for hard coded networks.
	overrideNodeConfigs(ctx, cfg)
	cfgBytes, _ = json.MarshalIndent(cfg, "", "  ")
	log.Info(fmt.Sprintf("Last override config:\n%s", string(cfgBytes)))
	log.Info(fmt.Sprintf("NodeServer.DataDir:%v", cfg.DataDir))
	log.Info(fmt.Sprintf("NodeServer.KeyStoreDir:%v", cfg.KeyStoreDir))

	// make local
	makeLocalNodeCfg(ctx, cfg)

	// 4: Config log to file
	makeRunLogFile(cfg)

	return cfg, nil
}

func makeLocalNodeCfg(ctx *cli.Context, cfg *nodeconfig.Config) {
	// single mode
	cfg.Single = true
	// no miner
	cfg.MinerEnabled = false
	// no ledger gc
	ledgerGc := false
	cfg.LedgerGc = &ledgerGc
}
