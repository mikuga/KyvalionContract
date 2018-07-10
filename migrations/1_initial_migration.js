var OwnerValidatorImpl = artifacts.require("./OwnerValidatorImpl.sol");
var OffChainManagerImpl = artifacts.require("./OffChainManagerImpl.sol");
var TokenContractImpl = artifacts.require("./TokenContractImpl.sol");
var MainContract = artifacts.require("./MainContract");


var options = {
  initialSupply: 500000000000000000,
  decimalUnit: 8,
  symbol: "KTC",
  rootAddress: "0x95bf476114e3241b808e81144228fe833fd38887"
};

module.exports = function(deployer) {
  console.log("!!!");
  deployer.deploy(OwnerValidatorImpl).then(function(){
    return deployer.deploy(OffChainManagerImpl,options.rootAddress,OwnerValidatorImpl.address)
  }).then(function(){
    return deployer.deploy(TokenContractImpl,options.initialSupply,options.decimalUnit,OwnerValidatorImpl.address,OffChainManagerImpl.address)
  }).then(function(){
    return deployer.deploy(MainContract,options.symbol,OwnerValidatorImpl.address, TokenContractImpl.addrses,options.symbol)
  })
};
