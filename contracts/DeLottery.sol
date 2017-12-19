pragma solidity ^0.4.18;
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

/*
	подумать - что есть во время розыгрыша меняется стоимость
*/

contract DeLottery is Ownable {
	using SafeMath for uint256;

	uint32 public constant QUORUM = 3;

	address[] participants;

	uint public ticketPrice = 1 ether;

	uint public prizeFund = 0;

	mapping(address => mapping(address => uint)) prizes;

	function DeLottery() public {
	}

	function buyTicket() public payable {
		require(msg.value == ticketPrice);
		require(!isContract(msg.sender));
		participants.push(msg.sender);
		prizeFund = prizeFund.add(ticketPrice);
	}

	function setTicketPrice(uint _tickerPrice) external onlyOwner {
		ticketPrice = _tickerPrice;
	}

	function runLottery() external onlyOwner {
		uint participantsCount = participants.length;
		require(participantsCount >= QUORUM);

		uint winnersCount = participantsCount / 10 + 1;
		uint winnerPrize = prizeFund / winnersCount * 19 / 20;

		int[] memory winners = new int[](winnersCount);

		for(uint64 j = 0; j < winnersCount; j++) {
			winners[j] = -1;
		}

		uint lastWinner = generateWinner(0, 0, participantsCount);
		winners[0] = int(lastWinner);

		for(uint i = 1; i < winnersCount; i++) {
			lastWinner = generateNextWinner(lastWinner, winners, participantsCount);
			winners[i] = int(lastWinner);
		}

		prizeFund = 0;

		for(uint k = 0; k < winnersCount; k++) {
			participants[uint(winners[k])].transfer(winnerPrize);
		}
	}

	function generateNextWinner(uint previousWinner, int[] winners, uint participantsCount) returns(uint) {
		uint nonce = 0;
		uint winner = generateWinner(previousWinner, nonce, participantsCount);

		while(isInArray(winner, winners)) {
			nonce += 1;
			winner = generateWinner(previousWinner, nonce, participantsCount);
		}

		return winner;
	}

	function generateWinner(uint previousWinner, uint nonce, uint participantsCount) internal returns (uint winner) {
		return uint(keccak256(uint(block.blockhash(block.number - 1)), previousWinner, nonce)) % participantsCount;
	}

	function isInArray(uint element, int[] array) private pure returns (bool) {
		for(uint64 i = 0; i < array.length; i++) {
			if(uint(array[i]) == element) {
				return true;
			}
		}
		return false;
	}

	function isContract(address _addr) private view returns (bool is_contract) {
		uint length;
		assembly {
			//retrieve the size of the code on target address, this needs assembly
			length := extcodesize(_addr)
		}
		return (length>0);
	}

}