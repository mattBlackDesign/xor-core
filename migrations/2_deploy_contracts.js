var Market = artifacts.require("./Market.sol");

var ExampleMarketTrust = artifacts.require("xor-external-contract-examples/contracts/ExampleMarketTrust.sol");
var ExampleMarketInterest = artifacts.require("xor-external-contract-examples/contracts/ExampleMarketInterest.sol");
var ExampleMarketAvatar = artifacts.require("./ExampleMarketAvatar.sol");
var ExampleMarketGovernance = artifacts.require("./ExampleMarketGovernance.sol");
var LoanFactory = artificats.require("./LoanFactory.sol");
var DOTFactory = artifacts.require("./DOTFactory.sol");
var StringUtils = artifacts.require("./StringUtils.sol");

module.exports = function(deployer) {
  deployer.then(async () => {
    await deployer.deploy(StringUtils);
    await deployer.deploy(Market);
    var stringUtils = await StringUtils.deployed();
    var market = await Market.deployed();
    await deployer.link(StringUtils, DOTFactory);
    await deployer.deploy(LoanFactory);
    await deployer.deploy(DOTFactory);
    var loanFactory = await LoanFactory.deployed();
    var dotFactory = await DOTFactory.deployed();

    market.setLoanFactoryContractAddress(loanFactory.address);
    market.setMarketTokenContractAddress(dotFactory.address);
    dotFactory.setMarketTokenContractAddress(market.address);

    await deployer.deploy(ExampleMarketGovernance);
    var exampleMarketGovernance = await ExampleMarketGovernance.deployed();

    await deployer.deploy(ExampleMarketAvatar);
    var exampleMarketAvatar = await ExampleMarketAvatar.deployed();

    exampleMarketGovernance.setMarketAvatarContractAddress(exampleMarketAvatar.address);
    exampleMarketGovernance.setMarketGovernanceContractAddress(market.address);

    await deployer.deploy(ExampleMarketTrust);
    await deployer.deploy(ExampleMarketInterest);

    var exampleMarketTrust = await ExampleMarketTrust.deployed();
    var exmapleMarketInterest = await ExampleMarketInterest.deployed();

    var arrContractAddresses = [
      exampleMarketGovernance.address,
      exampleMarketTrust.address,
      exmapleMarketInterest.address
    ]

    market.createMarket([5, 5, 5], arrContractAddresses);
  });
};
