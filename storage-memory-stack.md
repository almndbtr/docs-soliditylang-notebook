# Storage, Memory, and the Stack

Ref: https://docs.soliditylang.org/en/v0.8.12/introduction-to-smart-contracts.html#storage-memory-and-the-stack

The Ethereum Virtual Machine (EVM) has three areas where it can store data:

- Storage
- Memory
- Stack

## Storage

- Each [account](https://docs.soliditylang.org/en/v0.8.12/introduction-to-smart-contracts.html#accounts) has a data area called "storage".
  - Remember that an account can either be an external account controlled by public-private key pairs (i.e. humans) or a contract account which is controlled by the code stored _together_ with the account.
  - Every account has a persistent key-value store mapping 256-bit words to 256-bit words called storage.
  - Every account has a balance in Ether (in "Wei" to be exact, `1 Ether` is `10**18 Wei`)
- "Storage" is:
  - persistent between function calls and transactions
  - key-value store that maps 256-bit words to 256-bit words
  - something you should minimize when storing in persistence to what the contract needs to run
- Tip: store data like derived calculations, caching, and aggregates outside of the contract
- Contract cannot read nor write to any store _apart_ from its own

## Memory

- Memory: a contract obtains a freshly cleared instance for each message call
  - It's linear
  - It can be addressed at the byte level
  - ... but the reads are limited to a width of 256 bits
  - ... and writes can _either_ be 8 bits or 256 bits wide
  - expanded by a word (256-bit), when accessing (either reading of writing) a previously untouched memory word (i.e. any offset within a word)
  - Most costly the larger it grows, as it scaled quadratically

## Stack

- EVM is not a register machine
- EVM is a stack machine
  - All computations are performed on a data area called the stack
  - The stack is not a block
  - The stack has a maximum size of 1024 elements
  - The stack contains words of 256 bits
- Access to the stack is limited to the top eend
  - It's possible to copy 1 of the topmost 16 elements ot the top of the stack, or swap the topmost element with one of the 16 elements below it
  - All other ops take the topmost 2 (or one, or more, depending on the operation) elements from the stack and push the result onto the stack

## Bonus

- List of Opcodes: https://docs.soliditylang.org/en/v0.8.12/yul.html#opcodes
- Contracts can call other contracts or send Ether to non-contract accounts by the [means of message calls](https://docs.soliditylang.org/en/v0.8.12/introduction-to-smart-contracts.html#message-calls)
  - A contract can decide how much of its remaining gas should be sent with the inner message call and how much it wants to retain
  - If an out-of-gas exception happens in the inner call (or any other exception), this will be signaled by an error value put onto the stack -- so in this case, only the gas sent together with the call is used up
    - In Solidity, the calling contract causes a manual exception by default in such situations, so that exceptions "bubble up" the call stack"
    - Prior Art / something to study in this area: https://github.com/ourzora/v3
- Contracts can even [create other contracts using a special opscode](https://docs.soliditylang.org/en/v0.8.12/introduction-to-smart-contracts.html#create)
  - These calls and normal message calls differ in that the payload data is executed and the result stored as code and the caller/creator receives the address of the new contract ont he stack
- `selfdestruct` is not the same as a deleting data from a hard disk, as it is still a part of the history of the blockchain and _probably_ retained by most Ehtereum nodes
  - This is the only way to remove code from the blockchain when a contract at that address performs this operation
  - Remaining Ether stored at that address is sent to a designated target, but could be forever lost if you're not careful