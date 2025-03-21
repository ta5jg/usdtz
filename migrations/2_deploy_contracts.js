// var MyContract = artifacts.require("./MyContract.sol");
const FlashTetherTRC20 = artifacts.require("FlashTetherTRC20");

module.exports = function (deployer) {
    deployer.deploy(FlashTetherTRC20, 500000000, 10000000000, "TJGz93nx1LXPMioQnHH3d7e1XovpnDU1h3");
};
