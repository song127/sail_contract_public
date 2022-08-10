require('dotenv').config();

const HDWalletProvider = require('@truffle/hdwallet-provider');

const getEnv = env => {
  const value = process.env[env];

  if (typeof value === 'undefined') {
    throw new Error('ENV NOT SET');
  }

  return value;
}

const mainPrivate = getEnv('MAIN_WALLET_PRIVATE');
const testPrivate = getEnv('TEST_WALLET_PRIVATE');
const localPri = getEnv('LOCAL_PRIVATE');

const mainURL = getEnv('MAIN_URL');
const rinURL = getEnv('RIN_URL');
const kURL = getEnv('KOVAN_URL');
const mURL = getEnv('MUMBAI_URL');

const mainID = getEnv('MAIN_NETWORK_ID');
const rinID = getEnv('RIN_NETWORK_ID');
const kID = getEnv('KOVAN_ID');
const mID = getEnv('MUMBAI_ID');

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */
  networks: {
    dev: {
      provider: () => new HDWalletProvider(localPri, 'HTTP://127.0.0.1:7545'),
      host: "127.0.0.1",     // Localhost (default: none)
      port: 7545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
      skipDryRun: true
    },
    main: {
      provider: () => new HDWalletProvider(mainPrivate, mainURL),
      network_id: mainID,
      gas: 2900000,
      gasPrice: 35000000000,
      skipDryRun: false
    },
    rinkeby: {
      provider: () => new HDWalletProvider(testPrivate, rinURL),
      network_id: rinID,       // Ropsten's id
      gas: 5500000,        // Ropsten has a lower block limit than mainnet
      skipDryRun: false     // Skip dry run before migrations? (default: false for public nets )
    },
    kovan: {
      provider: () => new HDWalletProvider(testPrivate, kURL),
      network_id: kID,       // Ropsten's id
      gas: 5500000,        // Ropsten has a lower block limit than mainnet
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },
    matic: {
      provider: () => new HDWalletProvider(testPrivate , mURL),
      network_id: 80001,
      gas: 6000000,
      skipDryRun: true
    },
  },

  // Set default mocha options here, use special reporters, etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.14",      // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solidity docs for advice about optimization and evmVersion
      //  optimizer: {
      //    enabled: false,
      //    runs: 200
      //  },
      //  evmVersion: "byzantium"
      // }
    }
  },

  // Truffle DB is currently disabled by default; to enable it, change enabled:
  // false to enabled: true. The default storage location can also be
  // overridden by specifying the adapter settings, as shown in the commented code below.
  //
  // NOTE: It is not possible to migrate your contracts to truffle DB and you should
  // make a backup of your artifacts to a safe location before enabling this feature.
  //
  // After you backed up your artifacts you can utilize db by running migrate as follows:
  // $ truffle migrate --reset --compile-all
  //
  // db: {
  //   enabled: false,
  //   host: "127.0.0.1",
  //   adapter: {
  //     name: "sqlite",
  //     settings: {
  //       directory: ".db"
  //     }
  //   }
  // }
};
