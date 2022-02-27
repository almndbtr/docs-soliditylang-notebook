# Types

## Value Types

- Concept of `undefined` or `null` doesn't exist
- Newly declared variables always have a default value dependent on its type -- think of this as the "zero-value" or "zero-state" allocated for said variable, like in Go
  - https://docs.soliditylang.org/en/v0.8.12/control-structures.html#default-value
- To handle any unexpected values, use the [revert function](https://docs.soliditylang.org/en/v0.8.12/control-structures.html#assert-and-require) to revert the whole transaction, or return a tuple with a second `bool` value denoting success (like Go, where you call a function and assign the respective return values to variables, reserving the first for error checking)
  - `require`, `revert`, and `exceptions` each have their own semantics. Come back to this and their differences later
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

### Reference Types

- Values of reference type can be modified through multiple different names
- Reference types must be handled more carefully than value types
- Reference types comprise structs, arrays and mappings
- If you use a reference type, you always have to explicitly provide the data area where the type is stored (data location)
  - `memory`: lifetime is limited to an external function call
  - `storage`: the location where the state variables are stored, where the lifetime is limited to the lifetime of a contract
  - `calldata`: special data location that contains the function arguments -- non-modifiable, non-persistent area where function arguments are stored, and behaves mostly like memory
- Data location
  - Notes
    - Use `calldata` as a data location because it will avoid copies and also makes sure that the data cannot be modified
    - Arrays and structs with `calldata` data location can be returned from functions, but not possible to allocate such types
    - `memory` and `calldata` are allowed in all functions regardless of their visibility
  - Assignments between storage and memory or from calldata always create an independent copy
  - Assignments from memory to memory only create references. The implicaftiono is that changes to one memory variable are also visible in all other memory variables that refer to the same data
  - Assignments from storage to local storage variable only assign a reference
  - All other assignments to storage always copy

### Arrays

- Can have compile-time fixed size or they can have a dynamic size
  - Fixed size: `T[k]`; `uint[][5]` is an array of 5 dynamic arrays of `uint`
  - Dynamic size: `T[]`
- Indices are zero-based
- Access is in opposite direction of the declaration
- Array elements can be of any type, including mapping or struct
- Mappings can only be stored in the `storage` data location and publicly-visiblew functions need parameters that are ABI types
- You can mark state variable arrays `public` and have solidity create a getter
- Accessing an array past its end causing a failing assertion; consider using `.push()` or `.push(value)`
- `bytes` and `string` as Arrays
  - These are special
  - `bytes` type is similar to `bytes1[]` but it's packed tighly in calldata and memory
  - `string` is equal to `bytes` but does not allow length or index access
  - Solidity doesn't have native string manipulation functions; use third-party string libraries

From the docs, because it's better to have this on hand as it's described:

> You should use bytes over bytes1[] because it is cheaper, since using bytes1[] in memory adds 31 padding bytes between the elements. Note that in storage, the padding is absent due to tight packing, see [bytes and string](https://docs.soliditylang.org/en/v0.8.12/internals/layout_in_storage.html#bytes-and-string). As a general rule, use bytes for arbitrary-length raw byte data and string for arbitrary-length string (UTF-8) data. If you can limit the length to a certain number of bytes, always use one of the value types bytes1 to bytes32 because they are much cheaper.

- Notes on arrays
  - Increasing the length of a storage array by calling `pushj()` has constant gas costs vecause storage is zero-initialized, while decreasing the length by calling `pop()` has a cost that depends on the "size" of the elemny being removed. If that element is an array, it can be very costly, because it includes explicitly clearing the removed elements similar to calling `delete` on them.
  - If you call functions that return dynamic arrays, make sure to use an EVM that is set to Byzantium mode.

### Mapping Types

- Think of them as hash tables; virtually initialized such that every possible key exist and is mapped to a value whose byte-representation is all zeros, a type's default avlue
- The key data is stored in its `keccak256` hash to loop up the value
  - Read on: https://solidity-by-example.org/hashing/
- Mappings do not have a length or a concept of a key or value being set, and therefore cannot be erased without extra information regarding the assigned keys
- Mappings can only have a data location of `storage`, so they're allowed for state variables, as storage reference types in functions, or as parameters for library functions
  - Mappings can't be used as parameters or return parameters of contract functionos that are publicly visible
- You can mark state variables of mapping type as `public` and Solidity creates a `getter` for you, where the `_KeyType` becomes a parameter for the getter; similarly, the `_ValueType` with a value type or a struct gives a getter for `_ValueType`
- You can't iterate over mappings
- I repeat: you cannot enumerate over a mapping's keys
- You could, though, implement a data structure on top of them and iterate over that. [Example](https://docs.soliditylang.org/en/v0.8.12/types.html#iterable-mappings)
  - Consider writing a test against the contract to see how much gas it would cost to process these, be it in a write or otherwise