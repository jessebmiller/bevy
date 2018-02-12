import pytest
import os
from eth_utils import to_wei

from api import (
    check_share_value,
    check_balance,
    check_total_supply,
    check_total_value,
    redeem_shares,
)

from config import (
    chains,
    configured,
)


common_transaction_cost = 21000 * to_wei(10, "gwei")
def within(a, b, epsilon=common_transaction_cost):
    """ return true if a and b are within epsilon of each other """
    if a == b:
        return True
    elif a > b and a < b + epsilon:
        return True
    elif a < b and a > b - epsilon:
        return True
    return False


def test_check_total_supply(setup, transact, alice, bob, carol, sha3b):
    expected_amount = setup['amount'][bob] + setup['amount'][alice]
    assert check_total_supply() == expected_amount

    proof = sha3b("some iteration")
    pm = setup['manager_contract']
    carol_amount = 3333
    transact(pm, "acceptProposal", carol, proof, carol_amount)

    assert check_total_supply() == expected_amount + carol_amount


def test_check_share_value(setup, wei, bob, alice):
    expected_amount = setup['amount'][bob] + setup['amount'][alice]
    assert check_share_value() ==  setup['paid'] / expected_amount


def test_check_balance(setup, alice, bob):
    assert check_balance(alice) == setup['amount'][alice]
    assert check_balance(bob) == setup['amount'][bob]


def test_check_total_value(setup, wei, pay, alice):
    assert check_total_value() == setup['paid']

    amount = wei(2, "ether")
    pay(alice, setup['manager_address'], amount)
    assert check_total_value() == setup['paid'] + amount


def test_redeem_shares(setup, transact, web3):
    pm = setup['manager_contract']
    pre_share_balance = pm.call().balanceOf(setup['user'])
    pre_ether_balance = web3.eth.getBalance(setup['user'])

    redeem_amount = 500
    redeem_shares(redeem_amount)

    post_share_balance = pm.call().balanceOf(setup['user'])
    post_ether_balance = web3.eth.getBalance(setup['user'])

    share_value = pm.call().shareValue();

    assert pre_share_balance - redeem_amount == post_share_balance

    assert within(
        pre_ether_balance + share_value * redeem_amount,
        post_ether_balance,
    )
