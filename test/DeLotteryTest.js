const DeLottery = artifacts.require('./DeLottery.sol')

import EVMThrow from './helpers/EVMThrow'
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

const getBalance = (account) => {
	return web3.fromWei(web3.eth.getBalance(account));
}

const printBalances = (accounts) => {
	console.log('---------------------------------------------')
	for(var i = 0; i < accounts.length; i++) {
		console.log("balance of account " + i + ": " + getBalance(accounts[i]))
	}
	console.log('---------------------------------------------')
}

contract('DeLottery', accounts => {

	beforeEach(async function() {
		this.owner = accounts[0]
		this.lottery = await DeLottery.new()
	})

	it('should buy tickets and return change', async function() {
		// await this.lottery.buyTicket({from: accounts[0], value: web3.toWei(3.999, 'ether')})
		await web3.eth.sendTransaction({from: this.owner, 
			to: this.lottery.address, 
			value: web3.toWei(1, 'ether'),
			gas: 1000000})
		// const count = await this.lottery.gamblersCount.call()
		// assert.equal(count, 3, "3 tickets should be bought");
		// console.log('balanse of account: ' + getBalance(accounts[0]))

	})

	it('should run lottery', async function() {
		await web3.eth.sendTransaction({from: this.owner, 
			to: accounts[1], 
			value: web3.toWei(0.5, 'ether'),
			gas: 1000000})

		await web3.eth.sendTransaction({from: this.owner, to: this.lottery.address, 
			gas: 1000000, value: web3.toWei(1, 'ether')})
		// await web3.eth.sendTransaction({from: this.owner, to: this.lottery.address, value: web3.toWei(1, 'ether')})
		// await web3.eth.sendTransaction({from: this.owner, to: this.lottery.address, value: web3.toWei(1, 'ether')})


		// let prize = await this.lottery.prizeFund.call()
		// console.log('prize fund is: ' + prize.valueOf())

		// await this.lottery.runLottery()
		// printBalances(accounts)

		// console.log('\n\n\n*********************NEXT RUN*********************')
		// await this.lottery.buyTicket({from: accounts[0], value: web3.toWei(2, 'ether')})
		// await this.lottery.buyTicket({from: accounts[2], value: web3.toWei(1, 'ether')})
		// await this.lottery.buyTicket({from: accounts[3], value: web3.toWei(1, 'ether')})
		// await this.lottery.buyTicket({from: accounts[4], value: web3.toWei(1, 'ether')})
		// await this.lottery.buyTicket({from: accounts[5], value: web3.toWei(1, 'ether')})
		// await this.lottery.buyTicket({from: accounts[6], value: web3.toWei(1, 'ether')})
		// await this.lottery.buyTicket({from: accounts[7], value: web3.toWei(1, 'ether')})
		// await this.lottery.buyTicket({from: accounts[8], value: web3.toWei(1, 'ether')})
		// await this.lottery.buyTicket({from: accounts[9], value: web3.toWei(1, 'ether')})

		// prize = await this.lottery.prizeFund.call()
		// console.log('prize fund is: ' + prize.valueOf())

		// await this.lottery.runLottery()
		// printBalances(accounts)

	})

})