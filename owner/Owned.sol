pragma solidity ^0.4.1;
import "./OwnerValidator.sol";

contract Owned {
    function ownerValidate(address addr) constant returns (bool);
    bool public isWorking;

    function Owned() {
        isWorking = true;
    }

    modifier onlyOwner {
        if (!ownerValidate(msg.sender)) throw;
        _;
    }

    modifier onlyWorking {
        if (!isWorking) throw;
        _;
    }

    modifier onlyNotWorking {
        if (isWorking) throw;
        _;
    }

    function setWorking(bool _isWorking) onlyOwner {
        isWorking = _isWorking;
    }
}