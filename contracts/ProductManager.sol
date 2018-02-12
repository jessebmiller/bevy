pragma solidity ^0.4.4;

import "./zeppelin-solidity/contracts/math/SafeMath.sol";
import "./zeppelin-solidity/contracts/token/StandardToken.sol";
import "./zeppelin-solidity/contracts/token/BasicToken.sol";
import "./Upgradable.sol";


contract ProductManagerV1 is Upgradable, BasicToken {
  using SafeMath for uint256;

  /*
   * The author of an iteration may claim knowledge of their iteration for later
   * use in plagiarism claims or dispute edjudication by the community by
   * registering a claim with their address, a keccak hash of their iteration
   * and a keccak hash of the parent iteration.
   * TODO audit this claim chain for security and functionality
   */
  event AuthorshipClaim(address author, bytes32 proof);

  /*
   * Once an iteration has been claimed and the author in confident that it has
   * included in the blockchain, the author may propose their iteration by
   * revealing a URL containing the iteration that the community and owner can
   * verify against the proof.
   */
  event IterationProposal(address author, bytes32 proof, string location);

  /*
   * Keep track of the production release and provide evidence to users that
   * they are using software whose authors have been compensated
   */
  bytes32 public proofOfProductionRelease;

  /*
   * anyone may claim an iteration
   */
  function claimAuthorship(address _author, bytes32 _proof) public {
    AuthorshipClaim(_author, _proof);
  }

  /*
   * anyone may propose an iteration
   */
  function proposeIteration(address _author, bytes32 _proof, string _location) public {
    IterationProposal(_author, _proof, _location);
  }

  /*
   * The owner may accept proposals
   */
  function acceptProposal(address _author, bytes32 _proof, uint256 _amount) onlyOwner public {
    balances[_author] = balances[_author].add(_amount);
    totalSupply = totalSupply.add(_amount);
    proofOfProductionRelease = _proof;
  }

  /*
   * The value of each share (coin, token, TODO work on the language) is the
   * proportion of value held by the contract to total supply
   * TODO confirm that the share value rounds down.
   */
  function shareValue() constant public returns (uint256) {
    require(totalSupply > 0);
    return this.balance / totalSupply;
  }

  /*
   * Product tokens can be redemed for their share of the revenue (Ether for
   * now) held by the Product contract.
   */
  function redeem(uint256 _amount) public {
    // make sure share holders have had enough time to upgrade if they want to
    // if the new contract is making a lot of money, early upgraders shouldn't
    // have an advantage
    uint256 value = shareValue();
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    msg.sender.transfer(value * _amount);
  }

  /*
   * When a user upgrades to the next version it will call this to remove
   * the user from this contract
   */
  function removeUser(address user, address _nextVersion) public {
    // only the next version can call this (done in upgrade)
    require(msg.sender == nextVersion);
    uint256 balance = balanceOf(user);
    uint256 claim = shareValue() * balance;
    balances[user] = balances[user].sub(balance);
    totalSupply = totalSupply.sub(balance);
    _nextVersion.send(claim);
  }

  function () public payable { }
}

// dummy next version for testing
contract ProductManagerV2 is ProductManagerV1, StandardToken {

  function upgrade() public {
    require(previousVersion != address(0));
    ProductManagerV1 pv = ProductManagerV1(previousVersion);
    require(pv.nextVersion() == address(this));
    uint256 balance = pv.balanceOf(msg.sender);
    require(balance != 0);
    balances[msg.sender] = balances[msg.sender].add(balance);
    totalSupply = totalSupply.add(balance);
    pv.removeUser(msg.sender, address(this));
  }
}
