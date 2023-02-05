const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const {anyValue} = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const {expect} = require("chai");

function toWei(v) {
    return ethers.utils.parseUnits(v, 'ether').toString();
}

function fromWei(v) {
    return ethers.utils.formatUnits(v, 'ether').toString();
}

describe("Main", function () {
    async function deploy() {
        const balance = 100e18.toString();
        const fee = '1000'; // 10%
        const [DEV, USER, FEE_USER] = await ethers.getSigners();
        const Main = await ethers.getContractFactory("Main");
        const MockERC20 = await ethers.getContractFactory("MockERC20");
        const token = await MockERC20.deploy(balance);
        const main = await Main.deploy(token.address, fee);
        await main.changeFeeAddress(FEE_USER.address);
        return {token, main, DEV, USER, FEE_USER, fee, balance};
    }

    describe("Deployment", function () {
        it("variables should match", async function () {
            const {token, main, fee, DEV, FEE_USER, balance} = await loadFixture(deploy);
            expect(await main.token()).to.equal(token.address);
            expect(await main.depositFee()).to.equal(fee);
            expect(await token.balanceOf(DEV.address)).to.equal(balance);
            expect(await main.feeAddress()).to.equal(FEE_USER.address);
        });
    });

    describe("One Deposit & Withdraw", function () {
        it("do deposit and check variables", async function () {
            const {token, main, DEV, FEE_USER, balance} = await loadFixture(deploy);
            await token.approve(main.address, balance);
            await main.deposit(balance);
            const depositMinusFee = 90e18.toString();
            const receivedFee = 10e18.toString();
            expect(await main.balance()).to.equal(depositMinusFee);
            const depositInfo = await main.deposits(DEV.address);
            expect(depositInfo.user).to.equal(DEV.address);
            expect(depositInfo.shares).to.equal(depositMinusFee);
            expect(depositInfo.deposited).to.equal(depositMinusFee);
            expect(await token.balanceOf(FEE_USER.address)).to.equal(receivedFee);
        });
        it("do withdraw and check variables", async function () {
            const {token, main, DEV, balance} = await loadFixture(deploy);
            await token.approve(main.address, balance);
            await main.deposit(balance);
            let depositInfo = await main.deposits(DEV.address);
            const shares = depositInfo.shares;
            await main.withdraw(shares);
            depositInfo = await main.deposits(DEV.address);
            expect(depositInfo.shares).to.equal('0');
            expect(depositInfo.deposited).to.equal('0');
            expect(await main.balance()).to.equal('0');
            expect(await main.totalSupply()).to.equal('0');
            expect(await token.balanceOf(main.address)).to.equal('0');
        });
    });

    describe("Multiple Deposit & Withdraw", function () {
        it("do deposit and check variables", async function () {
            const {token, main, DEV, USER, FEE_USER, balance} = await loadFixture(deploy);

            await token.mint(USER.address, balance);

            await token.approve(main.address, balance);
            await token.connect(USER).approve(main.address, balance);

            await main.deposit(balance);
            await main.connect(USER).deposit(balance);

            const depositMinusFee = 90e18.toString();
            const depositsMinusFee = 180e18.toString();
            const receivedFee = 20e18.toString();

            expect(await main.balance()).to.equal(depositsMinusFee);
            expect(await token.balanceOf(FEE_USER.address)).to.equal(receivedFee);

            const depositInfo1 = await main.deposits(DEV.address);
            expect(depositInfo1.user).to.equal(DEV.address);
            expect(depositInfo1.shares).to.equal(depositMinusFee);
            expect(depositInfo1.deposited).to.equal(depositMinusFee);

            const depositInfo2 = await main.deposits(USER.address);
            expect(depositInfo2.user).to.equal(USER.address);
            expect(depositInfo2.shares).to.equal(depositMinusFee);
            expect(depositInfo2.deposited).to.equal(depositMinusFee);



        });
        it("do withdraw and check variables", async function () {
            const {token, main, DEV, USER, balance} = await loadFixture(deploy);
            await token.mint(USER.address, balance);
            await token.approve(main.address, balance);
            await token.connect(USER).approve(main.address, balance);

            await main.deposit(balance);
            await main.connect(USER).deposit(balance);

            let depositInfo1 = await main.deposits(DEV.address);
            let depositInfo2 = await main.deposits(USER.address);

            await main.withdraw(depositInfo1.shares);
            await main.connect(USER).withdraw(depositInfo2.shares);

            depositInfo1 = await main.deposits(DEV.address);
            expect(depositInfo1.shares).to.equal('0');
            expect(depositInfo1.deposited).to.equal('0');

            depositInfo2 = await main.deposits(USER.address);
            expect(depositInfo2.shares).to.equal('0');
            expect(depositInfo2.deposited).to.equal('0');

            expect(await main.balance()).to.equal('0');
            expect(await main.totalSupply()).to.equal('0');
            expect(await token.balanceOf(main.address)).to.equal('0');
        });
    });

});
