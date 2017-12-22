pragma solidity ^0.4.18;
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';

contract DeLottery is Pausable {
	using SafeMath for uint256;

	uint32 public constant QUORUM = 3;

	address[] gamblers;

	uint public ticketPrice = 1 ether;

	uint public prizeFund = 0;

	uint public nextTicketPrice = 0;

	mapping(address => mapping(address => uint)) prizes;

	mapping(address => bool) lotteryRunners;

   	modifier canRunLottery() {
   		require(lotteryRunners[msg.sender]);
   		_;
   	}

	function DeLottery() public {
		lotteryRunners[msg.sender] = true;
	}

	function () public payable whenNotPaused {
		require(!isContract(msg.sender));
		require(gamblers.length <= 100);

		uint ticketsBought = msg.value / ticketPrice;

		for(uint16 i = 0; i < ticketsBought; i++) {
			gamblers.push(msg.sender);
		}

		prizeFund = prizeFund.add(ticketsBought * ticketPrice);

		//return change
		uint change = msg.value % ticketPrice;
		if(change > 0) {
			msg.sender.transfer(change);
		}
	}

	function setTicketPrice(uint _ticketPrice) external onlyOwner {
		if(gamblers.length == 0) {
			ticketPrice = _ticketPrice;
			nextTicketPrice = 0;
		} else {
			nextTicketPrice = ticketPrice;
		}
	}

	function setAsLotteryRunner(address addr, bool canRunLottery) external onlyOwner {
		lotteryRunners[addr] = canRunLottery;
	}

	function runLottery() external whenNotPaused canRunLottery {
		require(gamblers.length >= QUORUM);

		uint winnersCount = calculateWinnersCount(gamblers.length);
		uint winnerPrize = calculateWinnerPrize(prizeFund, winnersCount);

		int[] memory winners = new int[](winnersCount);

		for(uint64 j = 0; j < winnersCount; j++) {
			winners[j] = -1;
		}

		uint lastWinner = 0;
		for(uint i = 0; i < winnersCount; i++) {
			lastWinner = generateNextWinner(lastWinner, winners, gamblers.length);
			winners[i] = int(lastWinner);
			gamblers[uint(winners[i])].transfer(winnerPrize); //safe because gambler can't be a contract
		}

		//set ticket price
		if(nextTicketPrice > 0) {
			ticketPrice = nextTicketPrice;
			nextTicketPrice = 0;
		}

		//set initial state
		prizeFund = 0;
		gamblers.length = 0;
	}

	function calculateWinnerPrize(uint prizeFund, uint winnersCount) returns (uint prize) {
		return prizeFund / winnersCount * 19 / 20;
	}

	function calculateWinnersCount(uint gamblersCount) returns (uint count) {
		if(gamblers.length < 10) {
			return 1;
		} else {
			return gamblers.length / 10;
		}
	}

	/**
	* @dev Function to get ether from contract
	* @param amount Amount in wei to withdraw
	*/
	function withdrawEther(address recipient, uint amount) external onlyOwner {
		recipient.transfer(amount);
	}

	function generateNextWinner(uint previousWinner, int[] winners, uint gamblersCount) private returns(uint) {
		uint nonce = 0;
		uint winner = generateWinner(previousWinner, nonce, gamblersCount);

		while(isInArray(winner, winners)) {
			nonce += 1;
			winner = generateWinner(previousWinner, nonce, gamblersCount);
		}

		return winner;
	}

	function generateWinner(uint previousWinner, uint nonce, uint gamblersCount) private returns (uint winner) {
		return uint(keccak256(uint(block.blockhash(block.number - 1)), previousWinner, nonce)) % gamblersCount;
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