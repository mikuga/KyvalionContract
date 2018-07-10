pragma solidity ^0.4.1;
import "../token/TokenContract.sol";
import "./Owned.sol";

contract OwnerValidatorImpl is OwnerValidator, Owned {

    address[] public owners;

    // set after creating token
    TokenContract public tokenContract;

    function OwnerValidatorImpl() {
        owners.push(msg.sender);
    }

    // return 0: not found, index + 1
    function indexOfOwners(address _address) private constant returns (uint pos) {
        pos = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == _address) {
                pos = i + 1;
                break;
            }
        }
        return pos;                
    }

    function validate(address addr) constant returns (bool) {
        return (indexOfOwners(addr) != 0);
    }
        
    function getOwners() constant returns (address[]) {
        return owners;
    } 

    function addOwner(address addr) onlyWorking {
        if (validate(msg.sender)) {
            if (!validate(addr)) {
                owners.push(addr);
            }
        }
    }

    function removeOwner(address addr) onlyWorking {
        if (validate(msg.sender)) {
            uint pos = indexOfOwners(addr);
            if (pos > 0) {
                owners[pos - 1] = 0x0;
            }
        }
    }

    function setTokenContract(address _tokenContract) onlyWorking {
        if (validate(msg.sender)) {
            tokenContract = TokenContract(_tokenContract);
        }
    }

    function ownerValidate(address addr) constant returns (bool) {
        return validate(addr);
    }

    function transferFromSender(address _to, uint256 _value) returns (bool success) {
        if (!validate(msg.sender)) throw;
        return tokenContract.transferFromSender(_to, _value);
    }

    function sendFromOwn(address _to, uint256 _value) returns (bool success) {
        if (!validate(msg.sender)) throw;
        if (!_to.send(_value)) throw;
        return true;
    }
}
