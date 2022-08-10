const SubWallet = artifacts.require("SubWallet");

module.exports = function (deployer) {
  deployer.deploy(SubWallet);
};
