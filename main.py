import click

from api import (
    deploy_manager_contract,
    get_proposals,
    accept_proposal,
    propose_iteration,
    check_share_value,
    check_balance,
    check_total_supply,
    check_total_value,
    redeem_shares,
)


@click.group()
def bevy():
    pass


@bevy.command()
def init():
    """
    bevy init

    Initialize a git repo as a bevy managed project by generating a config file
    to be committed to the repo

    Or if it's already a bevy managed project, initialize as a contributor

    """

    click.echo("bevy init called")


@bevy.command()
def proposals():
    get_proposals()


@bevy.command("total-supply")
def total_supply():
    return check_total_supply()


@bevy.command("redeem")
@click.argument('amount')
def redeem_cmd(amount):
    return redeem_shares(amount)
