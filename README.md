# TURBOTAIL- ARTWORK

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg?style=for-the-badge)
![Node](https://img.shields.io/badge/node-v20.10.0-blue.svg?style=for-the-badge)
![NPM](https://img.shields.io/badge/npm-v10.2.3-blue?style=for-the-badge)
[![License: MIT](https://img.shields.io/github/license/trashpirate/hold-earn.svg?style=for-the-badge)](https://github.com/trashpirate/hold-earn/blob/main/LICENSE)

[![Website: nadinaoates.com](https://img.shields.io/badge/Portfolio-00e0a7?style=for-the-badge&logo=Website)](https://nadinaoates.com)
[![LinkedIn: nadinaoates](https://img.shields.io/badge/LinkedIn-0a66c2?style=for-the-badge&logo=LinkedIn&logoColor=f5f5f5)](https://linkedin.com/in/nadinaoates)
[![Twitter: N0_crypto](https://img.shields.io/badge/@N0_crypto-black?style=for-the-badge&logo=X)](https://twitter.com/N0_crypto)

<!-- ![Nextjs](https://img.shields.io/badge/next-v13.5.4-blue?style=for-the-badge)
![Tailwindcss](https://img.shields.io/badge/TailwindCSS-v3.0-blue?style=for-the-badge)
![Wagmi](https://img.shields.io/badge/Wagmi-v1.4.3-blue?style=for-the-badge) -->

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#installation">Installation</a></li>
        <li><a href="#usage">Usage</a></li>
      </ul>
    </li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <!-- <li><a href="#acknowledgments">Acknowledgments</a></li> -->
  </ol>
</details>

<!-- ABOUT THE PROJECT -->

## About The Project

![TurboTails](#)

This repository contains the smart contract and deployment/testing suite to create an NFT (Non-Fungible Token) collection consisting of 10000 unique  images known as "TurboTails." These fun pets in fast cars come with many different traits of varying rarity. The entire process, from renaming files to generating metadata files, is designed to facilitate the upload of the collection to [IPFS](https://ipfs.tech/).

<!-- GETTING STARTED -->

## Getting Started

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/trashpirate/turbotails-artwork.git
   ```
2. Navigate to the project directory
   ```sh
   cd turbotails-artwork
   ```
3. Install NPM packages
   ```sh
   npm install
   ```

### Usage

**IPFS Storage:** 

images: ipfs://bafybeibjoz7wbjpajjf6dgg3l6djy4kltutg45fhhnnuc5qjqo2po5qbfe  
metadata: ipfs://bafybeia46ygme5csjbmqa73eacqcxmkfmmsajzkgvcxcr7a6tv2bl26nla

The images and parts of the metadata were generated with Photoshop and [GENFTY](https://www.genfty.com/).

#### Generate Metadata for IPFS

1. Upload `images` directory to IPFS
2. Update IPFS url, and metadata information in `generateMetadata.ts` script.
3. Run script
   ```sh
    ts-node --files src/generateMetadata.ts
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

<!-- CONTACT -->

## Contact

Nadina Oates - [@N0_crypto](https://twitter.com/N0_crypto)

Main Repository: [https://github.com/trashpirate/flamelings](https://github.com/trashpirate/flamelings)

Project Link: [https://flame.buyholdearn.com/](https://flame.buyholdearn.com/)

<!-- ACKNOWLEDGMENTS -->
<!-- ## Acknowledgments -->
