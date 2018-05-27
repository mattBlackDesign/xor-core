pragma solidity ^0.4.21;

import './ERC1068.sol';
import 'openzeppelin-solidity/contracts/token/ERC827/ERC827.sol';

// contract LoanGovernanceInterface {
//   function createGovernance() public;
//   function getGenesisProtocolContractAddress() external view returns(address);
// }

/**
 * @title LoanTrustInterface
 * @dev Interface for custom contracts calculating trust score
 */

contract LoanTrustInterface {
  /**
  * @dev Calculates trust score for borrowers which will be used to determine
  *      their interest payment
  * @param _address Address of individual being checked
  */ 
  function getTrustScore(address _address) external view returns (uint);
}

/**
 * @title MarketInterestInterface
 * @dev Interface for custom contracts calculating interest
 */

contract LoanInterestInterface {
  /**
   * @dev Calculates interest payment for borrowers
   * @param _address Address of individual being checked
   * @param _amt The amount being requested by borrower in current market
   */ 
  function getInterest(address _address, uint _amt) external view returns (uint);
}


contract LoanBase is ERC1068 {
	MintableToken dotContract;
	ERC827 tokenContract;

  // Time in Linux Epoch Time of Version creation
  uint updatedAt; 

  // Duration of "Request Period" during which borrowers submit loan requests 
  // and lenders offer loans
  uint requestPeriod;
  
  // Duration of "Loan Period" during which the loan is actually taken out
  uint loanPeriod;
  
  // Duration of "Settlement Period" during which borrowers repay lenders
  uint settlementPeriod; 
  
  // @notice Reason "Collection Period" is not a field is because it is infinite
  //         by default. Lenders have an unlimited time period within which
  //         they can collect repayments and interest 

  // Size of lending pool put forward by lenders in market (in Wei)
  uint totalOffered; 

  // Value of total amount requested by borrowers in market (in Wei)
  uint totalRequested; 
  
  // Amount taken out by borrowers on loan at a given time (in Wei)
  uint curBorrowed; 
  
  // Amount repaid by borrowers at a given time (in Wei)
  uint curRepaid;

  // Address of external governance contract
  // address governanceContractAddress;
  // LoanGovernanceInterface governanceContract;

  // Address of external trust contract
  LoanTrustInterface trustContract;

  // Address of external interest contract
  LoanInterestInterface interestContract;

  // Array of all lenders participating in the market
  address[] lenders; 
  
  // Array of all borrowers participating in the market
  address[] borrowers; 

  // Mapping of each lender (their address) to the size of their loan offer
  // (in Wei); amount put forward by each lender
  mapping (address => uint) lenderOffers; 
  
  // Mapping of each borrower (their address) to the size of their loan request
  // (in Wei)
  mapping (address => uint) borrowerRequests;
  
  // Mapping of each borrower to amount they have withdrawn from their loan (in Wei)
  mapping (address => uint) borrowerAccepted; 
  
  // Mapping of each borrower to amount of loan they have repaid (in Wei)
  mapping (address => uint) borrowerRepaid;

  // Mapping of each lender to amount that they have withdrawn back from loans (in Wei)
  // NOTE: Currently, lenders must collect their entire collectible amount
  //       at once. In future, there are plans to allow lenders to only collect part of 
  //       collectible amount at any one time
  mapping (address => uint) lenderWithdrawn;

  /**
   * @dev A public function that retrieves the size of the getMarketPool actually
   *      available for loans. Takes the minimum of total amount requested by
   *      borrowers and total amount offered by lenders
   */
  function getLoanPool() public view returns (uint) {
    if (totalOffered >= totalRequested) {
      return totalRequested;
    } else {
      return totalOffered;
    }
  }
}
