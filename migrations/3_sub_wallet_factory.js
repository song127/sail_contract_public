const SubWalletFactory = artifacts.require("SubWalletFactory");


module.exports = function (deployer) {
  // Kovan
  deployer.deploy(SubWalletFactory,
      '0xd2Bc7E2931be40e6BAc40a742f5bf86567812F7B', // SubWallet BaseContract // set later
      '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D', // Uniswap
      '0xDD13CE9DE795E7faCB6fEC90E346C7F3abe342E2', // AaveEthAllow
      '0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70', // AaveEthGateway
      '0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe', // AavePools
      ['0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD'], // DepositTokens
      [],                                           // ShortTokens
      30);                                          // Max Create Wallet

  // Polygon Mumbai
  // deployer.deploy(SubWalletFactory,
  //     '0x5d33F27d2E70ffCB7419b78fC948D4B51910123D', // SubWallet BaseContract // set later
  //     '0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506', // Uniswap
  //     '0x11b884339E453E3d66A8E22246782D40E62cB5F2', // AaveEthAllow
  //     '0xee9eE614Ad26963bEc1Bec0D2c92879ae1F209fA', // AaveEthGateway
  //     '0x9198F13B08E299d85E096929fA9781A1E3d5d827', // AavePools
  //     ['0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F'], // DepositTokens
  //     [],                                           // ShortTokens
  //     30);                                          // Max Create Wallet
};