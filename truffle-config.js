const HDWalletProvider = require('@truffle/hdwallet-provider');
const dotenv = require('dotenv').config();

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 8545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
    },

    goerli: {
       provider: () => new HDWalletProvider(process.env.MNENOMIC, process.env.INFURA_API_KEY, 0, 10),
       network_id: "*",       // Ropsten's id
       gas: 5500000,        // Ropsten has a lower block limit than mainnet
       confirmations: 1,    // # of confs to wait between deployments. (default: 0)
       networkCheckTimeout: "100000",
       timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
       skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },

    ropsten: {
       provider: () => new HDWalletProvider(process.env.MNENOMIC, `https://ropsten.infura.io/v3/`+ process.env.INFURA_API_KEY, 0, 10),
       network_id: 3,       // Ropsten's id
       gas: 5500000,        // Ropsten has a lower block limit than mainnet
       confirmations: 1,    // # of confs to wait between deployments. (default: 0)
       networkCheckTimeout: "100000",
       timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
       skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },

    mainnet: {
       provider: () => new HDWalletProvider(process.env.MNENOMIC, `https://mainnet.infura.io/v3/`+ process.env.INFURA_API_KEY, 0, 10),
       network_id: 1,
       gas: 5500000,  
       gasPrice: 2000000000,  // check https://ethgasstation.info/
       confirmations: 2,    // # of confs to wait between deployments. (default: 0)
       timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
       skipDryRun: false     // Skip dry run before migrations? (default: false for public nets )
      }
    },

  mocha: {
    enableTimeouts: false
  },

  compilers: {
    solc: {
       version: "0.7.0",
    }
  }
}

// mainnet: {
//   provider: () => new HDWalletProvider(process.env.MAINNET_MNEMONIC, "https://mainnet.infura.io/v3/" + infuraProjectId),
//   network_id: 1,       // mainnet
//   gas: 5500000,  
//   gasPrice: 2000000000,  // check https://ethgasstation.info/
//   confirmations: 2,    // # of confs to wait between deployments. (default: 0)
//   timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
//   skipDryRun: false     // Skip dry run before migrations? (default: false for public nets )
// },