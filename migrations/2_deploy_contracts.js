var Market = artifacts.require("./MarketBase.sol");

var ExampleLoanTrust = artifacts.require("xor-external-contract-examples/contracts/ExampleLoanTrust.sol");
var ExampleLoanInterest = artifacts.require("xor-external-contract-examples/contracts/ExampleLoanInterest.sol");
var LoanFactory = artifacts.require("./LoanFactory.sol");
var DOTFactory = artifacts.require("./DOTFactory.sol");
var StringUtils = artifacts.require("./StringUtils.sol");

var Token = artifacts.require("./Token.sol");

var Loan = artifacts.require("./Loan.sol");

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

    await deployer.deploy(ExampleLoanTrust);
    await deployer.deploy(ExampleLoanInterest);

    var exampleLoanTrust = await ExampleLoanTrust.deployed();
    var exampleLoanInterest = await ExampleLoanInterest.deployed();

    await deployer.deploy(Token, "Token", "TOK", 100000);

    var token = await Token.deployed();

    var periodArray = [60 * 2, 60 * 2, 60 * 2];

    var arrContractAddresses = [
      exampleLoanTrust.address,
      exampleLoanInterest.address,
      token.address
    ]
  });
};
