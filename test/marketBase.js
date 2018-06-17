var MarketBase = artifacts.require("./MarketBase.sol");
var ExampleLoanTrust = artifacts.require("xor-external-contract-examples/contracts/ExampleLoanTrust.sol");
var ExampleLoanInterest = artifacts.require("xor-external-contract-examples/contracts/ExampleLoanInterest.sol");
var Token = artifacts.require("./Token.sol");
var Loan = artifacts.require("./Loan.sol");

contract('MarketBase', function(accounts) {

  // it("...should store the value 89.", function() {
  //   return SimpleStorage.deployed().then(function(instance) {
  //     simpleStorageInstance = instance;

  //     return simpleStorageInstance.set(89, {from: accounts[0]});
  //   }).then(function() {
  //     return simpleStorageInstance.get.call();
  //   }).then(function(storedData) {
  //     assert.equal(storedData, 89, "The value 89 was not stored.");
  //   });
  // });
  beforeEach(async function () {
    this.marketBase = await MarketBase.deployed();
    this.loanTrust = await ExampleLoanTrust.deployed();
    this.loanInterest = await ExampleLoanInterest.deployed();
    this.token = await Token.deployed();
    this.createMarket = await this.marketBase.createMarket(
      [60 * 2, 60 * 2, 60 * 2],
      [this.loanTrust.address, this.loanInterest.address, this.token.address]
    );
    this.loanAddress = this.createMarket.logs[0].args.contractAddress;
    this.loan = Loan.at(this.loanAddress);
  });

  describe('test', function() {
    it('should return', async function() {
      const isBorrower = await this.loan.borrower("0x0000000000000000000000000000000000000000");
      assert.equal(isBorrower,false);
    })
  })
});



// var MarketCore = artifacts.require("./MarketCore.sol");
// var ExampleMarketTrust = artifacts.require("xor-external-contract-examples/contracts/ExampleMarketTrust.sol");
// var ExampleMarketInterest = artifacts.require("xor-external-contract-examples/contracts/ExampleMarketInterest.sol");

// const utils = require('./helpers/Utils');

// contract('MarketCore', function(accounts) {

//   beforeEach(async function () {
//     this.exampleMarketTrust = await ExampleMarketTrust.deployed();
//     this.exampleMarketInterest = await ExampleMarketInterest.deployed();
//     this.exampleContractAddresses = ["0x0000", this.exampleMarketTrust.address,
//     this.exampleMarketInterest.address];
//     this.marketCore = await MarketCore.deployed();
//     this.createMarket = await this.marketCore.createMarket(
//       1000,
//       1000,
//       1000,
//       this.exampleContractAddresses
//     );
//     this.createMarket2 = await this.marketCore.createMarket(
//       1000,
//       1000,
//       1000,
//       this.exampleContractAddresses
//     );
//     this.marketId = this.createMarket.logs[0].args["marketId"].toNumber();
//   })

//   describe('getMarketCount', function() {
//     describe('when two markets has been created', function() {
//       it('should return two', async function() {
//         const count = await this.marketCore.getMarketCount();

//         assert.equal(count.toNumber(), 3); // Need to account for deployment market
//       })
//     })
//   })

//   describe('marketPool', function() {
//     it('should be zero wei when there is only lenders', async function() {
//       await this.marketCore.offerLoan(this.marketId, {value: web3.toWei(10), from: accounts[0]});

//       const value = await this.marketCore.getMarketPool(this.marketId);
//       console.log("MARKET POOL:" + value);
//       assert.equal(value.toNumber(), 0);
//     })

//     it('should be zero wei when there is only borrowers', async function() {
//       await this.marketCore.requestLoan(this.marketId, web3.toWei(5), {from: accounts[1]});

//       const value = await this.marketCore.getMarketPool(this.marketId);

//       assert.equal(value.toNumber(), 0);
//     })

//     it('should be total lenders wei when there is more wei from borrowers', async function() {
//       await this.marketCore.offerLoan(this.marketId, {value: web3.toWei(5), from: accounts[0]});
//       await this.marketCore.requestLoan(this.marketId, web3.toWei(10), {from: accounts[1]});

//       const value = await this.marketCore.getMarketPool(this.marketId);

//       assert.equal(value.toNumber(), web3.toWei(5));
//     })

//     it('should be total borrower wei when there is more wei from lenders', async function() {
//       await this.marketCore.offerLoan(this.marketId, {value: web3.toWei(10), from: accounts[0]});
//       await this.marketCore.requestLoan(this.marketId, web3.toWei(5), {from: accounts[1]});

//       const value = await this.marketCore.getMarketPool(this.marketId);

//       assert.equal(value.toNumber(), web3.toWei(5));
//     })

//     it('should be borrower and lender wei when borrower and lender wei is equal', async function() {
//       await this.marketCore.offerLoan(this.marketId, {value: web3.toWei(5), from: accounts[0]});
//       await this.marketCore.requestLoan(this.marketId, web3.toWei(5), {from: accounts[1]});

//       const value = await this.marketCore.getMarketPool(this.marketId);

//       assert.equal(value.toNumber(), web3.toWei(5));
//     })
//   })
// });
