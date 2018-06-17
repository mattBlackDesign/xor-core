pragma solidity ^0.4.21;

import './Loan.sol';

contract LoanFactory {
	function createLoan(uint[] _periodArray, uint _riskConstant, address[] _contractAddressesArray, address dotAddress) public returns(address) {
		Loan loan = new Loan(_periodArray, _riskConstant, _contractAddressesArray, dotAddress);
		return address(loan);
	}
}
