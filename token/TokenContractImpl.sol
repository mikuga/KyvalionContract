pragma solidity ^0.4.1;
import "../math/SafeMath.sol";
import "../owner/Owned.sol";
import "../off-chain/OffChainManager.sol";
import "./TokenContract.sol";

contract TokenContractImpl is TokenContract, Owned {
    using SafeMath for uint256;
    string public standard = "Token 0.1";
    uint256 _totalSupply;
    uint8 _decimals;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    OwnerValidator public ownerValidator;
    OffChainManager public offChainManager;

    bool public isRedenominated;
    uint256 public redenomiValue;
    mapping (address => uint256) public redenominatedBalances;
    mapping (address => mapping (address => uint256)) public redenominatedAllowed;

    function TokenContractImpl(
        uint256 initialSupply,
        uint8 decimals,
        address _ownerValidator,
        address _offChainManager
    ){
        balances[msg.sender] = initialSupply;
        _totalSupply = initialSupply;
        _decimals = decimals;
        ownerValidator = OwnerValidator(_ownerValidator);
        offChainManager = OffChainManager(_offChainManager);
    }

    function totalSupply() constant returns (uint256 totalSupply) {
        if (isRedenominated) {
            return redenominatedValue(_totalSupply);
        }
        return _totalSupply;
    }

    function decimals() constant returns (uint8 decimals) {
        return _decimals;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        if (isRedenominated) {
            if (redenominatedBalances[_owner] > 0) {
                return redenominatedBalances[_owner];
            }
            return redenominatedValue(balances[_owner]);
        }
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        if (isRedenominated) {
            if (redenominatedAllowed[_owner][_spender] > 0) {
                return redenominatedAllowed[_owner][_spender];
            }
            return redenominatedValue(allowed[_owner][_spender]);
        }
        return allowed[_owner][_spender];
    }

    function redenominatedValue(uint256 _value) private returns (uint256) {
        return _value.mul(redenomiValue);
    }

    function ownerValidate(address addr) constant returns (bool) {
        return ownerValidator.validate(addr);
    }

    // value set only
    function redenominate(uint256 _redenomiValue) {
        if (isRedenominated) throw;
        if (ownerValidator.validate(msg.sender)) {
            redenomiValue = _redenomiValue;
            Redenominate(msg.sender, isRedenominated, redenomiValue);
        }
    }   

    // apply, can't reset
    function applyRedenomination() onlyNotWorking {
        if (isRedenominated) throw;
        if (redenomiValue == 0) throw;
        if (ownerValidator.validate(msg.sender)) {
            isRedenominated = true;
            ApplyRedenomination(msg.sender, isRedenominated, redenomiValue);
        }
    }   

    function setOwnerValidatorAddress(address _ownerValidator) onlyWorking {
        if (ownerValidator.validate(msg.sender)) {
            ownerValidator = OwnerValidator(_ownerValidator);
        }
    }

    function setOffChainManagerAddress(address _offChainManager) onlyWorking {
        if (ownerValidator.validate(msg.sender)) {
            offChainManager = OffChainManager(_offChainManager);
        }
    }

    function transfer(address _to, uint256 _value) onlyWorking returns (bool success) {
        return transferProcess(tx.origin, _to, _value);
    }

    function transferProcess(address _from, address _to, uint256 _value) private returns (bool success) {
        if (balanceOf(_from) < _value) throw;
        subtractBalance(_from, _value);
        if (offChainManager.isToOffChainAddress(_to)) {
            addBalance(offChainManager.getOffChainRootAddress(), _value);
            ToOffChainTransfer(_from, _to, _to, _value);
        } else {
            addBalance(_to, _value);
        }
        return true;        
    }

    function addBalance(address _address, uint256 _value) private {
        if (isRedenominated) {
            if (redenominatedBalances[_address] == 0) {
                if (balances[_address] > 0) {
                    redenominatedBalances[_address] = redenominatedValue(balances[_address]);
                    balances[_address] = 0;
                }
            }
            redenominatedBalances[_address] = redenominatedBalances[_address].add(_value);
        } else {
            balances[_address] = balances[_address].add(_value);
        }
    }

    function subtractBalance(address _address, uint256 _value) private {
        if (isRedenominated) {
            if (redenominatedBalances[_address] == 0) {
                if (balances[_address] > 0) {
                    redenominatedBalances[_address] = redenominatedValue(balances[_address]);
                    balances[_address] = 0;
                }
            }
            redenominatedBalances[_address] = redenominatedBalances[_address].sub(_value);
        } else {
            balances[_address] = balances[_address].sub(_value);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyWorking returns (bool success) {
        if (balanceOf(_from) < _value) throw;
        if (balanceOf(_to).add(_value) < balanceOf(_to)) throw;
        if (_value > allowance(_from, tx.origin)) throw;
        subtractBalance(_from, _value);
        if (offChainManager.isToOffChainAddress(_to)) {
            addBalance(offChainManager.getOffChainRootAddress(), _value);
            ToOffChainTransfer(tx.origin, _to, _to, _value);
        } else {
            addBalance(_to, _value);
        }
        subtractAllowed(_from, tx.origin, _value);
        return true;
    }

    // from contract address
    function transferFromSender(address _to, uint256 _value) onlyWorking returns (bool success) {
        if (!transferProcess(msg.sender, _to, _value)) throw;
        TransferFromSender(msg.sender, _to, _value);
        return true;
    }

    // from this contract
    function transferFromOwn(address _to, uint256 _value) onlyWorking returns (bool success) {
        if (!ownerValidator.validate(msg.sender)) throw;
        if (!transferProcess(this, _to, _value)) throw;
        TransferFromSender(this, _to, _value);    
        return true;
    }

    function sendFromOwn(address _to, uint256 _value) returns (bool success) {
        if (!ownerValidator.validate(msg.sender)) throw; 
        if (!_to.send(_value)) throw;
        return true;
    }

    function approve(address _spender, uint256 _value) onlyWorking returns (bool success) {
        setAllowed(tx.origin, _spender, _value);
        return true;
    }

    function subtractAllowed(address _from, address _spender, uint256 _value) private {
        if (isRedenominated) {
            if (redenominatedAllowed[_from][_spender] == 0) {
                if (allowed[_from][_spender] > 0) {
                    redenominatedAllowed[_from][_spender] = redenominatedValue(allowed[_from][_spender]);
                    allowed[_from][_spender] = 0;
                }
            }
            redenominatedAllowed[_from][_spender] = redenominatedAllowed[_from][_spender].sub(_value);
        } else {
            allowed[_from][_spender] = allowed[_from][_spender].sub(_value);
        }
    }

    function setAllowed(address _owner, address _spender, uint256 _value) private {
        if (isRedenominated) {
            redenominatedAllowed[_owner][_spender] = _value;
        } else {
            allowed[_owner][_spender] = _value;
        }
    }

    event TransferFromSender(address indexed _from, address indexed _to, uint256 _value);
    event ToOffChainTransfer(address indexed _from, address indexed _toKey, address _to, uint256 _value);
    event Redenominate(address _owner, bool _isRedenominated, uint256 _redenomiVakye);
    event ApplyRedenomination(address _owner, bool _isRedenominated, uint256 _redenomiVakye);
}