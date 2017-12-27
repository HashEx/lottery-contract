const DeLottery = artifacts.require('./DeLottery.sol')

import EVMThrow from './helpers/EVMThrow'
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

async function getBalance(account) {
	return await web3.fromWei(web3.eth.getBalance(account));
}

async function printBalances(accounts) {
	console.log('---------------------------------------------')
	for(var i = 0; i < accounts.length; i++) {
		const balance = await getBalance(accounts[i])
		console.log("balance of account " + i + ": " + balance)
	}
	console.log('---------------------------------------------')
}

async function buyTicket(lottery, account, ethers) {
	return await web3.eth.sendTransaction({from: account, to: lottery, 
		gas: 1000000, value: web3.toWei(ethers, 'ether')})
}

async function runLottery(lottery, accounts) {
	await buyTicket(lottery.address, accounts[0], 1)
	await buyTicket(lottery.address, accounts[1], 1)
	await buyTicket(lottery.address, accounts[3], 1)
	await lottery.runLottery()
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
		for(let i = 0; i < 1; i++) {
			await runLottery(this.lottery, accounts)
			printBalances(accounts)
		}
		// assert.equal(1, 2);
	})

	it('should send refund', async function() {
		const initialBalance = await getBalance(this.owner);

		await buyTicket(this.lottery.address, this.owner, 1.5)

		const newBalance = await getBalance(this.owner);
		const diff = initialBalance.valueOf() - newBalance.valueOf();

		assert.equal(Math.abs(1 - diff) < 0.01, true)

		const ticketsBought = await this.lottery.getTicketsCount.call()
		assert.equal(ticketsBought.valueOf(), 1, "should buy 1 ticket")

		const fund = await this.lottery.prizeFund.call()
		assert.equal(web3.fromWei(fund), 1, 'fund should be 1 ether')
	})

	it('should send refund if more than max tickets bought', async function() {
		const initialBalance = await getBalance(this.owner);

		await this.lottery.setMaxTickets(10)

		await this.lottery.setTicketPrice(web3.toWei(0.1, 'ether'))

		await buyTicket(this.lottery.address, this.owner, 2.5)

		const newBalance = await getBalance(this.owner);
		const diff = initialBalance - newBalance;

		assert.equal(Math.abs(1 - diff) < 0.01, true, "should only buy for 1 ether")

		const ticketsBought = await this.lottery.getTicketsCount.call()
		assert.equal(ticketsBought.valueOf(), 10, "should buy all 10 tickets")

		const fund = await this.lottery.prizeFund.call()
		assert.equal(web3.fromWei(fund), 1, 'max fund of 1 ether shuld be set')
	})

	it('should not allow to buy more than max tickets', async function() {
		await this.lottery.setMaxTickets(10)

		await this.lottery.setTicketPrice(web3.toWei(0.1, 'ether'))
		await buyTicket(this.lottery.address, this.owner, 10)

		const ticketsBought = await this.lottery.getTicketsCount.call()
		assert.equal(ticketsBought.valueOf(), 10, "should buy all 10 tickets")

		await buyTicket(this.lottery.address, this.owner, 0.1).should.be.rejected
	})

	it('should set correct prize fund', async function() {
		await this.lottery.setTicketPrice(web3.toWei(0.1, 'ether'))

		await buyTicket(this.lottery.address, this.owner, 1)

		const fund = await this.lottery.prizeFund.call()

		assert.equal(web3.fromWei(fund), 1, 'fund of 1 ether shuld be set')
	})

	it('should increase stage num after lottery run', async function() {
		const initialStage = await this.lottery.stage.call()
		assert.equal(initialStage, 0, 'initial stage should be set to 0')
		await runLottery(this.lottery, accounts)
		const stage = await this.lottery.stage.call()
		assert.equal(stage, 1, 'initial stage should be set to 0')
	})

	it('should set ticket price immediately if no tickets bought in current stage', async function() {
		await this.lottery.setTicketPrice(web3.toWei(0.5, 'ether'));
		const newTicketPrice = await this.lottery.ticketPrice.call()
		assert.equal(newTicketPrice.valueOf(), web3.toWei(0.5, 'ether').valueOf(), 'new ticket price should be set immediately')

		await runLottery(this.lottery, accounts)

		await this.lottery.setTicketPrice(web3.toWei(0.25, 'ether'));

		const ticketPriceForNewLottery = await this.lottery.ticketPrice.call()
		assert.equal(ticketPriceForNewLottery.valueOf(), web3.toWei(0.25, 'ether'), 'new ticket price should be set immediately')
	})

	it('should set ticket price after lottery run if some tickets were already bought', async function() {
		await buyTicket(this.lottery.address, this.owner, 1)

		await this.lottery.setTicketPrice(web3.toWei(0.5, 'ether'));

		const currentTicketPrice = await this.lottery.ticketPrice.call()
		assert.equal(currentTicketPrice.valueOf(), web3.toWei(1, 'ether'), 'ticket price should not be set immediately')

		const nextTicketPrice = await this.lottery.nextTicketPrice.call()
		assert.equal(nextTicketPrice.valueOf(), web3.toWei(0.5, 'ether').valueOf(), 'next ticket price value should be set')

		await runLottery(this.lottery, accounts)
		const newTicketPrice = await this.lottery.ticketPrice.call()
		assert.equal(newTicketPrice.valueOf(), web3.toWei(0.5, 'ether'), 'ticket price should be set after lottery run')
	})

	it('should increment tickets count after buy', async function() {
		let ticketsCount = await this.lottery.getTicketsCount.call()
		assert.equal(ticketsCount.valueOf(), 0, 'tickets count should be equal 0 before any buy')
		await buyTicket(this.lottery.address, this.owner, 1)

		ticketsCount = await this.lottery.getTicketsCount.call()
		assert.equal(ticketsCount.valueOf(), 1, 'tickets count should be equal 1')
	})

	it('should correctly calculate winner prize', async function() {
		const prize = await this.lottery.calculateWinnerPrize.call(1000, 10)
		assert.equal(prize.valueOf(), 95, 'price should be equal ' + 95)
	})

	it('should correctly calculate winners count', async function() {
		let winnersCount = await this.lottery.calculateWinnersCount(5)
		assert.equal(winnersCount.valueOf(), 1, 'should be 1 winner for 5 tickets')
		winnersCount = await this.lottery.calculateWinnersCount(19)
		assert.equal(winnersCount.valueOf(), 1, 'should be 1 winner for 19 tickets')
		winnersCount = await this.lottery.calculateWinnersCount(20)
		assert.equal(winnersCount.valueOf(), 2, 'should be 2 winners for 20 tickets')
	})

})