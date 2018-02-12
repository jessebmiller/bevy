from api import (
    propose_iteration,
)


def test_propose_iteration(setup):
    """
    Should claim authorship of some iteration, then reveal it and propose it

    Should only reveal and propose if the claim transaction is suitably
    confirmed.

    """

    propose_iteration()

    # The proof should be correct

    # The proof should be in some number of blocks before the proposal

    # The content at the URI should match the proof

    # 
