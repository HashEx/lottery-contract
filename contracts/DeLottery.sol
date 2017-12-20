pragma solidity ^0.4.18;
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';

/*
	подумать - что есть во время розыгрыша меняется стоимость
*/

contract DeLottery is Pausable {
	using SafeMath for uint256;

	uint32 public constant QUORUM = 3;

	address[] participants;
	uint participantsCount;

	uint public ticketPrice = 1 ether;

	uint public prizeFund = 0;

	uint public nextTicketPrice = 0;

	mapping(address => mapping(address => uint)) prizes;

	mapping(address => bool) lotteryRunners;

	/**
   	* @dev Throws if called by any account other than the owner.
   	*/
   	modifier canRunLottery() {
   		require(lotteryRunners[msg.sender]);
   		_;
   	}

	function DeLottery() public {
		setAsLotteryRunner(msg.sender, true);
	}

	function buyTicket() public payable whenNotPaused {
		require(msg.value == ticketPrice);
		require(!isContract(msg.sender));
		participants.push(msg.sender);
		participantsCount++;
		prizeFund = prizeFund.add(ticketPrice);
	}

	function setTicketPrice(uint tickerPrice) external onlyOwner {
		nextTicketPrice = tickerPrice;
	}

	function setAsLotteryRunner(address addr, bool canRunLottery) public onlyOwner {
		lotteryRunners[addr] = canRunLottery;
	}

	function runLottery() external whenNotPaused canRunLottery {
		require(participantsCount >= QUORUM);

		uint winnersCount;
		if(participantsCount < 10) {
			winnersCount = 1;
		} else {
			winnersCount = participantsCount / 10;
		}
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

		//set initial state
		prizeFund = 0;
		participantsCount = 0;

		for(uint k = 0; k < winnersCount; k++) {
			participants[uint(winners[k])].transfer(winnerPrize);
		}

		if(nextTicketPrice > 0) {
			ticketPrice = nextTicketPrice;
			nextTicketPrice = 0;
		}
	}

	function generateNextWinner(uint previousWinner, int[] winners, uint participantsCount) private returns(uint) {
		uint nonce = 0;
		uint winner = generateWinner(previousWinner, nonce, participantsCount);

		while(isInArray(winner, winners)) {
			nonce += 1;
			winner = generateWinner(previousWinner, nonce, participantsCount);
		}

		return winner;
	}

	function generateWinner(uint previousWinner, uint nonce, uint participantsCount) private returns (uint winner) {
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

		/**
	* @dev Function to get ether from contract
	* @param amount Amount in wei to withdraw
	*/
	function withdrawEther(address recipient, uint amount) external onlyOwner {
		recipient.transfer(amount);
	}

}