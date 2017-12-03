pragma solidity ^0.4.4;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/token/StandardToken.sol";


contract Product is StandardToken, Ownable {

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
   * Log the payments the contract receives so the DApp can do what it needs to
   * with that information.
   */
  event Payment(uint256 amount, address from);

  /*
   * Keep track of the production release and provide evidence to users that
   * they are using software whose authors have been compensated
   */
  bytes32 public proofOfProductionRelease;

  /*
   * Clients may want to know what version of the contract the product they are
   * working on is using.
   * TODO: how can we migrate a product to a newer version of the contract?
   */
  string public version = "0.0.1-alpha";

  function claimIteration(address _author, bytes32 _proof) public {
    AuthorshipClaim(_author, _proof);
    /*
     * TODO Iterate on this
     * Claims as logs allow an author to register evidence, but allows authors
     * to forget to register the evidence before making a proposal.
     *
     * Storing a registry of claims would allow the propose function to fail
     * unless the proposed iteration were correctly claimed but would increase
     * the gas cost of proposing iterations.
     */
  }

  function proposeIteration(address _author, bytes32 _proof, string _location) public {
    IterationProposal(_author, _proof, _location);
    // TODO see comments in claimIteration
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
    return this.balance / totalSupply;
  }

  /*
   * Product tokens can be redemed for their share of the revenue (Ether for
   * now) held by the Product contract.
   */
  function redeem(uint256 _amount) public {
    uint256 value = shareValue();
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    msg.sender.transfer(value * _amount);
  }

  function () public payable {
    Payment(msg.value, msg.sender);
  }
}
