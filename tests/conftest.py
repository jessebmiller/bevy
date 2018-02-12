import pytest


@pytest.fixture()
def deploy(chain):

    def deploy(contract_name, _from=None):
        if _from is None:
            contract, _ = chain.provider.get_or_deploy_contract(contract_name)
        else:
            contract, _ = chain.provider.get_or_deploy_contract(
                contract_name,
                deploy_transaction={"from": _from},
            )
        return contract

    return deploy


@pytest.fixture()
def pay(chain):

    def pay(_from, to, value):
        chain.web3.eth.sendTransaction({
            "from": _from,
            "to": to,
            "value": value,
        })

    return pay


@pytest.fixture()
def wei(web3):

    def wei(value, denomination):
        return web3.toWei(value, denomination)

    return wei


@pytest.fixture()
def alice(chain):
    return chain.web3.eth.accounts[0]


@pytest.fixture()
def bob(chain):
    return chain.web3.eth.accounts[1]


@pytest.fixture()
def carol(chain):
    return chain.web3.eth.accounts[2]


@pytest.fixture()
def eve(chain):
    return chain.web3.eth.accounts[3]


@pytest.fixture()
def vick(chain):
    return chain.web3.eth.accounts[4]


@pytest.fixture()
def transact(chain):

    def transact(contract, method_name, *args, **kwargs):
        method = contract.transact(kwargs).__getattr__(method_name)
        txn_hash = method(*args)
        return chain.wait.for_receipt(txn_hash)

    return transact


@pytest.fixture()
def sha3b(chain):
    """ sha3 bytes """

    def wrapped(plaintext):
        return chain.web3.toBytes(hexstr=chain.web3.sha3(text=plaintext))

    return wrapped


@pytest.fixture()
def setup(chain, project, transact, pay, alice, bob, carol, sha3b, wei):
    # set the context so that the active chain has a manager contract
    # and that the manager address is correctly configured
    os.environ["active_chain"] = "tester"
    chains["tester"] = chain
    manager_contract_name = "ProductManagerV2"
    os.environ["manager_contract"] = manager_contract_name
    pm = configured("manager_contract")

    # configure an active user address
    os.environ["user_address"] = bob

    # set up an interesting state on that contract
    proof = sha3b("some iteration")
    amount = {
        bob: 1001,
        alice: 2002,
    }
    pay_amount = wei(7, "ether")
    transact(pm, "claimAuthorship", bob, proof, _from=bob)
    transact(pm, "proposeIteration", bob, proof, 'uri', _from=bob)
    transact(pm, "acceptProposal", bob, proof, amount[bob], _from=alice)
    transact(pm, "acceptProposal", alice, proof, amount[alice], _from=alice)

    pay(carol, pm.address, pay_amount)

    return {
        "manager_address": pm.address,
        "manager_contract": pm,
        "amount": amount,
        "paid": pay_amount,
        "proof": proof,
        "chain": chain,
        "user": bob,
    }
