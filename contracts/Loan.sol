pragma solidity ^0.4.21; 

import './LoanInterest.sol';


/**
  * @title MarketLend
  * @dev Contract containing business logic pertaining to lenders within a market
 */
contract Loan is LoanInterest {

  /** 
   * @param _periodArray 
            [request, loan, settlement]
   * @param _contractAddressesArray An array containing the addresses of instance
   *                               component contracts
   *                               [governance, trust, interest, dotAddress, tokenAddress]
   */
  function Loan(uint[] _periodArray, address[] _contractAddressesArray) public {
    requestPeriod = _periodArray[0];
    loanPeriod = _periodArray[1];
    settlementPeriod = _periodArray[2];
    governanceContract = LoanGovernanceInterface(_contractAddressesArray[0]);
    trustContract = LoanTrustInterface(_contractAddressesArray[1]);
    interestContract = LoanInterestInterface(_contractAddressesArray[2]);
    dotContract = ERC827(_contractAddressesArray[3]);
    tokenContract = ERC827(_contractAddressesArray[4]);
  }


  /*** EVENTS ***/
  /**
   * @dev Triggered when a new lender enters market and offers a loan
   * @param _address Address of lender
   */
  event LoanOffered(address lender, uint amount);
  
  /**
   * @dev Triggered when a lender who has a refundable excess amount transfers
   *      excess amount back to his address
   */
   event ExcessTransferred(address lender, uint amount);
   
   /**
    * @dev Triggered when a lender collects their collectible amount in collection
    *      period
    */
    event Collected(address lender, uint amount);
    
  /*** GETTERS ***/    
  /**
   * @dev Fetches all relevant information about a lender in a particular Market.
   *      Utilizes various getter functions written below
   */
  function getLender(address _lender) public view 
  returns(uint, uint, uint, uint, uint) {
    uint actualOffer = actualLenderOffer(_lender);
    return (
      getLenderOffer(_lender), 
      actualOffer, 
      getLenderCollected(_lender), 
      getLenderCollectible(_lender),
      actualOffer.percent(getLoanPool(), 5)
    );
  }

  /**
   * @dev Calculates any excess lender funds that are not part of the market
   *      pool (when total amount offered > total amount requested)
   */
  function calculateExcess(address _lender) private view returns (uint) {
    uint lenderOffer = getLenderOffer(_lender);
    if (totalOffered > totalRequested) {
      uint curValue = 0;
      for (uint i = 0; i < getLenderCount(); i++) {
        if (getLenderAddress(i) == _lender) {
          if (curValue <= totalRequested) {
            uint newValue = curValue.add(lenderOffer);
            if (newValue > totalRequested) {
              uint diff = totalRequested.sub(curValue);
              return lenderOffer.sub(diff);
            } else {
              return 0;
            }
          }
          break;
        }
        curValue = curValue.add(getLenderOffer(getLenderAddress(i)));
      }
    } else {
      return 0;
    }
  }
  
  /**
   * @dev Retrieves the "actual" size of loan offer corresponding to particular
   *      lender (after excess has been removed)
   * @notice This value would only differ from return value of getLenderOffer()
   *         for the same lender if total amount offered > total amount 
   *         requested and the lender is near the end of the queue
   * @notice This value should only differ from return value of getLenderOffer() for 
   *         ONE lender in a Market instance
   */ 
  function actualLenderOffer(address _address) public view returns (uint) {
    return getLenderOffer(_address).sub(calculateExcess(_address));
  }

  /**
   * @dev Retrieves the collectible amount for each lender from their investment/
   *      loan. Includes principal + interest - defaults.
   */
  function getLenderCollectible(address _address) public view returns (uint) {
    return actualLenderOffer(_address).mul(getMarketCurRepaid()).div(getLoanPool());
  }

  function getLenderCount() public view returns (uint) {
    return lenders.length;
  }

  /**
   * @dev Retrieves address of a lender from their lenderID in market
   */
  function getLenderAddress(uint _lenderId) public view returns (address) {
    return lenders[_lenderId];
  }
  
  /**
   * @dev Returns true if given individual is a lender (after request period concludes 
   *      and excess lenders are removed), false otherwise
   */
  function lender(address _address) public view returns (bool) {
    if ((checkRequestPeriod() && getLenderOffer(_address) > 0) ||
      actualLenderOffer(_address) > 0) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if given lender has collected their collectible
   *      amount
   */
  function collected(address _address) public view returns (bool) {
    if (getLenderCollectible(_address) == getLenderCollected(_address) &&
      getLenderCollected(_address) != 0) {
      return true;
    } else {
      return false;
    }
  }

  /*** SETTERS & TRANSACTIONS ***/
  /**
   * @dev Offers a loan, and locks funds into the Market contract. Caller
   *      then becomes a lender in the current market.
   * @notice Even when a lender offers a loan with this function, at the end of
   *         the request period, they may not necessarily remain a lender (and
   *         thus have their funds returned) if total amount offered > total amount 
   *         requested
   */ 
  function offerLoan()
    external
    payable
    isRequestPeriod()
    isNotLender(msg.sender)
  {
    lenders.push(msg.sender);
    lenderOffers[msg.sender] = msg.value;
    totalOffered = totalOffered.add(msg.value);
    emit LoanOffered(msg.sender, msg.value);
  }

  /**
   * @dev Called by lenders who have been removed. Transfers excess amount exceeding
   *      market pool back to them.
   * TODO: try catch for when person calling is not lender
   */
  function transferExcess() 
    external 
    isLender(msg.sender)
    isAfterRequestPeriod() 
  {
    require(getLenderOffer(msg.sender) > 0);
    uint excessAmt = calculateExcess(msg.sender);
    msg.sender.transfer(excessAmt);
    emit ExcessTransferred(msg.sender, excessAmt);
  }

  /**
   * @dev Transfers collectible amount (interest + principal - defaults) to respective 
   *      lender
   */
  function collectCollectible() 
    external
    isCollectionPeriod() isLender(msg.sender)
    hasNotCollected(msg.sender) 
  {
    uint collectibleAmt = getLenderCollectible(msg.sender);
    lenderCollected[msg.sender] = collectibleAmt;
    msg.sender.transfer(collectibleAmt);
    emit CollectibleCollected(msg.sender, collectibleAmt);
  }
  
  /*** MODIFIERS ***/
  /**
   * @dev Throws if individual being checked is not a lender in market
   */
  modifier isLender(address _address) {
    require(lender(_address));
    _;
  }
  
  /**
   * @dev Throws if individual being checked is a lender in market
   */
  modifier isNotLender(address _address) {
    require (!lender(_address));
    _;
  }
  
  /**
   * @dev Throws if lender being checked has not collected their collectible amount
   */
  modifier hasCollected(address _address) {
    require (collected(_address));
    _;
  }

  /**
   * @dev Throws if lender being checked has collected their collectible amount
   */
  modifier hasNotCollected(address _address) {
    require (!collected(_address));
    _;
  }
}



  /*** EVENTS ***/
  /**
   * @dev Triggered when a borrower enters market and requests a loan
   */
  event LoanRequested(address borrower, uint amount);

  /**
   * @dev Triggered when a borrower has repaid his loan
   */
  event LoanRepaid(address borrower, uint amount);
  
  /*** GETTERS ***/
  /**
   * @dev Fetches all relevant information about a borrower in a particular Market.
   *      Utilizes various getter functions written below
   */
  function getBorrower(address _borrower) 
    public 
    view 
    returns(uint, uint ,uint ,uint ,uint) 
  {
    uint actualRequest = actualBorrowerRequest(_borrower);
    return (
      getBorrowerRequest(_borrower),
      actualRequest,
      getBorrowerWithdrawn(_borrower),
      getBorrowerRepaid(_borrower),
      actualRequest.percent(getLoanPool(), 5)
    );
  }
  
  /**
   * @dev Retrieves the "actual" size of loan request corresponding to particular
   *      borrower (after excess has been removed)
   * @notice This value would only differ from return value of getBorrowerRequest()
   *         for the same borrower if total amount requested > total amount 
   *         offered and the borrower is near the end of the queue
   * @notice This value should only differ from return value of getBorrowerRequest() for 
   *         ONE borrower in a Market instance
   */ 
  function actualBorrowerRequest(address _address) 
    public
    view
    returns(uint) 
  {
    uint borrowerRequest = getBorrowerRequest(_address);
    if (totalOffered >= totalRequested) {
      return getBorrowerRequest(_address);
    } else {
      uint curValue = 0;
      uint requestValue = 0;
      for(uint i = 0; i < getBorrowerCount(); i++) {
        if (getBorrowerAddress(i) == _address) {
          if (curValue < totalOffered) {
            uint newValue = curValue.add(borrowerRequest);
            if (newValue > totalOffered) {
              uint diff = newValue.sub(totalOffered);
              requestValue = borrowerRequest.sub(diff);
            } else {
              requestValue = borrowerRequest;
            }
          }
          break;
        }
        curValue = curValue.add(getBorrowerRequest(getBorrowerAddress(i)));
      }
      return requestValue;
    }
  }
  
  /**
   * @dev Fetches the total size of repayment a borrower has to make to cover
   *      principal + interest
   */
  function getTotalRepayment(address _address) public view returns (uint) {
    uint request = actualBorrowerRequest(_address);
    return request.add(getInterest(_address, request));
  }
  
  /**
   * @dev Fetches the index of a borrower within array of borrowers in Market 
   *      (from their address)
   * NOTE: This function currently not used anywhere
   */
  function getBorrowerIndex(address _borrowerAddress) public view returns (uint) {
    uint index = 0;
    for (uint i = 0; i < getBorrowerCount(); i++) {
      if (getBorrowerAddress(i) == _borrowerAddress) {
        index = i;
      }
    }
    return index;
  }

  /**
   * @dev Fetches the number of registered borrowers in a certain market
   */
  function getBorrowerCount() public view returns (uint) {
    return borrowers.length;
  }

  /**
   * @dev Retrieves address of a borrower from their borrowerID in market
   */
  function getBorrowerAddress(uint _borrowerId) public view returns (address) {
    return borrowers[_borrowerId];
  }

  /**
   * @dev Returns true if given individual is a borrower (after request period concludes 
   *      and excess borrowers are removed), false otherwise
   */
  function borrower(address _address) public view returns (bool) {
    if ((checkRequestPeriod() && getBorrowerRequest(_address) > 0) || 
      actualBorrowerRequest(_address) > 0) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if given borrower has withdrawn the entire amount of their
   *      loan request, false otherwise
   */
  function withdrawn(address _address) public view returns (bool) {
    if (getBorrowerRequest(_address) == getBorrowerWithdrawn(_address)
      && getBorrowerWithdrawn(_address) > 0) {
      return true;
    } else {
      return false;
    }
  }
  
  /**
   * @dev Returns true if a borrower has repaid his loan in the market, false
   * otherwise
   */
  function repaid(address _address) public view returns (bool) {
    uint actualRequest = actualBorrowerRequest(_address);
    uint expectedRepayment = actualRequest.add(getInterest(_address, actualRequest));
    if (getBorrowerRepaid(msg.sender) == expectedRepayment) {
      return true;
    } else {
      return false;
    }
  }
  
  /*** SETTERS & TRANSACTIONS ***/
  /**
   * @dev Submits a Loan Request in the Market. Caller then becomes a borrower in
   *      the current Market.
   * @notice Even when a borrower submits a request with this function, at the end of
   *         the request period, they may not necessarily remain a borrower (and
   *         (and thus not receive their loan) if total amount requested > total amount 
   *         offered
   */ 
  function requestLoan(uint _amount)
    external
    isRequestPeriod()
    isNotBorrower(msg.sender)
    isNotLender(msg.sender)
  {
    borrowers.push(msg.sender);
    borrowerRequests[msg.sender] = _amount;
    totalRequested = totalRequested.add(_amount);
    emit LoanRequested(msg.sender, _amount);
  }

  /**
   * @dev Withdraws requested amount to borrower's address from lending pool
   */
  function withdrawRequested()
    external
    isLoanPeriod()
    isBorrower(msg.sender)
    hasNotWithdrawn(msg.sender)
  {
    uint request = actualBorrowerRequest(msg.sender);
    msg.sender.transfer(request);
    borrowerWithdrawn[msg.sender] = request;
    curBorrowed = curBorrowed.add(request);
  }
  
  /**
   * @dev Repays principal and interest back to "repayment pool" to be distributed
   *      to lenders
   * @notice Partial repayments not supported at this time.
   */
  function repay()
    external
    payable
    isSettlementPeriod()
    isBorrower(msg.sender)
    hasNotRepaid(msg.sender)
  {
    curRepaid = curRepaid.add(msg.value);
    borrowerRepaid[msg.sender] = msg.value;
    addToRepayments(msg.sender, msg.value);
    emit LoanRepaid(msg.sender, msg.value);
  }

  /*** MODIFIERS ***/
  /**
   * @dev Throws if individual being checked is not a borrower in market
   */
  modifier isBorrower(address _address) {
    require(borrower(_address));
    _;
  }

  /**
   * @dev Throws if individual being checked is a borrower in market
   */
  modifier isNotBorrower(address _address) {
    require (!borrower(_address));
    _;
  }
  
  /**
   * @dev Throws if borrower being checked has not repaid their loan principal/interest
   */
  modifier hasRepaid(address _address) {
    require(repaid(_address));
    _;
  }
  
  /**
   * @dev Throws if borrower being checked has repaid their loan principal/interest
   */
  modifier hasNotRepaid(address _address) {
    require(!repaid(_address));
    _;
  }
  
  /**
   * @dev Throws if borrower being checked has not withdrawn the full amount
   *      of their loan request
   */
  modifier hasWithdrawn(address _address) {
    require(withdrawn(_address));
    _;
  }

  /**
   * @dev Throws if borrower being checked has withdrawn the full amount
   *      of their loan request
   */
  modifier hasNotWithdrawn(address _address) {
    require(!withdrawn(_address));
    _;
  }
}
