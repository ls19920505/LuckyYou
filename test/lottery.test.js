const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('Lottery3D', function () {
  it('should revert buying ticket after draw', async function () {
    const Lottery3D = await ethers.getContractFactory('Lottery3D');
    const lottery = await Lottery3D.deploy();
    if (lottery.waitForDeployment) {
      await lottery.waitForDeployment();
    } else {
      await lottery.deployed();
    }

    await lottery.openRound(1, 1);
    const [, user] = await ethers.getSigners();
    const ticketPrice = await lottery.ticketPrice();
    await lottery.connect(user).buyTicket(1, 123, 1, { value: ticketPrice });

    await ethers.provider.send('evm_increaseTime', [2]);
    await ethers.provider.send('evm_mine');

    await lottery.draw(1, 123);

    await expect(
      lottery.connect(user).buyTicket(1, 123, 1, { value: ticketPrice })
    ).to.be.revertedWith('Round closed');
  });
});
