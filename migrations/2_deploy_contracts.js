var Market = artifacts.require("./MarketBase.sol");

var ExampleLoanTrust = artifacts.require("xor-external-contract-examples/contracts/ExampleLoanTrust.sol");
var ExampleLoanInterest = artifacts.require("xor-external-contract-examples/contracts/ExampleLoanInterest.sol");
// var ExampleLoanAvatar = artifacts.require("./ExampleLoanAvatar.sol");
// var ExampleLoanGovernance = artifacts.require("./ExampleLoanGovernance.sol");
var LoanFactory = artifacts.require("./LoanFactory.sol");
var DOTFactory = artifacts.require("./DOTFactory.sol");
var StringUtils = artifacts.require("./StringUtils.sol");

var Token = artifacts.require("./Token.sol");

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
    market.setDOTFactoryContractAddress(dotFactory.address);

    // await deployer.deploy(ExampleLoanGovernance);
    // var exampleLoanGovernance = await ExampleLoanGovernance.deployed();

    // await deployer.deploy(ExampleLoanAvatar);
    // var exampleLoanAvatar = await ExampleLoanAvatar.deployed();

    // exampleLoanGovernance.setLoanAvatarContractAddress(exampleLoanAvatar.address);
    // exampleLoanGovernance.setLoanGovernanceContractAddress(market.address);

    await deployer.deploy(ExampleLoanTrust);
    await deployer.deploy(ExampleLoanInterest);

    var exampleLoanTrust = await ExampleLoanTrust.deployed();
    var exampleLoanInterest = await ExampleLoanInterest.deployed();

    var arrContractAddresses = [
      // exampleLoanGovernance.address,
      exampleLoanTrust.address,
      exampleLoanInterest.address
    ]

    // market.createMarket([5, 5, 5], arrContractAddresses);

    await deployer.deploy(Token, "Token", "TOK", 100000);
  });
};
