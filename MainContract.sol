pragma solidity ^0.4.1;
import "./owner/OwnerValidator.sol";
import "./token/TokenContract.sol";

contract MainContract {
    string public standard = "Token 0.1";
    string public name;
    string public symbol;

    OwnerValidator public ownerValidator;
    TokenContract public tokenContract;

    function MainContract(
        string _tokenName,
        address _ownerValidator,
        address _tokenContract,
        string _symbol
    ) {
        ownerValidator = OwnerValidator(_ownerValidator);
        tokenContract = TokenContract(_tokenContract);
        name = _tokenName;
        symbol = _symbol;
    }

    function totalSupply() constant returns(uint256 totalSupply) {
        return tokenContract.totalSupply();
    }

    function decimals() constant returns(uint8 decimals) {
        return tokenContract.decimals();
    }

    function setOwnerValidateAddress(address _ownerValidator) {
        if (ownerValidator.validate(msg.sender)) {
            ownerValidator = OwnerValidator(_ownerValidator);
        }
    }

    function setTokenContract(address _tokenContract) {
        if (ownerValidator.validate(msg.sender)) {
            tokenContract = TokenContract(_tokenContract);
        }
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

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return uint256(tokenContract.balanceOf(_owner));
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (tokenContract.transfer(_to, _value)) {
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            throw;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (tokenContract.transferFrom(_from, _to, _value)) {
            Transfer(_from, _to, _value);
            return true;
        } else {
            throw;
        }
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if (tokenContract.approve(_spender,_value)) {
            Approval(msg.sender,_spender,_value);
            return true;
        } else {
            throw;
        }
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return tokenContract.allowance(_owner,_spender);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}