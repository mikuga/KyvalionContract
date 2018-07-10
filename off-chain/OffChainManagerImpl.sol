pragma solidity ^0.4.1;
import "../owner/Owned.sol";
import "../token/TokenContract.sol";
import "./OffChainManager.sol";

contract OffChainManagerImpl is OffChainManager, Owned {
    address public rootAddress;
    address[] public offChainAddreses;
    // reference of offChainAddreses, value: index + 1, 0 is invalid
    mapping (address => uint256) refOffChainAddresses; 

    OwnerValidator public ownerValidator;
    // set after creating token
    TokenContract public tokenContract;

    function OffChainManagerImpl(
        address _rootAddress,
        address _ownerValidator
    ) {
        rootAddress = _rootAddress;
        ownerValidator = OwnerValidator(_ownerValidator);
    }

    function setRootAddress(address _address) onlyWorking {
        if (ownerValidator.validate(msg.sender)) {
            rootAddress = _address;
        }
    }

    function setOwnerValidatorAddress(address _ownerValidator) onlyWorking {
        if (ownerValidator.validate(msg.sender)) {
            ownerValidator = OwnerValidator(_ownerValidator);
        }
    }

    function setTokenContract(address _tokenContract) {
        if (ownerValidator.validate(msg.sender)) {
            tokenContract = TokenContract(_tokenContract);
        }
    }

    function offChainAddresesValidCount() constant returns (uint) {
        uint cnt = 0;
        for (uint i = 0; i < offChainAddreses.length; i++) {
            if (offChainAddreses[i] != 0) {
                cnt++;
            }
        }
        return cnt;
    }

    function addOffChainAddress(address _address) private {
        if (!isToOffChainAddress(_address)) {
            offChainAddreses.push(_address);
            refOffChainAddresses[_address] = offChainAddreses.length;
        }
    }

    function removeOffChainAddress(address _address) private {
        uint pos = refOffChainAddresses[_address];
        if (pos > 0) {
            offChainAddreses[pos - 1] = 0;
            refOffChainAddresses[_address] = 0x0;
        }
    }

    function addOffChainAddresses(address[] _addresses) onlyWorking {
        if (ownerValidator.validate(msg.sender)) {
            for (uint i = 0; i < _addresses.length; i++) {
                addOffChainAddress(_addresses[i]);
            }
        }
    }

    function removeOffChainAddresses(address[] _addresses) onlyWorking {
        if (ownerValidator.validate(msg.sender)) {
            for (uint i = 0; i < _addresses.length; i++) {
                removeOffChainAddress(_addresses[i]);
            }
        }
    }

    function ownerValidate(address addr) constant returns (bool) {
        return ownerValidator.validate(addr);
    }

    function transferFromSender(address _to, uint256 _value) returns (bool success) {
        if (!ownerValidator.validate(msg.sender)) throw;
        return tokenContract.transferFromSender(_to, _value);
    }

    function sendFromOwn(address _to, uint256 _value) returns (bool success) {
        if (!ownerValidator.validate(msg.sender)) throw; 
        if (!_to.send(_value)) throw;
        return true;
    }

    function isToOffChainAddress(address addr) constant returns (bool) {
        return refOffChainAddresses[addr] > 0;
    }

    function getOffChainRootAddress() constant returns (address) {
        return rootAddress;
    }

    function getOffChainAddresses() constant returns (address[]) {
        return offChainAddreses;
    } 

    function isToOffChainAddresses(address[] _addresses) constant returns (bool) {
        for (uint i = 0; i < _addresses.length; i++) {
            if (!isToOffChainAddress(_addresses[i])) {
                return false;
            }
        }
        return true;
    }
}
