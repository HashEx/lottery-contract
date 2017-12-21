pragma solidity ^0.4.18;
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';

contract DeLottery is Pausable {
	using SafeMath for uint256;

	uint32 public constant QUORUM = 3;

	address[] gamblers;
	uint public gamblersCount;

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
		setAsLotteryRunner(msg.sender, true);
	}

	function () public payable whenNotPaused {
		require(!isContract(msg.sender));
		require(gamblersCount <= 100);

		uint ticketsBought = msg.value / ticketPrice;

		for(uint16 i = 0; i < ticketsBought; i++) {
			gamblers.push(msg.sender);
			gamblersCount++;
		}

		prizeFund = prizeFund.add(ticketsBought * ticketPrice);

		//return change
		uint change = msg.value % ticketPrice;
		if(change > 0) {
			msg.sender.transfer(change);
		}
	}

	function setTicketPrice(uint _ticketPrice) external onlyOwner {
		if(gamblersCount == 0) {
			ticketPrice = _ticketPrice;
			nextTicketPrice = 0;
		} else {
			nextTicketPrice = ticketPrice;
		}
	}

	function setAsLotteryRunner(address addr, bool canRunLottery) public onlyOwner {
		lotteryRunners[addr] = canRunLottery;
	}

	function runLottery() external whenNotPaused canRunLottery {
		require(gamblersCount >= QUORUM);

		uint winnersCount;
		if(gamblersCount < 10) {
			winnersCount = 1;
		} else {
			winnersCount = gamblersCount / 10;
		}
		uint winnerPrize = prizeFund / winnersCount * 19 / 20;

		int[] memory winners = new int[](winnersCount);

		for(uint64 j = 0; j < winnersCount; j++) {
			winners[j] = -1;
		}

		uint lastWinner = generateWinner(0, 0, gamblersCount);
		winners[0] = int(lastWinner);

		for(uint i = 1; i < winnersCount; i++) {
			lastWinner = generateNextWinner(lastWinner, winners, gamblersCount);
			winners[i] = int(lastWinner);
		}

		//set initial state
		prizeFund = 0;
		gamblersCount = 0;

		for(uint k = 0; k < winnersCount; k++) {
			gamblers[uint(winners[k])].transfer(winnerPrize);
		}

		if(nextTicketPrice > 0) {
			ticketPrice = nextTicketPrice;
			nextTicketPrice = 0;
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