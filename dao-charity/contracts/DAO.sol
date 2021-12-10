// SPDX-License-Identifier: MIT

// Learn from https://learn.figment.io/tutorials/build-a-dao-on-celo

/**

Requirements:
  - Users connect their Celo Wallet to join the Charity DAO.
  - Users send Celo tokens to the DAO to become Contributors.
  - Contributors that have made 200 or more total contributions are automatically made Stakeholders.
  - Only a Stakeholder of the DAO can vote on proposals.
  - Contributors and/or Stakeholders can create a new proposal.
  - A newly created proposal has an ending date, when voting will conclude.
  - Stakeholders can upvote or downvote a proposal.
  - Once a Proposal's expiry date passes, a Stakeholder then pays out the requested amount to the specified Charity.

*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DAO is ReentrancyGuard, AccessControl  {
  bytes32 public constant CONTRIBUTOR_ROLE = keccak256("CONTRIBUTOR");
  bytes32 public constant STAKEHOLDER_ROLE = keccak256("STAKEHOLDER");
  uint32 public constant minimunVotingPeriod = 1 weeks;
  uint256 public numOfProposals;

  struct CharityProposal {
    uint256 id;
    uint256 amount;
    uint256 livePeriod;
    uint256 votesFor;
    uint256 votesAgainst;
    string description;
    bool votingPassed;
    bool paid;
    address payable charityAddress;
    address proposer;
    address paidBy;
  }

  mapping(uint256 => CharityProposal) private charityProposals;
  // record the proposals that stakeholder has voted on it
  mapping(address => uint256[]) private stakeHolderVotes;
  // amounts they(contributors) have sent into the DAO treasury.
  mapping(address => uint256) private constributors;
  // balances of stakeholders
  mapping(address => uint256) private stakeholders;

  event ContributionReceived(address indexed fromAddress, uint256 amount);
  event NewProposal(address indexed proposer, uint256 amount);
  event PaymentTransfered(
    address indexed stakeholderAddress,
    address indexed charityAddress,
    uint256 amount
  );

  modifier onlyStakeholder(string memory _msg) {
    require(hasRole(STAKEHOLDER_ROLE, msg.sender), _msg);
    _;
  }

  modifier onlyContributor(string memory _msg) {
    require(hasRole(CONTRIBUTOR_ROLE, msg.sender), _msg);
    _;
  }

  function createProposal(
    uint256 _amount,
    address _charityAdddres,
    string calldata _description
  ) 
    external
    onlyStakeholder("Only stakeholders are allowed to create proposals")
  {
    uint256 proposalId = numOfProposals++;
    CharityProposal storage newProposal = charityProposals[proposalId];
    newProposal.id = proposalId;
    newProposal.amount = _amount;
    newProposal.livePeriod = block.timestamp + minimunVotingPeriod;
    newProposal.description = _description;
    newProposal.charityAddress = payable(_charityAdddres);
    newProposal.proposer = msg.sender;
    emit NewProposal(msg.sender, _amount);
  }

  function vote(uint256 _id, bool _isAgree) 
    external
    onlyStakeholder("Only stakeholders are allowed to vote")
  {
    CharityProposal storage proposal = charityProposals[_id];
    _votable(proposal);
    if(_isAgree) {
      proposal.votesFor++;
    } else {
      proposal.votesAgainst++;
    }
    stakeHolderVotes[msg.sender].push(_id);
  }

  function _votable(CharityProposal storage _proposal) private {
    if(
      _proposal.votingPassed ||
      block.timestamp > _proposal.livePeriod
    ) {
      _proposal.votingPassed = true;
      revert("Voting period passed");
    }
    uint256[] memory stakerVotes = stakeHolderVotes[msg.sender];
    for(uint256 i= 0; i < stakerVotes.length; i++) {
      if(stakerVotes[i] == _proposal.id) {  
        revert("This stakeholder already voted on this proposal");
      }
    }
  }

  function payCharity(uint256 _proposalId)
    external
    nonReentrant
    onlyStakeholder("Only stakeholders can make payment")
  {
    CharityProposal storage proposal = charityProposals[_proposalId];
    require(
      proposal.votingPassed,
      "Proposal still in the voting period"
    );
    require(proposal.paid == false, "The proposal has been paid");
    if(proposal.votesAgainst >= proposal.votesFor) {
      // more voter voted on against
      revert("The proposal does not have the required amount of votes to pass");
    } else {
      if(address(this).balance < proposal.amount) {
        revert("The contract has no enough fund");
      } else {
        // pay it
        proposal.paid = true;
        proposal.paidBy = msg.sender;
      }
    }
    emit PaymentTransfered(msg.sender, proposal.charityAddress, proposal.amount);
    return proposal.charityAddress.transfer(proposal.amount);
  }

  function makeStakeholder(uint256 _amount) public {
    // not a stakeholder
    if(!hasRole(STAKEHOLDER_ROLE, msg.sender)) {
      uint256 totalAmount = constributors[msg.sender] + _amount;
      if(totalAmount >= 1 ether) {
        // become stakeholder
        _setupRole(STAKEHOLDER_ROLE, msg.sender);
        _setupRole(CONTRIBUTOR_ROLE, msg.sender);
        stakeholders[msg.sender] += totalAmount;
      } else {
        // become contributor
        _setupRole(CONTRIBUTOR_ROLE, msg.sender);
      }
      constributors[msg.sender] += _amount;
    } else {
      constributors[msg.sender] += _amount;
      stakeholders[msg.sender] += _amount;
    }
    
  }

  function getProposals() 
    external
    view
    returns (CharityProposal[] memory proposals) 
  {
    proposals = new CharityProposal[](numOfProposals);
    for(uint256 i = 0; i < numOfProposals; i++) {
      proposals[i] = charityProposals[i];
    }
  }

  function getProposal(uint256 _id)
    public
    view
    returns (CharityProposal memory) 
  {
    return charityProposals[_id];
  }

  function getStakeholderVotes(address _address) 
    public
    view
    onlyStakeholder("Only stakeholders can check their votes")
    returns (uint256[] memory) 
  {
    return stakeHolderVotes[_address];
  }

  function getStakeholderBalance(address _address)
    public
    view
    onlyStakeholder("Only stakeholders can check their balances")
    returns (uint256)
  {
    return stakeholders[_address];
  }

  function getContributorBalance(address _address)
    public
    view
    onlyContributor("Only contributors can check their balances")
    returns (uint256)
  {
    return constributors[_address];
  }

  function isStakeholder() public view returns (bool) {
    return stakeholders[msg.sender] > 0;
  }

  function isContributor() public view returns (bool) {
    return constributors[msg.sender] > 0;
  }

  receive() external payable {
    makeStakeholder(msg.value);
    emit ContributionReceived(msg.sender, msg.value);
  }
}