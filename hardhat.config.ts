import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        details: {
          yul: true,
          yulDetails: {
            stackAllocation: true,
            optimizerSteps: "u",
          },
        },
      },
    },
  },
};

export default config;
