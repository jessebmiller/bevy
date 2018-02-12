from config import inject_config


@inject_config
def check_share_value(manager: "manager_contract"):
    return manager.call().shareValue()


@inject_config
def check_balance(user: "user_address", manager: "manager_contract"):
    """ Check the user's balance of shares """
    return manager.call().balanceOf(user)


@inject_config
def check_total_supply(manager: "manager_contract"):
    """ check_total_supply displays the total number of shares """
    return manager.call().totalSupply()


@inject_config
def check_total_value(chain: "active_chain"):
    """ return the total value of the manager contract on the active chain """
    manager, _ = chain.provider.get_or_deploy_contract("ProductManagerV2")
    return chain.web3.eth.getBalance(manager.address)


@inject_config
def redeem_shares(
        amount,
        user: "user_address",
        manager: "manager_contract",
        chain: "active_chain",
):
    """ Redeem some amount of shares """
    txn_hash = manager.transact({"from": user}).redeem(amount)
    print("Transaction:", txn_hash)
    print("waiting for receipt")
    print("Receipt:", chain.wait.for_receipt(txn_hash))
