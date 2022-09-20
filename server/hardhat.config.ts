import { HardhatUserConfig } from "hardhat/config"
import { config as dotenvConfig } from "dotenv"
import { resolve } from "path"
import "@nomicfoundation/hardhat-toolbox"
import "@openzeppelin/hardhat-upgrades"

const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || "./.env";
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) })

const { PRIVATE_KEY } = process.env;

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  defaultNetwork: "moonbase",
  networks: {
    moonbase: {
      url: "https://moonbase-alpha.public.blastapi.io",
      chainId: 1287,
      accounts: [PRIVATE_KEY!]
    }
  },
  paths:{
    artifacts: "../client/src/artifacts",
  }
};

export default config;
