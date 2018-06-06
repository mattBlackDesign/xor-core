
pragma solidity ^0.4.4;

import "openzeppelin-solidity/contracts/token/ERC827/ERC827Token.sol";
import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
// import '@daostack/arc/contracts/VotingMachines/GenesisProtocol.sol';

/*
 * Token
 *
 * Very simple ERC20 Token example, where all tokens are pre-assigned
 * to the creator. Note they can later distribute these tokens
 * as they wish using `transfer` and other `StandardToken` functions.
 */
contract Token is ERC827Token, MintableToken, BurnableToken {

  string public name;
  string public symbol;
  uint public constant DECIMAL = 18;
  uint public cap;

  /**
  * @dev Constructor
  * @param _name - token name
  * @param _symbol - token symbol
  * @param _cap - token cap - 0 value means no cap
  */
  function Token(string _name, string _symbol, uint _cap) public {
      name = _name;
      symbol = _symbol;
      cap = _cap;
  }

}
