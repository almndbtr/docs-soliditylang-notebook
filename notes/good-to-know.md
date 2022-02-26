# Good to know

## Types

- Concept of `undefined` or `null` doesn't exist
- Newly declared variables always have a default value dependent on its type -- think of this as the "zero-value" or "zero-state" allocated for said variable, like in Go
  - https://docs.soliditylang.org/en/v0.8.12/control-structures.html#default-value
- To handle any unexpected values, use the [revert function](https://docs.soliditylang.org/en/v0.8.12/control-structures.html#assert-and-require) to revert the whole transaction, or return a tuple with a second `bool` value denoting success (like Go, where you call a function and assign the respective return values to variables, reserving the first for error checking)
  - `require`, `revert`, and `exceptions` each have their own semantics. Come back to this and their differences later

### Laundry List
- Booleans
  - The operations `||` and `&&` apply the common short-circuiting rules
    - However, if you run something like say `f(x) || g(y)`, if `f(x)` ervaluates to `true`, `g(y)` will not be evaluated even if it may have side effects. The implication is this: if you want to ensure that _both_ are run, then rewrite it so that's explicit before running the short-circuiting check. For example, you can create a variable to store whatever the `f(x)` expression returns, and another for `g(y)`, and then run the check so you're looking strictly at boolean values rather than the _eventual_ return value that's given.
- Integers
  - Warning: Integers in Solidity are restricted to a certain range.
    - `uint32` has a range of `0` up to `2**32 - 1`
    - There are two modes in which arithmetic is performed on these types: the wrapping (also known as unchecked mode) and the checked mode
      - In v0.8.12, arithmetic is always checked by default -- this means that if the result of an operation fails outside the value range of the type, the call is reverted through a [failing assertion](https://docs.soliditylang.org/en/v0.8.12/control-structures.html#assert-and-require)
    - Know this cold: [checked or unchecked arithmetic](https://docs.soliditylang.org/en/v0.8.12/control-structures.html#unchecked)
      - Prior Art: https://github.com/ourzora/v3/pull/126#pullrequestreview-866843334
- Comparisons
- Bit Operatioons
- Shifts
- Arithmetic operations
  - Know this cold: https://docs.soliditylang.org/en/v0.8.12/control-structures.html#unchecked
- Modulo
- Exponentiation
- Fixed point numbers (not fully supported)
- Address, only two flavours
  - `address`: holds a 20 byte value (size of an Ethereum address)
    - This might be a smart contract that **was not built** to accept Ether
  - `address payable`: same as address, but with the additional members `transfer` and `send`
    - This is an address **you can send Ether to**
  - Consult type conversions (implicit / explicit) as necessary [via the docs](https://docs.soliditylang.org/en/v0.8.12/types.html#address)
    -In short, if you _ever_ plan to make some address a place where you want to send Ether, declare it as `address payable` to save yourself from a world of pain in the future ✨
  - Warning: if you convert a type that uses a larger byte size to an `address`, for example `bytes32`, then the `address` is truncated. You can use `address(uint160(bytes20(b)))` or `address(uint160(uint256(b)))` to reduce conversion ambiguity
- Always double check the version of the contract before you proceed in auditing it
- [Members of address types](https://docs.soliditylang.org/en/v0.8.12/units-and-global-variables.html#address-related)
  - These are publicly accessible/queryable
  - `transfer` sends Ether to a payable address
  - `send` is the low-level counterpart of `trasnfer`; if it fails, current contract will not stop with an exception, but `send` will return `false`
    - Warning: always check the return value of `send`, since it can fail if the call stack depth is at 1024 and it also fails if the receipient runs out of gas
    - Use `transfer`
    - Even better: use a pattern where the receipient withdraws the money -- go find Prior Art for this
- PAUSE: call, delegatecall and staticcall
  - https://docs.soliditylang.org/en/v0.8.12/types.html#address

