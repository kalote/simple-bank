import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { config as LoadEnv } from "dotenv";

LoadEnv();

const config: HardhatUserConfig = {
  solidity: "0.8.17",
    networks: {
      goerli: {
        url: `https://goerli.infura.io/v3/${process.env.INFURA_KEY}`,
        accounts: [process.env.GOERLI_PRIVATE_KEY as string]
      }
    }
  };

export default config;
