var Market = artifacts.require("./Market.sol");

var ExampleMarketTrust = artifacts.require("xor-external-contract-examples/contracts/ExampleMarketTrust.sol");
var ExampleMarketInterest = artifacts.require("xor-external-contract-examples/contracts/ExampleMarketInterest.sol");
var ExampleLoanAvatar = artifacts.require("./ExampleLoanAvatar.sol");
var ExampleLoanGovernance = artifacts.require("./ExampleLoanGovernance.sol");
var LoanFactory = artifacts.require("./LoanFactory.sol");
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

    await deployer.deploy(ExampleLoanGovernance);
    var exampleLoanGovernance = await ExampleLoanGovernance.deployed();

    await deployer.deploy(ExampleLoanAvatar);
    var exampleLoanAvatar = await ExampleLoanAvatar.deployed();

    exampleLoanGovernance.setLoanAvatarContractAddress(exampleLoanAvatar.address);
    exampleLoanGovernance.setLoanGovernanceContractAddress(market.address);

    await deployer.deploy(ExampleMarketTrust);
    await deployer.deploy(ExampleMarketInterest);

    var exampleMarketTrust = await ExampleMarketTrust.deployed();
    var exmapleMarketInterest = await ExampleMarketInterest.deployed();

    var arrContractAddresses = [
      exampleLoanGovernance.address,
      exampleMarketTrust.address,
      exmapleMarketInterest.address
    ]

    // market.createMarket([5, 5, 5], arrContractAddresses);
  });
};
