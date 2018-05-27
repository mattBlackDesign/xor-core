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
    // governanceContract = LoanGovernanceInterface(_contractAddressesArray[0]);
    trustContract = LoanTrustInterface(_contractAddressesArray[0]);
    interestContract = LoanInterestInterface(_contractAddressesArray[1]);
    dotContract = ERC827(_contractAddressesArray[2]);
    tokenContract = ERC827(_contractAddressesArray[3]);
  }


  /*** EVENTS ***/
  /**
   * @dev Triggered when a new lender enters market and offers a loan
   */
  event Funded(address lender, uint amount);

  event FundFailure(address lender);
  
  /**
   * @dev Triggered when a lender who has a refundable excess amount transfers
   *      excess amount back to his address
   */
  event ExcessTransferred(address lender, uint amount);
   
   /**
    * @dev Triggered when a lender collects their collectible amount in collection
    *      period
    */
  event Withdrawn(address lender, uint amount);

  event WithdrawFailure(address lender);
    
  /*** GETTERS ***/    
  /**
   * @dev Fetches all relevant information about a lender in a particular Market.
   *      Utilizes various getter functions written below
   */
  function getLender(address _lender) public view 
  returns(uint, uint, uint, uint, uint) {
    uint actualOffer = actualLenderOffer(_lender);
    return (
      lenderOffers[_lender], 
      actualOffer, 
      lenderWithdrawn[_lender], 
      getLenderWithdrawable(_lender),
      actualOffer.percent(getLoanPool(), 5)
    );
  }

  /**
   * @dev Calculates any excess lender funds that are not part of the market
   *      pool (when total amount offered > total amount requested)
   */
  function calculateExcess(address _lender) private view returns (uint) {
    uint lenderOffer = lenderOffers[_lender];
    if (totalOffered > totalRequested) {
      uint curValue = 0;
      for (uint i = 0; i < lenders.length; i++) {
        if (lenders[i] == _lender) {
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
        curValue = curValue.add(lenderOffers[lenders[i]]);
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
  function actualLenderOffer(address _lender) public view returns (uint) {
    return lenderOffers[_lender].sub(calculateExcess(_lender));
  }

  /**
   * @dev Retrieves the collectible amount for each lender from their investment/
   *      loan. Includes principal + interest - defaults.
   */
  function getLenderWithdrawable(address _lender) public view returns (uint) {
    uint temp = actualLenderOffer(_lender).mul(curRepaid).div(getLoanPool());
    return temp.sub(lenderWithdrawn[_lender]);
  }

  
  /**
   * @dev Returns true if given individual is a lender (after request period concludes 
   *      and excess lenders are removed), false otherwise
   */
  function lender(address _lender) public view returns (bool) {
    if ((checkRequestPeriod() && lenderOffers[_lender] > 0) ||
      actualLenderOffer(_lender) > 0) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if given lender has withdrawn their collectible
   *      amount
   */
  function withdrawn(address _lender) public view returns (bool) {
    if (getLenderWithdrawable(_lender) == lenderWithdrawn[_lender] &&
      lenderWithdrawn[_lender] != 0) {
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
   * Previously offerLoan()
   */ 
  function fund(address _lender, uint256 _capital) public returns (bool success) {
    if ((tokenContract.balanceOf(_lender) >= _capital) && 
    (_capital <= tokenContract.allowance(_lender, this)) &&
    checkRequestPeriod() && 
    (!lender(_lender)) &&
    _lender == msg.sender) {
      lenders.push(_lender);
      lenderOffers[_lender] = _capital;
      totalOffered = totalOffered.add(_capital);
      success = true;
      tokenContract.transferFrom(_lender, this, _capital);
      emit Funded(_lender, _capital);
    } else {
      success = false;
      emit FundFailure(_lender);
    } 
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
    require(lenderOffers[msg.sender] > 0);
    uint excessAmt = calculateExcess(msg.sender);
    tokenContract.transferFrom(this, msg.sender, excessAmt);
    emit ExcessTransferred(msg.sender, excessAmt);
  }

  /**
   * @dev Transfers collectible amount (interest + principal - defaults) to respective 
   *      lender
   * TODO: implement ability to withdraw twice
   */

  function withdraw(address _to, uint256 _capital) public returns (bool success) {
    if (checkWithdrawPeriod() && lender(_to) &&
      (!withdrawn(_to)) && (_to == msg.sender) &&
      (_capital <= getLenderWithdrawable(_to))) {
      lenderWithdrawn[_to] = lenderWithdrawn[_to].add(_capital);
      success = true;
      tokenContract.transferFrom(this, _to, _capital);
      emit Withdrawn(_to, _capital);
    } else {
      success = false;
      emit WithdrawFailure(_to);
    }
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
   * @dev Throws if lender being checked has not withdrawn their collectible amount
   */
  modifier hasWithdrawn(address _lender) {
    require (withdrawn(_lender));
    _;
  }

  /**
   * @dev Throws if lender being checked has withdrawn their collectible amount
   */
  modifier hasNotWithdrawn(address _lender) {
    require (!withdrawn(_lender));
    _;
  }


  /*** EVENTS ***/
  /**
   * @dev Triggered when a borrower enters market and requests a loan
   */
  event Requested(address borrower, uint amount);

  /**
   * @dev Triggered when a borrower has repaid his loan
   */
  event PaidBack(address borrower, uint amount);

  event PaybackFailure(address borrower);

  event Accepted(address borrower, uint amount);

  event AcceptFailure(address borrower);
  
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
      borrowerRequests[_borrower],
      actualRequest,
      borrowerAccepted[_borrower],
      borrowerRepaid[_borrower],
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
  function actualBorrowerRequest(address _borrower)
    public
    view
    returns(uint) 
  {
    uint borrowerRequest = borrowerRequests[_borrower];
    if (totalOffered >= totalRequested) {
      return borrowerRequests[_borrower];
    } else {
      uint curValue = 0;
      uint requestValue = 0;
      for(uint i = 0; i < borrowers.length; i++) {
        if (borrowers[i] == _borrower) {
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
        curValue = curValue.add(borrowerRequests[borrowers[i]]);
      }
      return requestValue;
    }
  }
  
  /**
   * @dev Fetches the total size of repayment a borrower has to make to cover
   *      principal + interest
   */
  function getTotalRepayment(address _borrower) public view returns (uint) {
    uint request = actualBorrowerRequest(_borrower);
    return request.add(getInterest(_borrower, request));
  }
  
  /**
   * @dev Fetches the index of a borrower within array of borrowers in Market 
   *      (from their address)
   * NOTE: This function currently not used anywhere
   */
  function getBorrowerIndex(address _borrower) public view returns (uint) {
    uint index = 0;
    for (uint i = 0; i < borrowers.length; i++) {
      if (borrowers[i] == _borrower) {
        index = i;
      }
    }
    return index;
  }

  /**
   * @dev Returns true if given individual is a borrower (after request period concludes 
   *      and excess borrowers are removed), false otherwise
   */
  function borrower(address _borrower) public view returns (bool) {
    if ((checkRequestPeriod() && borrowerRequests[_borrower] > 0) ||
      actualBorrowerRequest(_borrower) > 0) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if given borrower has withdrawn the entire amount of their
   *      loan request, false otherwise
   */
  function accepted(address _borrower) public view returns (bool) {
    if (borrowerRequests[_borrower] == borrowerAccepted[_borrower]
      && borrowerAccepted[_borrower] > 0) {
      return true;
    } else {
      return false;
    }
  }
  
  /**
   * @dev Returns true if a borrower has repaid his loan in the market, false
   * otherwise
   */
  function repaid(address _borrower) public view returns (bool) {
    uint actualRequest = actualBorrowerRequest(_borrower);
    uint expectedRepayment = actualRequest.add(getInterest(_borrower, actualRequest));
    if (borrowerRepaid[msg.sender] == expectedRepayment) {
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
    emit Requested(msg.sender, _amount);
  }

  /**
   * @dev Sends requested amount to borrower's address from lending pool
   */
  function accept() public returns (bool success) {
    if (checkLoanPeriod() && borrower(msg.sender) &&
      (!accepted(msg.sender))) {
      uint request = actualBorrowerRequest(msg.sender);
      borrowerAccepted[msg.sender] = request;
      curBorrowed = curBorrowed.add(request);
      success = true;
      tokenContract.transferFrom(this, msg.sender, request);
      emit Accepted(msg.sender, request);
    } else {
      success = false;
      emit AcceptFailure(msg.sender);
    }
  }
  
  /**
   * @dev Repays principal and interest back to "repayment pool" to be distributed
   *      to lenders
   * @notice Partial repayments not supported at this time.
   */
  function payback(address _from, uint256 _payment) public returns (bool success) {
    if (checkSettlementPeriod() && borrower(_from)
      && (!repaid(_from)) && _from == msg.sender &&
      (_payment <= tokenContract.allowance(_from, this))) {
      curRepaid = curRepaid.add(_payment);
      borrowerRepaid[_from] = _payment;
      addToRepayments(_from, _payment);
      success = true;
      tokenContract.transferFrom(_from, this, _payment);
      emit PaidBack(_from, _payment);
    } else {
      success = false;
      emit PaybackFailure(_from);
    }
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
  modifier hasRepaid(address _borrower) {
    require(repaid(_borrower));
    _;
  }
  
  /**
   * @dev Throws if borrower being checked has repaid their loan principal/interest
   */
  modifier hasNotRepaid(address _borrower) {
    require(!repaid(_borrower));
    _;
  }
  
  /**
   * @dev Throws if borrower being checked has not withdrawn the full amount
   *      of their loan request
   */
  modifier hasAccepted(address _borrower) {
    require(accepted(_borrower));
    _;
  }

  /**
   * @dev Throws if borrower being checked has withdrawn the full amount
   *      of their loan request
   */
  modifier hasNotAccepted(address _borrower) {
    require(!accepted(_borrower));
    _;
  }
}
