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

const buyTicket = (lottery, account, ethers) => {
	return web3.eth.sendTransaction({from: account, to: lottery, 
		gas: 1000000, value: web3.toWei(ethers, 'ether')})
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
	})

	it('should run lottery', async function() {
		await buyTicket(this.lottery.address, accounts[0], 1)
		await buyTicket(this.lottery.address, accounts[1], 1)
		await buyTicket(this.lottery.address, accounts[2], 1)
		await buyTicket(this.lottery.address, accounts[3], 1)

		let prize = await this.lottery.prizeFund.call()
		console.log('prize fund is: ' + prize.valueOf())

		await this.lottery.runLottery()
		printBalances(accounts)

		console.log('\n\n\n*********************NEXT RUN*********************')
		await buyTicket(this.lottery.address, accounts[9], 1)
		await buyTicket(this.lottery.address, accounts[8], 1)
		await buyTicket(this.lottery.address, accounts[7], 1)
		await buyTicket(this.lottery.address, accounts[6], 1)

		prize = await this.lottery.prizeFund.call()
		console.log('prize fund is: ' + prize.valueOf())

		await this.lottery.runLottery()
		printBalances(accounts)

	})

})