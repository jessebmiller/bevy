pragma solidity ^0.4.4;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";

/*
 * An upgradable contract is one with a next version and a previous version,
 * unless it is the first or most recent version, that it's users have the
 * to migrate to.
 */
contract Upgradable is Ownable {

  event NewVersion(address);

  address public previousVersion;
  address public nextVersion;

  // grace period is the number of blocks that redeeming is disabled on the new
  // contract to allow everyone who wants to upgrade the chance to before folks
  // start redeeming the earnings of the new contract
  uint32 public gracePeriod;
  uint256 public upgradeBlock;

  /*
   * Once the new version of the contract is deployed, the owner can execute the
   * upgrade.
   */
  function executeUpgrade(address _previousVersion, uint32 _gracePeriod) onlyOwner {
    if (_previousVersion != address(0)) {
      Upgradable pv = Upgradable(_previousVersion);
      pv.setNextVersion();
    }
    upgradeBlock = block.number;
    gracePeriod = _gracePeriod;
  }

  function setNextVersion() public {
    // must be set by a contract owned by this contract's owner.
    // future contract's executeUpgrade function will call this
    Upgradable nextContract = Upgradable(msg.sender);
    require(nextContract.owner() == owner);
    nextVersion = msg.sender;
    NewVersion(msg.sender);
  }

  // upgrade moves the sender's state to the next version
  function upgrade() public;

  // downgrade moves the sender's state to the previous version
  function downgrade() public;
}
