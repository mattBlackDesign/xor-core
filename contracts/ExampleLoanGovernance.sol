// pragma solidity ^0.4.21;

// import '@daostack/arc/contracts/VotingMachines/GenesisProtocol.sol';

// /**
//   * @title LoanTrustInterface
//   * @dev Interface for XOR Loan Trust Contract for calculating trust score
//  */

// contract ExampleLoanGovernanceInterface {

//   // Address from LoanCore
//   function getDOTTokenAddress() public returns(address);
// }

// contract ExampleLoanAvatarInterface {

//   function createAvatar(bytes32 _randomStr, DAOToken daoToken, Reputation reputation) public returns(address);
// }


// /**
//   * @title ExampleLoanTrust
//   * @dev Example Loan Trust contract for showing trust score programmability.
//   */
// contract ExampleLoanGovernance  {
//   ExampleLoanGovernanceInterface exampleLoanGovernanceContract;
//   ExampleLoanAvatarInterface exampleLoanAvatarContract;
//   GenesisProtocol genesisProtocolContract;
//   ExecutableInterface executableInterfaceContract;
//   // Avatar avatar;
//   address avatarAddress;


//   /**
//     * @dev Set the address of the sibling contract that tracks trust score.
//    */
//   function setLoanGovernanceContractAddress(address _address) external {
//     exampleLoanGovernanceContract = ExampleLoanGovernanceInterface(_address);
//   }

//   /**
//     * @dev Get the address of the sibling contract that tracks trust score.
//    */
//   function getLoanGovernanceContractAddress() external view returns(address) {
//     return address(exampleLoanGovernanceContract);
//   }


//   /**
//     * @dev Set the address of the sibling contract that tracks trust score.
//    */
//   function setLoanAvatarContractAddress(address _address) external {
//     exampleLoanAvatarContract = ExampleLoanAvatarInterface(_address);
//   }

//   *
//     * @dev Get the address of the sibling contract that tracks trust score.
   
//   function getLoanAvatarContractAddress() external view returns(address) {
//     return address(exampleLoanAvatarContract);
//   }

//   function getGenesisProtocolContractAddress() external view returns(address) {
//     return address(genesisProtocolContract);
//   }

//   function createGovernance() public {
//     StandardToken dotToken = StandardToken(exampleLoanGovernanceContract.getDOTTokenAddress());

//     genesisProtocolContract = new GenesisProtocol(dotToken);

//     uint[12] memory params;
//     params[0] = 50;
//     params[1] = 60;
//     params[2] = 60;
//     params[3] = 1;
//     params[4] = 1;
//     params[5] = 0;
//     params[6] = 0;
//     params[7] = 60;
//     params[8] = 1;
//     params[9] = 1;
//     params[10] = 10;
//     params[11] = 80;

//     genesisProtocolContract.setParameters(params);
//     executableInterfaceContract = ExecutableInterface(address(this));
//     Reputation reputation = new Reputation();
//     DAOToken daoToken = DAOToken(exampleLoanGovernanceContract.getDOTTokenAddress());
//     avatarAddress = exampleLoanAvatarContract.createAvatar(keccak256(address(exampleLoanGovernanceContract)), daoToken, reputation);
//   }

//   function propose(uint _numOfChoices, address _proposer) public returns(bytes32) {
//     genesisProtocolContract.propose(_numOfChoices, "", avatarAddress, executableInterfaceContract, msg.sender);
//   }

//   // function getParametersHash(
//   //   uint[12] _params) //use array here due to stack too deep issue.
//   //       public
        
//   //       returns(bytes32) {
//   //   return genesisProtocolContract.getParametersHash(_params);
//   // }

//   // function execute(bytes32 _proposalId) public {
//   //   genesisProtocolContract.execute(_proposalId);
//   // }
// }

