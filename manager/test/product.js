var Product = artifacts.require("./Product.sol");


contract("Product", function(accounts) {

    var alice = accounts[0]
    var bob = accounts[1]

    it("should start with zero supply", function() {
        return Product.deployed().then(function(instance) {
            return instance.totalSupply.call();
        }).then(function(supply) {
            assert.equal(supply, 0);
        });
    });

    it("should be owned by the first account", function () {
        return Product.deployed().then(function(instance) {
            return instance.owner.call();
        }).then(function(owner) {
            assert.equal(owner, alice, "Not owned by first account");
        });
    });
});

contract("Product.transferOwnership", function(accounts) {

    var alice = accounts[1];
    var bob = accounts[0];

    it("should be able to transfer ownership", function () {
        var product
        return Product.deployed().then(function(instance) {
            product = instance
            product.transferOwnership(bob);
            return product.owner.call();
        }).then(function(owner) {
            assert.equal(owner, bob, "Not owned by new owner");
            product.transferOwnership(alice, {from: bob});
            return product.owner.call();
        }).then(function(owner) {
            assert.equal(owner, alice, "owner not set back")
        });
    });
});

contract("Product Events", function(accounts) {

    var alice = accounts[1];
    var bob = accounts[0];

    it("should log claims of authorship", function () {
        var proof = web3.sha3("Bob's iteration and a nonce or something too");
        var logs;
        var product
        return Product.deployed().then(function(instance) {
            product = instance;
            return product.claimAuthorship(bob, proof);
        }).then(function(result) {
            return product.AuthorshipClaim({author: bob});
        }).then(function(authorshipClaimFilter) {
            authorshipClaimFilter.get(function(err, logs) {
                assert.equal(err, undefined);
                assert.equal(logs.length, 1);
                assert.equal(logs[0].args.author.valueOf(), bob);
                assert.equal(logs[0].args.proof.valueOf(), proof);
            })
        });
    });

    it("should log iteration proposals", function (done) {
        var proof = web3.sha3("Bob's iteration and a nonce or something too");
        var url = "https://url.url";
        var product;
        Product.deployed().then(function(instance) {
            product = instance;
            return product.proposeIteration(alice, proof, url);
        }).then(function(result) {
            return product.IterationProposal({author: alice});
        }).then(function(eventFilter) {
            eventFilter.get(function(err, logs) {
                assert.equal(err, undefined);
                assert.equal(logs.length, 1);
                assert.equal(logs[0].args.author.valueOf(), alice);
                assert.equal(logs[0].args.proof.valueOf(), proof);
                assert.equal(logs[0].args.location.valueOf(), url);
                done();
            });
        });
    });
});

contract("Product.acceptProposal", function(accounts) {

    var alice = accounts[0];
    var bob = accounts[1];

    it("should let the owner accept proposals", function () {
        var proof = web3.sha3("bob's iteration that alice wants to accept");
        var amount = 10000
        var results = {};
        var product;
        return Product.deployed().then(function(instance) {
            product = instance;
            return product.acceptProposal(bob, proof, amount, {from: alice});
        }).then(function(tx) {
            return product.totalSupply.call();
        }).then(function(totalSupply) {
            assert.equal(totalSupply, amount, "Total Supply is wrong");
            return product.balanceOf(bob);
        }).then(function(bobsBalance) {
            assert.equal(bobsBalance, amount, "Bob's balance is wrong");
            return product.proofOfProductionRelease.call();
        }).then(function(prodRelease) {
            assert.equal(prodRelease, proof, "Proof of production release is wrong");
        });
    });

    it("should only let the owner accept proposals", function () {
        var proof = web3.sha3("bob's proof that owner wants to accept");
        amount = 1000
        var failed = false;
        return Product.deployed().then(function(instance) {
            return instance.acceptProposal(bob, proof, amount, {from: bob});
        }).catch(function(err) {
            assert.equal(
                err.message,
                "VM Exception while processing transaction: invalid opcode");
            failed = true;
        }).then(function(result) {
            assert.equal(failed, true, "should have failed");
        });
    });
});

contract("Product fallback function", function(accounts) {

    var alice = accounts[0];
    var bob = accounts[1];

    it("should be payable", function () {
        var product;
        return Product.deployed().then(function(instance) {
            product = instance;
            return product.send(web3.toWei(1, "ether"));
        }).then(function(tx) {
            assert.equal(
                web3.eth.getBalance(product.address),
                web3.toWei(1, "ether"));
        });
    });

    it("should log payments", function (done) {
        Product.deployed().then(function(instance) {
            return instance.Payment({from: alice});
        }).then(function(paymentFilter) {
            paymentFilter.get(function(err, logs) {
                assert.equal(err, undefined);
                assert.equal(logs.length, 1);
                assert.equal(logs[0].args.from.valueOf(), alice);
                assert.equal(logs[0].args.amount.valueOf(), web3.toWei(1, "ether"));
                done();
            });
        });
    });
});

contract("Product.shareValue", function(accounts) {

    var alice = accounts[0];
    var bob = accounts[1];

    it("should report the value of it's shares", function() {
        var product;
        return Product.deployed().then(function(instance) {
            product = instance;
            return product.send(3);
        }).then(function(tx) {
            // accept a proposal that has not been proposed (this may break
            // in the future
            var proof = web3.sha3("some iteration");
            return product.acceptProposal(bob, proof, 2, {from: alice});
        }).then(function(tx) {
            return product.shareValue.call();
        }).then(function(shareValue) {
            assert.equal(shareValue, 1);
        });
    });

    it("should round down", function() {
        var product;
        return Product.deployed().then(function(instance) {
            product = instance;
            return product.totalSupply.call();
        }).then(function(supply) {
            // when supply is 2
            assert.equal(supply, 2);
            return web3.eth.getBalance(product.address);
        }).then(function(balance) {
            // and balance is 3
            assert.equal(balance, 3);
            return product.shareValue.call();
        }).then(function(shareValue) {
            // share value rounds down to 1
            assert.equal(shareValue, 1);
        });
    });
});

contract("Product.redeem", (accounts) => {

    var alice = accounts[0];
    var bob = accounts[1];

    it("should convert shares to ether", () => {
        var product;
        var amount = 1000
        var shareValue;
        var initialBalance;
        var payment = 1;
        return Product.deployed().then((instance) => {
            product = instance;
            // dilute for bob by amount
            return product.acceptProposal(
                bob, web3.sha3("proof"), amount, {from: alice});
        }).then((tx) => {
            // dilute for alice by amount
            return product.acceptProposal(
                alice, web3.sha3("proofx"), amount, {from: alice});
        }).then((tx) => {
            // pay contract 10 ether
            return product.send(web3.toWei(payment, "ether"));
        }).then((tx) => {
            return product.shareValue.call();
        }).then((value) => {
            shareValue = value;
            // value should be the floor of 10 ether devided by twice the amount
            assert.equal(
                shareValue,
                Math.floor(web3.toWei(payment, "ether") / (2 * amount)));
            return web3.eth.getBalance(bob);
        }).then((balance) => {
            initialBalance = balance;
            return product.redeem(500, {from: bob});
        }).then((tx) => {
            return web3.eth.getBalance(bob);
        }).then((balance) => {
            // bob should have 500 shares worth more ether than he did initially
            assert(shareValue * 500, balance - initialBalance);
            return web3.eth.getBalance(product.address);
        }).then((balance) => {
            // product should have 500 shares worth less ether than it did (10)
            assert(shareValue * 500, web3.toWei(payment, "ether") - balance);
        });
    });

    it("should not let accounts redeem more than their balance", function() {
        var failed = false;
        Product.deployed().then((instance) => {
            return instance.redeem(amount + 1, {from: alice});
        }).catch((err) => {
            assert.equal(
                "VM Exception while processing transaction: invalid opcode",
                err.message);
            failed = true;
        }).then((tx) => {
            assert.equal(failed, true, "allowed alice to redeem too much");
        });
    });
});
