// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Coin {
  // The keyword "public" makes variables
  // accessible from other contracts

  // Declares a state variable of type `address`
  // `address` type is a 160-bit value that does not allow any arithemtic operations
  // It is suitable for storing addresses of contracts,
  // or a hash of the public half of a keypair belonging to external accounts
  // Read more: https://docs.soliditylang.org/en/v0.8.12/types.html#address
  // `public` auto-gens a fn that allows you to access the current value
  // of the state variable from outside of the contract
  // logicailly equivalent to:
  // function minter() external view returns (address) { return minter; }
  address public minter;

  // Think of this as a hash table
  // Not possible to obtain a list of all keys of a mapping, nor a list of all values
  // record what you added to the mapping or use it in a context where this isn't needed
  mapping (address => uint) public balances;

  // Events allow clients to react to specific
  // contract changes you declare
  // Etherem clients such as web apps can listen for these events emitted
  // on the blockchain without much cost; once emitted, listener receives from, to, and amount
  // See web3.js for more details
  event Sent(address from, address to, uint amount);

  // Constructor code is only run when the contract is created
  // It cannot be called afterwards
  constructor() {
    minter = msg.sender;
  }

  // Sends an amount of newly created coins to an address
  // Can only be called by the contract creator
  function mint(address receiver, uint amount) public {
    // This ensures that _only_ the creator of the contract can call `mint`
    // The creator can mint as many tokens as they like, but this will lead to a phenomenon called "overflow"
    // Because of Checked arithmetic, the transaction would revert if the expression `balances[receiver] += amount;` overflows,
    // such that `balances[receiver] + amount` in arbitrary precision arithmetic is larger than the maximum value of
    // `uint`, which is `2**256 - 1`.
    // Learn more: https://docs.soliditylang.org/en/v0.8.12/control-structures.html#unchecked

    // You can use `unchecked` to have the max "wrap" over to the under- or over- flow`
    // This is also a sort of "gas optimization" that might be of interest
    // Prior Art: https://github.com/ourzora/v3/pull/126#discussion_r794997046
    require(msg.sender == minter);
    balances[receiver] += amount;
  }

  // Errors allow you to provide information about
  // Why an operation failed. They are returned
  // to the caller of the function.
  error InsufficientBalance(uint requested, uint available);

  // Sends an amount of existing coins
  // from any caller to an address
  function send(address receiver, uint amount) public {
    if (amount > balances[msg.sender]) {
      revert InsufficientBalance({
        requested: amount,
        available: balances[msg.sender]
      });
    }

    balances[msg.sender] -= amount;
    balances[receiver] += amount;
    emit Sent(msg.sender, receiver, amount);
  }
}