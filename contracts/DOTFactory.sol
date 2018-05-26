pragma solidity ^0.4.21;

import './DOT.sol';
import './StringUtils.sol';
import './Strings.sol';


contract DOTFactory {
	using strings for *;

	mapping(address => address[]) public created;
	mapping(address => bool) public isDOT;

	function createDOT(uint _id, uint _cap) public returns(address) {
		string memory id = uint2str(_id);
		string memory name = "DOT Token ".toSlice().concat(id.toSlice());
		string memory symbol = "DOT".toSlice().concat(id.toSlice());

		DOT newToken = (new DOT(name, symbol, _cap));
		created[msg.sender].push(address(newToken));
		isDOT[address(newToken)] = true;

		return address(newToken);
	}

	function getStrId(uint _str) public returns(bytes32) {
		return StringUtils.uintToBytes(_str);
	}

	function uint2str(uint i) internal pure returns (string){
    if (i == 0) return "0";
    uint j = i;
    uint length;
    while (j != 0){
        length++;
        j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint k = length - 1;
    while (i != 0){
        bstr[k--] = byte(48 + i % 10);
        i /= 10;
    }
    return string(bstr);
	}
}
