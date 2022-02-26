// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title Voting with delegration.
contract Ballot {
    // This declares a new complex struct which will be used for variables later.
    // It will represent a single voter.
    struct Voter {
      uint weight; // weight is accumulated by delegation
      bool voted; // if true, that person already voted
      address delegate; // person delegated to
      uint vote; // index of the voted proposal
    }

    // This is a struct for a signle proposal
    struct Proposal {
      bytes32 name;     // short name (upto 32 bytes)
      uint voteCount;   // number of accumulated votes
    }

    address public chairperson;


    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposals;

    /// Create a new ballot to choose one of `proposalNames`.
    constructor(bytes32[] memory proposalNames) {
      chairperson = msg.sender;
      voters[chairperson].weight = 1;

      // For each of the provided proposal names,
      // create a new proposal object and add it to the end of the array
      // Q: Is this loop necessary?
      for (uint i =0; i < proposalNames.length; i++) {
        // `Proposal({...})` creates a temporary Proposal object
        // and `proposals.push(...)` appends it to the end of `proposals`.
        // https://docs.soliditylang.org/en/v0.6.0/types.html#array-members
        // This push returns nothing, which is different from other languages like JS
        // Contrast: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/push
        proposals.push(Proposal({
          name: proposalNames[i],
          voteCount: 0
        }));
      }
    }

    // Give `voter` the right to vote on this ballot.
    // May only be called by `chairperson`.
    function giveRightToVote(address voter) external {
      // If the first argument of `require` evaluates to `false`,
      // execution terminates and all changes to the state and to
      // Ether balances are reverted.

      // This used to consume all gas in old EVM versions, but not anymore.
      // It is often a good idea to use `require` to check functiojns are called correctly.
      // As a second arg, you can also provide an explanation about what went wrong.
      require(
        msg.sender == chairperson,
        "Only chairperson can give the right to vote."
      );
      require(
        !voters[voter].voted,
        "The voter already voted."
      );
      require(
        voters[voter].weight == 0,
        "The voter does not have any weight to vote."
      );
      voters[voter].weight = 1;
    }

    /// Delegate your vote to the voter `to`.
    function delegate(address to) external {
      // assigns reference
      Voter storage sender = voters[msg.sender];

      // Requirements
      require(!sender.voted, "You already voted.");
      require(to != msg.sender, "Self-delegration is disallowed.");

      // Forward the delegratiojn as long as `to` is also delegated.
      // In general, such loops are very dangerous.
      // If they run too long, they might need more gas than is available in a block.
      // In this case, the delegration will not be executed, but in other situations,
      // such loops might cause a contracft to get "stuck" completely.
      while (voters[to].delegate != address(0)) {
        to = voters[to].delegate;

        require(to != msg.sender, "Found loop in delegation.");
      }

      // PAUSE: Voter storage delegate_ = voters[to];
    }
}