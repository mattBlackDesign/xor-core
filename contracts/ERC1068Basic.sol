import './ERC1068.sol'

contract ERC1068Basic is ERC1068 {
  /// @notice returns the amount of tokens that borrower is asking for.
  /// @dev returns the amount of the loan, the amount of ERC20 Tokens that the borrower is asking for.
  function getAmount() public view returns(uint256);

  /// @notice returns the address of the token used in the loan.
  /// @dev returns the address of the ERC20 Token used in the loan.
  function getTokenAddress() public view returns(address);

  /// @notice returns the address of the beneficiary of the loan.
  /// @dev returns the address of the beneficiary of the loan 'borrower'.
  function getBorrower() public view returns(address);

  /// @notice returns the terms of the loan.
  /// @dev returns the address of the beneficiary of the loan 'borrower'.
  function getTerms() public view returns(bytes32);

  /// @notice cancel the loan. (i.e. borrower Morty got the tokens from other source and doesn't needs Rick tokens, then Morty cancel the loan).
  /// @dev change the loan stage to canceled.
  function cancel() public returns (bool success);

  /// @notice trigger when the loan is available to be funded.
  /// @dev trigger when the loan change to stage Funding.
  /// @param token address of the token to be lend.
  /// @param borrower address where the loan is received.
  /// @param requiredCapital amount of tokens that the borrower is asking for.
  event Begun(address token, address borrower, uint256 requiredCapital);

  /// @notice trigger when cancel function is successfully called.
  /// @dev trigger when cancel function is successfully called.
  /// @param who who trigger the cancel function.
  event Cancelled(address _who);

  /// @notice trigger when total payment paid by borrower is lower than the total amout to be paid and the time to paid the loan expire.
  /// @dev trigger when total payment paid by borrower is higher than the total amout to be paid and the time to paid the loan expire.
  /// @param borrower who ask for the loan.
  /// @param debt amount of tokens that the borrower has as debt.
  event Defaulted(address borrower, uint256 debt);

  /// @notice trigger when the borrower paid the whole loan back.
  /// @dev trigger when total payment paid by borrower is higher than the total amout to be paid.
  /// @param borrower who ask for the loan.
  event Finished(address borrower);

}