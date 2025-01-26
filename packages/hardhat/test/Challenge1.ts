//
// This script executes when you run 'yarn test'
//
import { ethers, network } from "hardhat";
import { expect } from "chai";
import { ExampleExternalContract, Staker } from "../typechain-types";

describe("🚩 Challenge 1: 🔏 Decentralized Staking App", function () {
  let exampleExternalContract: ExampleExternalContract;
  let stakerContract: Staker;

  describe("Staker", function () {
    const contractAddress = process.env.CONTRACT_ADDRESS;

    let contractArtifact: string;
    if (contractAddress) {
      // For the autograder.
      contractArtifact = `contracts/download-${contractAddress}.sol:Staker`;
    } else {
      contractArtifact = "contracts/Staker.sol:Staker";
    }

    it("Should deploy ExampleExternalContract", async function () {
      const ExampleExternalContract = await ethers.getContractFactory("ExampleExternalContract");
      exampleExternalContract = await ExampleExternalContract.deploy();
    });
    it("Should deploy Staker", async function () {
      const Staker = await ethers.getContractFactory(contractArtifact);
      stakerContract = (await Staker.deploy(await exampleExternalContract.getAddress())) as Staker;
      console.log("\t", "🛰  Staker contract deployed on", await stakerContract.getAddress());
    });
    describe("stake()", function () {
      it("Balance should go up when you stake()", async function () {
        const [owner] = await ethers.getSigners();

        console.log("\t", " 🧑‍🏫 Tester Address: ", owner.address);

        const startingBalance = await stakerContract.balances(owner.address);
        console.log("\t", " ⚖️ Starting balance: ", Number(startingBalance));

        console.log("\t", " 🔨 Staking...");
        const stakeResult = await stakerContract.stake({ value: ethers.parseEther("0.001") });
        console.log("\t", " 🏷  stakeResult: ", stakeResult.hash);

        console.log("\t", " ⏳ Waiting for confirmation...");
        const txResult = await stakeResult.wait();
        expect(txResult?.status).to.equal(1);

        const newBalance = await stakerContract.balances(owner.address);
        console.log("\t", " 🔎 New balance: ", ethers.formatEther(newBalance));
        expect(newBalance).to.equal(startingBalance + ethers.parseEther("0.001"));
      });

      if (process.env.CONTRACT_ADDRESS) {
        console.log(
          " 🤷 since we will run this test on a live contract this is as far as the automated tests will go...",
        );
      } else {
        it("If enough is staked and time has passed, you should be able to complete", async function () {
          const timeLeft1 = await stakerContract.timeLeft();
          console.log("\t", "⏱ There should be some time left: ", Number(timeLeft1));
          expect(Number(timeLeft1)).to.greaterThan(0);

          console.log("\t", " 🚀 Staking a full eth!");
          const stakeResult = await stakerContract.stake({ value: ethers.parseEther("1") });
          console.log("\t", " 🏷  stakeResult: ", stakeResult.hash);

          console.log("\t", " ⌛️ fast forward time...");
          await network.provider.send("evm_increaseTime", [72 * 3600]);
          await network.provider.send("evm_mine");

          const timeLeft2 = await stakerContract.timeLeft();
          console.log("\t", "⏱ Time should be up now: ", Number(timeLeft2));
          expect(Number(timeLeft2)).to.equal(0);

          console.log("\t", " 🎉 calling execute");
          const execResult = await stakerContract.execute();
          console.log("\t", " 🏷  execResult: ", execResult.hash);

          const result = await exampleExternalContract.completed();
          console.log("\t", " 🥁 complete: ", result);
          expect(result).to.equal(true);
        });
        it("Should redeploy Staker, stake, not get enough, and withdraw", async function () {
  const [owner, secondAccount] = await ethers.getSigners();

  const ExampleExternalContract = await ethers.getContractFactory("ExampleExternalContract");
  exampleExternalContract = await ExampleExternalContract.deploy();
  const exampleExternalContractAddress = await exampleExternalContract.getAddress();

  const Staker = await ethers.getContractFactory("Staker");
  stakerContract = await Staker.deploy(exampleExternalContractAddress);

  console.log("\t", " 🔨 Staking...");
  const initialBalance = await ethers.provider.getBalance(secondAccount.address);

  const stakeTx = await stakerContract.connect(secondAccount).stake({
    value: ethers.parseEther("0.001"),
  });
  console.log("\t", " 🏷  stakeResult: ", stakeTx.hash);

  console.log("\t", " ⏳ Waiting for confirmation...");
  const stakeReceipt = await stakeTx.wait();

  // Fix: Ensure gasCost calculation uses BigNumber correctly
  // Use gasUsed and gasPrice directly (no need for BigNumber.from)
  const gasUsed = stakeReceipt.gasUsed; // Already a BigNumber
  const gasPrice = stakeTx.gasPrice; // Should also be a BigNumber
  //const stakeGasCost = gasUsed.mul(gasPrice);

  const balanceAfterStake = await ethers.provider.getBalance(secondAccount.address);
  const expectedBalanceAfterStake = initialBalance.sub(ethers.parseEther("0.001")).sub(stakeGasCost);

  console.log("\t", " 🔍 Validating balance after staking...");
  expect(balanceAfterStake).to.equal(expectedBalanceAfterStake);

  console.log("\t", " ⌛️ fast forward time...");
  await network.provider.send("evm_increaseTime", [72 * 3600]);
  await network.provider.send("evm_mine");

  console.log("\t", " 🎉 calling execute");
  const execResult = await stakerContract.execute();
  console.log("\t", " 🏷  execResult: ", execResult.hash);

  const result = await exampleExternalContract.completed();
  console.log("\t", " 🥁 complete should be false: ", result);
  expect(result).to.equal(false);

  const startingBalance = await ethers.provider.getBalance(secondAccount.address);
  console.log("\t", " 💵 calling withdraw");
  const withdrawTx = await stakerContract.connect(secondAccount).withdraw();
  console.log("\t", " 🏷  withdrawResult: ", withdrawTx.hash);

  const withdrawReceipt = await withdrawTx.wait();

  // Fix: Ensure withdraw gas cost uses BigNumber operations
  const withdrawGasUsed = ethers.BigNumber.from(withdrawReceipt.gasUsed);
  const withdrawGasPrice = ethers.BigNumber.from(withdrawTx.gasPrice);
  const withdrawGasCost = withdrawGasUsed.mul(withdrawGasPrice);

  const endingBalance = await ethers.provider.getBalance(secondAccount.address);
  const expectedEndingBalance = startingBalance.add(ethers.parseEther("0.001")).sub(withdrawGasCost);

  console.log("\t", " 🔍 Validating balance after withdrawing...");
  expect(endingBalance).to.equal(expectedEndingBalance);
});


       }
    });
  });
});
