require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: {
    compilers: [
      { version: "0.8.0", settings: { optimizer: { enabled: true, runs: 200 } } },
      { version: "0.8.20", settings: { optimizer: { enabled: true, runs: 200 } } },
      { version: "0.8.7", settings: { optimizer: { enabled: true, runs: 200 } } },
      { version: "0.8.13", settings: { optimizer: { enabled: true, runs: 200 } } },
      { version: "0.7.0" },
      { version: "0.6.6" },
      { version: "0.4.24" },
    ],
  },
  networks: {
    base: {
      url: "https://8453.rpc.thirdweb.com",
      accounts: [process.env.SECRET],
      chainId: 8453
    }
  },
  etherscan: {
    apiKey: "1G8X9N63I2UWGXN4A2JQTHUCJE1E6VMTFU"
  }
};
