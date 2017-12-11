var Upgradable = artifacts.require("./ProductManager.sol")


contract("Upgradable", ([alice, bob, carol, vick, ...accounts]) => {

    it("should know the block it was created on", () => {
        var upgradable
        return Upgradable.deployed().then((instance) => {
            upgradable = instance;
            return upgradable.executeUpgrade(0, 700)
        }).then((tx) => {
            return upgradable.upgradeBlock.call()
        }).then((block) => {
            assert(block > 0)
            return upgradable.gracePeriod.call()
        }).then((period) => {
            assert.equal(period, 700)
        })
    })
})
