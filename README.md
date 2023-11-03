# Gatekeeper One Challenge

## Gate 1

Gate one was relatively straightforward.  It required the msg.sender to not equal tx.orgin. to pass this gate all I needed to do is interact with the gatekeeper contract through another contract. 

``` solidity 
modifier gateOne() { 
	require(msg.sender != tx.origin); 
	_; 
}
```

## Gate 2
Gate 2 is where things began to get tricky. The require statements condition is that gasleft() % 8191 needs to equal zero. Essentially the gasleft() needs to be divisible by 8191. 

``` solidity
modifier gateTwo() { 
	require(gasleft() % 8191 == 0); 
	_; 
}
```

The first thing I did to attempt to solve this is using forge test. I made a test file that tested my EnterGate contract. I supplied the transaction with what I estimated to be enough gas and then added console logs in my instance of the gatekeeper one contract to log the gasleft() in the function modifer right before the gate two check. I adjusted the amount of gas I added to the transaction until my gasleft() logged at the right value. I later found out that using forges console2.logUint() uses gas which made the number inaccurate. (or at least I think that is what happened. Further testing would be required to determine if this was actually the case but my gasleft() values that were being logged in testing were not accurate.)

The next step was to use forge test --debug to try and debug the transaction. It was not working correctly however and would not show the source code which made parsing the assembly opcodes difficult and unclear. 

I was finally able to pass this gate by using a for loop to increase the gas by one until the condition was met. 

## Gate 3 

Gate3 involved passing in a bytes8 gatekey and passing checks where it compares the gatekey bytes typecasted at different uint values.

``` solidity
modifier gateThree(bytes8 _gateKey) { 
require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey));
require(uint32(uint64(_gateKey)) != uint64(_gateKey);
require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)); 
_;
}
```

For this gate I needed to learn about how typecasting worked casting bytes to different uint values. In a previous challenge I encountered I needed a `bytes16 key` that was equal to the value of a private variable `bytes32[3] private data`. The variable data was an array of 3 bytes32 values. The bytes16 key needed to be equal to `bytes16(data[2])`. data\[2] is the third index of the array so i just needed to grab the first 16 bytes of the value and pass that in as my bytes16 key. 

This is Important to note because bytes behave differently when you are casting bytes to bytes and bytes to uints. For example, when you are casting a bytes16 to a bytes 8 only the first 8 bytes are used. 0x1234567890abcdeffedcba0987654321 becomes 0x1234567890abcdef.

If you cast a bytes 8 to a bytes 16 value it pads zeros on the right side. 0x1234567890abcdef becomes 0x1234567890abcdef0000000000000000. 

When casting bytes to uint the opposite happens. For example a bytes8 value being cast to a uint 32 (4 bytes) would use the last 4 bytes instead of the first. 0x1234567890abcdef would become 0x90abcdef. 

If you cast a uint32 value to bytes4 and then to a bytes8, It will take the 4 bytes and pad zeroes on the right side.  0x90abcdef becomes 0x90abcdef00000000. 

If you have a uint32 value and you cast it to a uint64 zeroes will be padded on the left side.
0x90abcdef becomes 0x0000000090abcdef

It is important to note when using forge test logBytes() the zeros will be shown padded on the right side even if you are logging the bytes for uint values. This is incorrect. The zeroes should be padded on the left.

### Part 1

``` solidity
require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey));
```

This require statement is taking the `bytes8 _gatekey` and casting it to a uint64 and then into a uint32 and comparing it to the gatekey cast to a uint64 then a uint16 to check for equality.

lets say the bytes8 gatekey is 0x1234567890abcdef

Cast from a bytes8 to a uint64 it would remain the same since a uint64 is 8 bytes long.

Cast from a uint64 to a uint32 the last 4 bytes would be used so the value would be 0x90abcdef

Cast from a uint64 to a uint16 the last 2 bytes are used so the value would be 0xcdef

The uint16 and uint32 values are then compared for equality. When you compare a uint16 and a uint32 the uint16 value will be padded with zeros on the left side so it can be compared as a uint32.  

0x90abcdef is compared against 0x0000cdef.

This tells us that the bytes8 key needs to have zeroes in the fifth and sixth bytes for the comparison to be equal. 

Lets say out new gatekey is now 0x123456780000cdef

Now when we compare the uint32 and uint16 they will both be 0x0000cdef.

### Part 2

``` solidity
require(uint32(uint64(_gateKey)) != uint64(_gateKey);
```

This require statement is taking the `bytes8 _gatekey` and casting it into a uint64 and then uint32 and comparing it to the gatekey cast to a uint64 to check for inequality. 

We know from part 1 that the uint32 value is the last 4 bytes of gatekey which would be 0x0000cdef

The uint64 value of the gatekey is the entire key which would be  0x123456780000cdef.

When the uint32 and uint64 values are compared the uint32 is left padded with zeroes to be compared as a uint64

0x123456780000cdef is compared against 0x000000000000cdef

These values are not equal so our update gatekey passes this check.

### Part 3 

``` solidity
require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin));
```

This require statement is taking the `bytes8 _gatekey` and casting it into a uint64 and then uint32 and compares it to tx.orgin cast as a uint160 and then uint16 and checks for equality.

The uint32 value is the last 4 bytes of the gatekey which would be 0x0000cdef.

tx.orgin is going to be the wallet address that we use to interact with our contract. 

An address is 20 bytes so casting to a uint160 the value would remain the same.

cast into uint16 would the last 2 bytes of the address are used. 

The uint16 value of the address is left padded with zeros to be compared as a uint32 against the uint32 value of the gatekey. 

0x0000cdef is compared against 0x0000???? to check for equality.  We can see here that in order to pass our check the last 2 bytes of our key need to match the last 2 bytes of our address. 

This means that our updated gatekey  0x123456780000cdef needs to have the last 4 characters (or 2 bytes) match the last 4 characters of our wallet address and it should pass all of the checks and pass Gate 3.

Important note is that Forge when logging bytes pads the zeroes on the right side instead of the left side so if you are logging the bytes of uint values it will not be accurate.
