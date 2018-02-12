pragma solidity ^0.4.4;

import "./zeppelin-solidity/contracts/ownership/Ownable.sol";

/*
 * An upgradable contract is one with a next version and a previous version,
 * unless it is the first or most recent version, that it's users have the
 * to migrate to.
 */
contract Upgradable is Ownable {

  address public previousVersion;
  address public nextVersion;

  /*
   * Once the new version of the contract is deployed, and the previsous version
   * is prepaired the owner can activate the upgrade with an evaluation grace
   * period.
   */
  function activateUpgrade(address _previousVersion) onlyOwner {
    Upgradable pv = Upgradable(_previousVersion);
    // only if this is the next version of the previous version
    require(pv.nextVersion() == address(this));
    // and the owner of both contracts are the same
    require(pv.owner() == owner);
    // set the previous version
    previousVersion = _previousVersion;
  }

  /*
   * Prepare this contract for it's upgrade to be activated
   */
  function prepareUpgrade(address _nextVersion) onlyOwner {
    Upgradable nextContract = Upgradable(_nextVersion);
    // only if the next version is owned by the same owner
    require(nextContract.owner() == owner);
    // and the next version is not set
    require(nextVersion == address(0));
    // set the next version
    nextVersion = _nextVersion;
  }

  /*
   * In case a buggy or bad next version causes an un-upgradable dead end, lets
   * build in a way for the owner to clear the block
   */
  function clearNextVersion() onlyOwner {
    nextVersion = address(0);
  }

  /*
   * Concrete implementations should give thier users methods for moving to the
   * next version or previous versions
   */
}
