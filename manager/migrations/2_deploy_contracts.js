var ProductManager = artifacts.require("./ProductManager.sol");

module.exports = function(deployer) {
    deployer.deploy(ProductManager, {gas: 6761676});
};
