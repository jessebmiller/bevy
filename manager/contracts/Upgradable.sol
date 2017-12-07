pragma solidity ^0.4.4;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";

/*
 * An upgradable contract is one with a next version and a previous version,
 * unless it is the first or most recent version, that it's users have the
 * to migrate to.
 */
contract Upgradable is Ownable {

  event NewVersion(address nextVersion);

  address public previousVersion;
  address public nextVersion;

  // grace period is the number of blocks that redeeming is disabled on the new
  // contract to allow everyone who wants to upgrade the chance to before folks
  // start redeeming the earnings of the new contract
  uint32 public gracePeriod;
  uint32 public upgradeBlock;

  function Upgradable(address _previousVersion, uint32 _gracePeriod) public {
    _previousVersion.setNextVersion();
    this.upgradeBlock = block.number;
    this.gracePerios = _gracePeriod;
  }

  function setNextVersion() public {
    // must be set by a contract owned by this contract's owner.
    require(msg.sender.getOwner() == this.owner);
    this.nextVersion = msg.sender;
    NewVersion(_nextVersion);
  }

  // upgrade moves the sender's state to the next version
  function upgrade() {}

  // downgrade moves the sender's state to the previous version
  function downgrade() {}
