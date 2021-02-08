var MarketBase = artifacts.require("./MarketBase.sol");
var ExampleLoanTrust = artifacts.require("xor-external-contract-examples/contracts/ExampleLoanTrust.sol");
var ExampleLoanInterest = artifacts.require("xor-external-contract-examples/contracts/ExampleLoanInterest.sol");
var Token = artifacts.require("./Token.sol");
var Loan = artifacts.require("./Loan.sol");

const MAX_UINT256 = 2**256 - 1

contract('Loan', function(accounts) {

  beforeEach(async function () {
    this.marketBase = await MarketBase.deployed();
    this.loanTrust = await ExampleLoanTrust.deployed();
    this.loanInterest = await ExampleLoanInterest.deployed();
    this.token = await Token.deployed();
    this.mintToken = await this.token.mint(accounts[0], 1000000);
    this.createMarket = await this.marketBase.createMarket(
      [60 * 2, 60 * 2, 60 * 2],
      [this.loanTrust.address, this.loanInterest.address, this.token.address]
    );
    this.loanAddress = this.createMarket.logs[0].args.contractAddress;
    this.loan = Loan.at(this.loanAddress);
  });

  describe('lender can offer loan after approving erc20 funds transfer', function() {
    it('should transfer funds successfully', async function() {
      await this.token.approve(this.loanAddress, 100000)
      await this.loan.fund(accounts[0], 100000)
      await this.loan.request(100000, {from: accounts[1]})
      const loanPool = await this.loan.getLoanPool()
      assert.equal(parseInt(loanPool), 100000)
    })
  })

  describe('borrower can accept loan', function() {
    it('should transfer funds to borrower successfully', async function() {
      // SETUP
      await this.token.approve(this.loanAddress, 100000)
      await this.loan.fund(accounts[0], 100000)
      await this.loan.request(100000, {from: accounts[1]})
      web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [121], id: 0});
      web3.currentProvider.send({jsonrpc: "2.0", method: "evm_mine", params: [], id: 0})
      const loanPeriod = await this.loan.checkLoanPeriod()
      assert.equal(loanPeriod, true)
      // SETUP Complete
      const accept = await this.loan.accept({from: accounts[1]})
      const balanceBorrower = await this.token.balanceOf(accounts[1])
      assert.equal(parseInt(balanceBorrower), 100000)
    })
  })

  describe('borrower can payback loan', function() {
    it('should transfer payback principal + interest to contract', async function() {
      // SETUP
      await this.token.approve(this.loanAddress, 1000000)
      await this.token.approve(this.loanAddress, 1000000, {from: accounts[1]})
      await this.token.transfer(this.loanAddress, 100000, {from: accounts[1]})
      await this.loan.fund(accounts[0], 100000)
      await this.loan.request(100000, {from: accounts[1]})
      web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [121], id: 0});
      web3.currentProvider.send({jsonrpc: "2.0", method: "evm_mine", params: [], id: 0})
      const loanPeriod = await this.loan.checkLoanPeriod()
      assert.equal(loanPeriod, true)
      const accept = await this.loan.accept({from: accounts[1]})
      web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [121], id: 0});
      web3.currentProvider.send({jsonrpc: "2.0", method: "evm_mine", params: [], id: 0})
      // SETUP Complete
      const totalRepayment = await this.loan.getTotalRepayment.call(accounts[1])
      await this.token.transfer(accounts[1], 15000)
      const initialBalance = await this.token.balanceOf(accounts[1])
      await this.loan.payback(accounts[1], parseInt(totalRepayment), {from: accounts[1]})
      const balanceBorrower = await this.token.balanceOf(accounts[1])
      const repaid = await this.loan.repaid(accounts[1], {from: accounts[1]})
      assert.equal(parseInt(balanceBorrower), 0)
      assert.equal(repaid, true)
    })
  })

  describe('lender can withdraw funds repaid', function() {
    it('should transfer collected funds to lender', async function() {
      // SETUP
      await this.token.approve(this.loanAddress, 1000000)
      await this.token.approve(this.loanAddress, 1000000, {from: accounts[1]})
      await this.loan.fund(accounts[0], 100000)
      await this.loan.request(100000, {from: accounts[1]})
      web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [121], id: 0});
      web3.currentProvider.send({jsonrpc: "2.0", method: "evm_mine", params: [], id: 0})
      const accept = await this.loan.accept({from: accounts[1]})
      web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [121], id: 0});
      web3.currentProvider.send({jsonrpc: "2.0", method: "evm_mine", params: [], id: 0})
      const totalRepayment = await this.loan.getTotalRepayment.call(accounts[1])
      await this.token.transfer(accounts[1], 15000)
      await this.loan.payback(accounts[1], parseInt(totalRepayment), {from: accounts[1]})
      const balanceBorrower = await this.token.balanceOf(accounts[1])
      const repaid = await this.loan.repaid(accounts[1], {from: accounts[1]})
      web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [121], id: 0});
      web3.currentProvider.send({jsonrpc: "2.0", method: "evm_mine", params: [], id: 0})
      const withdrawPeriod = await this.loan.checkWithdrawPeriod()
      assert.equal(withdrawPeriod, true)
      // SETUP Complete
      const initBalance = await this.token.balanceOf(accounts[0])
      const withdraw = await this.loan.withdraw(accounts[0], parseInt(totalRepayment))
      const finalBalance = await this.token.balanceOf(accounts[0])
      assert.equal(parseInt(finalBalance) - parseInt(initBalance), parseInt(totalRepayment))
    })
  })
});

