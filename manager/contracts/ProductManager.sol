pragma solidity ^0.4.4;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./Upgradable.sol";


contract ProductManager is Upgradable {
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
   * A shareholder upgraded to the next version of the contract
   */
  event Upgrade(address shareholder);

  /*
   * A shareholder downgraded to the previous version of the contract
   */
  event Downgrade(address shareholder);

  /*
   * Log the payments the contract receives so the DApp can do what it needs to
   * with that information.
   */
  event Payment(uint256 amount, address from);

  /*
   * Just have the minimum parts of a standard coin needed to distribute shares
   * to contributors. Start simple, then iterate when we learn.
   */
  uint256 public totalSupply;
  mapping(address => uint256) balances;

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
   * Implement minimal coin features needed to start as simple as possible.
   */
  function balanceOf(address _who) public view returns (uint256) {
    return balances[_who];
  }

  /*
   * The value of each share (coin, token, TODO work on the language) is the
   * proportion of value held by the contract to total supply
   * TODO confirm that the share value rounds down.
   */
  function shareValue() constant public returns (uint256) {
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
    require(upgradeBlock + gracePeriod < block.number);
    uint256 value = shareValue();
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    msg.sender.transfer(value * _amount);
  }

  function moveContracts(address a) internal {
    // if the contract exists
    require(a != address(0));
    // if the caller is a shareholder
    require(balances[msg.sender] != 0);
    uint256 balance = balances[msg.sender];
    uint256 value = this.shareValue();
    // send their shares, and the ether backing them to the new contract
    balances[msg.sender] = 0;
    ProductManager preferedContract = ProductManager(a);
    preferedContract.receiveBalance(balance);
    preferedContract.transfer(value * balance);
  }

  function receiveBalance(uint256 balance) public {
    require(msg.sender == previousVersion);
    balances[tx.origin].add(balance);
  }

  function upgrade() public {
    // move to the next versiond
    moveContracts(nextVersion);
    // Log it for people watching
    Upgrade(msg.sender);
  }

  function downgrade() public {
    // move to the previous version
    moveContracts(previousVersion);
    // Log it for people watching
    Downgrade(msg.sender);
  }

  function () public payable {
    Payment(msg.value, msg.sender);
  }
}
