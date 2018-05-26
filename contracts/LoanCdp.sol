pragma solidity ^0.4.21;

import "./LoanBase.sol";

contract TubInterface {
  function sai() public returns (address);
	function join(uint wad) public;
	function open() public returns (bytes32 cup);
	function lock(bytes32 cup, uint wad) public;
	function draw(bytes32 cup, uint wad) public;
}

// contract WethInterface {
// 	function deposit() public payable;
// 	function approve(address guy, uint wad) public returns (bool);
// }

contract LoanCdp is LoanBase {
	TubInterface tubContract;
	// WethInterface wethContract;

  function setTubContractAddress(address _address) external {
    tubContract = TubInterface(_address);
  }

  function getTubContractAddress() external view returns(address) {
    return address(tubContract);
  }

  // function setWethContractAddress(address _address) external {
  //   wethContract = WethInterface(_address);
  // }

  // function getWethContractAddress() external view returns(address) {
  //   return address(wethContract);
  // }

  function join(uint wad) public {
  	tubContract.join(wad);
  }

  function open() public returns(bytes32 cup) {
  	tubContract.open();
  }

  function lock(bytes32 cup, uint wad) public {
  	tubContract.lock(cup, wad);
  }

  function draw(bytes32 cup, uint wad) public {
  	tubContract.draw(cup, wad);
  }

  function sai() public returns (address) {
    tubContract.sai();
  }
}
