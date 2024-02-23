-include .env

.PHONY: all test clean deploy

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# install dependencies
install :; forge install Cyfrin/foundry-devops --no-commit && forge install https://github.com/chiru-labs/ERC721A.git --no-commit && forge install OpenZeppelin/openzeppelin-contracts --no-commit

# update dependencies
update:; forge update

# compile
build:; forge build

# test
test :; forge test 

# take snapshot
snapshot :; forge snapshot

# format
format :; forge fmt

# spin up local test network
anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# spin up fork
fork :; @anvil --fork-url ${RPC_BSC_MAIN} --fork-block-number 35267180 --fork-chain-id 56 --chain-id 123

# Network Config
NETWORK_ARGS := --rpc-url http://127.0.0.1:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast -g 110
NETWORK_ARGS_OWNER := --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast -g 110
NETWORK_USER := --rpc-url http://127.0.0.1:8545 --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d --broadcast -g 110

ifeq ($(findstring --network bsctest,$(ARGS)),--network bsctest)
	NETWORK_ARGS := --rpc-url $(RPC_BSC_TEST) --account Testing --sender 0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF --broadcast --verify --etherscan-api-key $(BSCSCAN_KEY)
endif

ifeq ($(findstring --network bscmain,$(ARGS)),--network bscmain)
	NETWORK_ARGS := --rpc-url $(RPC_BSC_MAIN) --account EARN-Deployer --sender 0x4397122Ad9602aD358816F1f2De2396e3dCEb857 --broadcast --verify --etherscan-api-key $(BSCSCAN_KEY)
endif

ifeq ($(findstring --network bsctest --who user,$(ARGS)),--network bsctest --who user)
	NETWORK_ARGS := --rpc-url $(RPC_BSC_TEST) --account TestAccount1 --sender 0xCbA52038BF0814bC586deE7C061D6cb8B203f8e1 --broadcast --verify --etherscan-api-key $(BSCSCAN_KEY)
endif

# deployment
deploy: 
	@forge script script/deployment/DeployFlameStarters.s.sol:DeployFlameStarters $(NETWORK_ARGS)
	
# interactions
setbatchlimit: 
	@forge script script/interactions/OwnerInteractions.s.sol:SetNewBatchLimit $(NETWORK_ARGS)
	
setmaxperwallet: 
	@forge script script/interactions/OwnerInteractions.s.sol:SetNewMaxPerWallet $(NETWORK_ARGS)

mint: 
	@forge script script/interactions/UserInteractions.s.sol:MintNfts $(NETWORK_ARGS)

# security
slither :; slither ./src 


-include ${FCT_PLUGIN_PATH}/makefile-external