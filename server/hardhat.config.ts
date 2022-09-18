import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  defaultNetwork: "moonbase",
  networks: {
    moonbase: {
      url: "https://moonbase-alpha.public.blastapi.io",
      chainId: 1287,
      accounts: ["0xe57432df862d2c4708c1ff2d1ae3079725b409c419d6a9f4f2d40ed361923b68"]
    }
  },
  paths:{
    artifacts: "../client/src/artifacts",
  }
};

export default config;
