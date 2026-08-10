package config

import (
	"errors"
	"strconv"
	"strings"

	"github.com/vitelabs/go-vite/v2/common/types"
)

type Producer struct {
	Producer         bool   `json:"Producer"`
	Coinbase         string `json:"Coinbase"`
	EntropyStorePath string `json:"EntropyStorePath"`

	coinbase types.Address
	index    uint32

	VirtualSnapshotVerifier bool `json:"VirtualSnapshotVerifier"`
}

func (cfg *Producer) IsMine() bool {
	if cfg == nil {
		return false
	}
	return cfg.Producer && cfg.Coinbase != ""
}

func (cfg Producer) GetCoinbase() types.Address {
	return cfg.coinbase
}

func (cfg Producer) GetIndex() uint32 {
	return cfg.index
}

func (cfg *Producer) Parse() error {
	if cfg.Coinbase != "" {
		coinbase, index, err := parseCoinbase(cfg.Coinbase)
		if err != nil {
			return err
		}
		cfg.coinbase = *coinbase
		cfg.index = index
	}
	return nil
}

func parseCoinbase(coinbaseCfg string) (*types.Address, uint32, error) {
    // Check if format is "index:address" or just "address"
    splits := strings.Split(coinbaseCfg, ":")
    
    var index uint32 = 0
    var addressStr string
    
    if len(splits) == 1 {
        // Format: just "vite_..." (no index)
        addressStr = splits[0]
        index = 0
    } else if len(splits) == 2 {
        // Format: "index:vite_..."
        i, err := strconv.Atoi(splits[0])
        if err != nil {
            return nil, 0, err
        }
        index = uint32(i)
        addressStr = splits[1]
    } else {
        return nil, 0, errors.New("invalid coinbase format")
    }
    
    addr, err := types.HexToAddress(addressStr)
    if err != nil {
        return nil, 0, err
    }
    
    return &addr, index, nil
}
