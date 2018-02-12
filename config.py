from inspect import signature, Signature
from functools import wraps
from populus.project import Project
import os


DEFAULT = object()

project = Project()

chains = {
    "tester": project.get_chain("tester"),
    "ropsten": project.get_chain("ropsten"),
    "testnet": project.get_chain("ropsten"),
    "mainnet": project.get_chain("mainnet"),
}


def get_contract_from_active_chain(name):
    """ Returns the named contract from the active chain """
    contract, _ = configured("active_chain").provider.get_or_deploy_contract(name)
    return contract


constructors = {
    "active_chain": lambda name: chains[name],
    "manager_contract": get_contract_from_active_chain,
}


def configured(key, default=DEFAULT):
    constructor = constructors.get(key, lambda x: x)
    if default is DEFAULT:
        return constructor(os.environ[key])
    else:
        return constructor(os.environ.get(key, default))


def inject_config(function):
    """
    Looks up, constructs and injects config values for anotated parameters

    annotated, configurable parameters must come after non configurable ones

    This works a little like defaults, but get's the value from the config.

    >>> @inject_config
    ... def get_recipe(spam: "spam_amount"):
    ...     print(", ".join(["spam" for x in range(int(spam))]), "and eggs")
    >>> import os
    >>> os.environ["spam_amount"] = "3"
    >>> get_recipe()
    spam, spam, spam and eggs

    """

    @wraps(function)
    def wrapper(*args, **kwargs):
        sig = signature(function)

        # for each parameter that wasn't passed as args
        for parameter_name in list(sig.parameters)[len(args):]:
            # and wasn't passed in kwargs
            if kwargs.get(parameter_name, DEFAULT) is DEFAULT:
                # set configured value based on the annotation key
                config_key = sig.parameters[parameter_name].annotation
                if config_key != Signature.empty:
                    kwargs[parameter_name] = configured(config_key)

        return function(*args, **kwargs)

    return wrapper
