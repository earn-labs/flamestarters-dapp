# FLAMESTARTERS-SMART-CONTRACTS 🔥

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg?style=for-the-badge)
![Forge](https://img.shields.io/badge/Forge-v0.2.0-blue?style=for-the-badge)

<!-- ABOUT THE PROJECT -->
## About The Project

![FlameStarters](https://github.com/earn-labs/flamestarters-dapp/blob/master/frontend/public/flamestarters_header.jpg?raw=true)

A NFT collection of 177 unique AI-generated and human-curated pieces designed to ignite the EARNer in you! Collect rare characters like flintstone from the earliest days of mankind, or mint a bougie designer lighter. Hidden within the collection are seven legendary pieces that stand apart from all others.

This repository contains the smart contract and deployment/testing suite to create the collection.

### Smart Contracts on BSC Testnet

**Payment Token Contract**  
https://testnet.bscscan.com/address/0x17ce1f8de9235ec9aacd58c56de5f8ea4bd8e063

**NFT Contract**  
https://testnet.bscscan.com/address/0xf72d5237b5ad316944c7c57d5f4df8aebebbebcd

### Smart Contracts Mainnet

**Payment Token Contract**   
https://bscscan.com/token/0xb0bcb4ede80978f12aa467f7344b9bdbcd2497f3

**NFT Contract**  
https://bscscan.com/address/0x0528C4DFc247eA8b678D0CA325427C4ca639DEC2

<!-- GETTING STARTED -->
## Getting Started

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/trashpirate/flamestarters-dapp.git
   ```
2. Navigate to the project directory
   ```sh
   cd flamestarters-dapp/contracts
   ```
3. Install Forge submodules
   ```sh
   forge install
   ```

### Usage

#### Compiling
```sh
forge compile
```

#### Testing locally

Run local tests:  
```sh
forge test
```

Run test with bsc mainnet fork:
1. Start local test environment
    ```sh
    make fork
    ```
2. Run fork tests
    ```sh
    forge test
    ```

#### Deploy to BSC testnet

1. Create test wallet using keystore. Enter private key of test wallet when prompted.
    ```sh
    cast wallet import Testing --interactive
    ```
    
2. Deploy to BSC testnet
    ```sh
    make deploy ARGS=\"--network bsctest\"
    ```

#### Deploy to BSC mainnet
1. Create deployer wallet using keystore. Enter private key of deployer wallet when prompted.
    ```sh
    cast wallet import <KeystoreName> --interactive
    ```
    
2. Deploy to BSC mainnet
    ```sh
    make deploy ARGS=\"--network bscmain\"
    ```

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.



