var MarketBase = artifacts.require("./MarketBase.sol");
var ExampleLoanTrust = artifacts.require("xor-external-contract-examples/contracts/ExampleLoanTrust.sol");
var ExampleLoanInterest = artifacts.require("xor-external-contract-examples/contracts/ExampleLoanInterest.sol");
var Token = artifacts.require("./Token.sol");
var Loan = artifacts.require("./Loan.sol");

contract('MarketBase', function(accounts) {

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
