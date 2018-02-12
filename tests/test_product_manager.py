import pytest
import math
from itertools import zip_longest
from eth_utils import force_obj_to_text
from ethereum.tester import TransactionFailed


def test_zero_initial_supply(deploy):
    pm = deploy("ProductManagerV1")
    total_supply = pm.call().totalSupply()
    assert total_supply == 0


def test_owned_by_creator(deploy, alice, bob):
    pm = deploy("ProductManagerV1", alice)
    assert alice == pm.call().owner()
    assert bob != pm.call().owner()


def test_transfer_ownership(deploy, transact, alice, bob, vick):
    pm = deploy("ProductManagerV1")
    transact(pm, "transferOwnership", bob)
    owner = pm.call().owner()
    assert owner == bob
    assert owner != vick


def test_product_events(deploy, sha3b, transact, alice, bob):
    pm = deploy("ProductManagerV1")

    proof = sha3b("some iteration")

    test_sets = [
        {
            # This transaction
            "transaction": (pm, "claimAuthorship", bob, proof),
            # should generate this event type
            "event_type": "AuthorshipClaim",
            # with this profile
            "log_profile": [{"author": bob, "proof": proof}],
        }, {
            "transaction": (pm, "proposeIteration", bob, proof, "uri"),
            "event_type": "IterationProposal",
            "log_profile": [{"author": bob, "proof": proof, "location": "uri"}]
        },
    ]

    def profile_logs(logs):
        return [l["args"] for l in logs]

    failure_messages = []
    for test_set in test_sets:
        # for each test set, check that the transaction specified creates the
        # logs that it should
        try:
            transact(*test_set["transaction"])
            filter_ = pm.pastEvents(test_set["event_type"])
            logs = filter_.get()
            log_profile = profile_logs(logs)
            # the web3 eventFilter.get function calls force_obj_to_text on
            # filter results, so we need to do the same to compare.
            expected_profile = force_obj_to_text(test_set["log_profile"])
            assert log_profile == expected_profile, "Got: {}, Want {}".format(
                log_profile, expected_profile,
            )
        except Exception as err:
            failure_messages.append(str(err))

    # expect no failure messages, but list them if there are any
    assert failure_messages == [], "\n".join(failure_messages)


def test_only_owner_can_accept_proposal(
        deploy,
        alice,
        bob,
        vick,
        sha3b,
        transact,
):
    pm = deploy("ProductManagerV1")
    proof = sha3b("some iteration")
    amount = 1000
    transact(pm, "acceptProposal", bob, proof, amount)
    assert pm.call().totalSupply() == amount, "Total supply is wrong"
    assert pm.call().balanceOf(bob) == amount, "Bob's balance is wrong"
    assert pm.call().proofOfProductionRelease() == force_obj_to_text(proof), \
        "Proof of production release is wrong"

    with pytest.raises(TransactionFailed):
        transact(pm, "acceptProposal", vick, proof, 3000, _from=vick)


def test_fallback_function_is_payable(deploy, alice, bob, pay, web3):
    pm = deploy("ProductManagerV1")
    # It should be payable
    amount = web3.toWei(10, "ether")
    pay(bob, pm.address, amount)
    assert web3.eth.getBalance(pm.address) == amount, "Unexpected balance"


def test_share_value(deploy, alice, bob, pay, sha3b, web3, transact):
    pm = deploy("ProductManagerV1")
    proof = sha3b("some iteration")

    pay(alice, pm.address, 3)
    transact(pm, "acceptProposal", bob, proof, 2)

    # When supply is 2
    assert pm.call().totalSupply() == 2
    # and balance is 3
    assert web3.eth.getBalance(pm.address) == 3
    # share value should round down to 1
    assert pm.call().shareValue() == 1, "Share value didn't round down to 1"


def test_redeem(deploy, alice, bob, pay, sha3b, transact, web3):
    pm = deploy("ProductManagerV1")
    dilute_amount = 1000
    payment = web3.toWei(10, "ether")
    proof = sha3b("some iteration")

    # Dilute for alice by dilute amount
    transact(pm, "acceptProposal", alice, proof, dilute_amount)
    # Dilute for bob by dilute amount
    transact(pm, "acceptProposal", bob, proof, dilute_amount)
    # Pay contract 10 ether
    pay(alice, pm.address, payment)

    # Share value should be the floor of the payment devided by twice the dilute
    # amount
    share_value = pm.call().shareValue()
    assert share_value == payment / (2 * dilute_amount), "Share value incorrect"

    # When alice redeems shares, she should have that many times the share value
    # more ether than she started with
    initial_balance = web3.eth.getBalance(bob)
    redeem_amount = 10
    transact(pm, "redeem", redeem_amount, _from=bob)
    updated_balance = web3.eth.getBalance(bob)

    # actual redeemed amount should take into account gas price
    expected_redeem_amount = share_value * redeem_amount
    actual_redeem_amount = updated_balance - initial_balance
    gas_allowance = 500000
    assert expected_redeem_amount > actual_redeem_amount, \
        "Redeem paid too much"
    assert expected_redeem_amount - gas_allowance < actual_redeem_amount, \
        "Redeem didn't pay enough"

    # Alice should not be able to redeem more than her share
    with pytest.raises(TransactionFailed):
        transact(pm, "redeem", 1001, _from=alice)


def test_user_can_upgrade(deploy, alice, bob, pay, transact, sha3b, wei):
    pm1 = deploy("ProductManagerV1")
    proof = sha3b("some iteration")

    # alice accepts her own iteration paying 1000 product shares
    transact(pm1, "acceptProposal", alice, proof, 1000)

    # alice accepts bobs iteration paying 1000 product shares
    transact(pm1, "acceptProposal", bob, proof, 1000)

    # total supply is 2000
    pre_total_supply = pm1.call().totalSupply()
    assert pre_total_supply == 2000

    # alice pays the contract 20 ether
    pay(alice, pm1.address, wei(20, "ether"))

    # share price should be 20 ether devided by 2000 shares (0.01 ether)
    pre_share_value = pm1.call().shareValue()
    assert pre_share_value == wei(0.01, "ether")

    # alice deploys and activates an upgraded product manager contract
    pm2 = deploy("ProductManagerv2")
    transact(pm1, "prepareUpgrade", pm2.address)
    transact(pm2, "activateUpgrade", pm1.address)
    assert pm1.call().nextVersion().lower() == pm2.address.lower()
    assert pm2.call().previousVersion().lower() == pm1.address.lower()

    # bob starts on the first version
    pre_bob_balance = pm1.call().balanceOf(bob)
    assert pre_bob_balance == 1000

    # bob moves to the upgraded version
    transact(pm2, "upgrade", _from=bob)

    # share value shouldn't change
    assert pm1.call().shareValue() == pre_share_value

    # supply should be reduced by bobs previous balance
    assert pm1.call().totalSupply() == pre_total_supply - pre_bob_balance

    # bob should have zero shares on the first version
    assert pm1.call().balanceOf(bob) == 0

    # bob should have his balance on the upgraded contract
    assert pm2.call().balanceOf(bob) == pre_bob_balance

    # the share prices of the two contracts should be the same
    assert pm2.call().shareValue() == pm1.call().shareValue()
