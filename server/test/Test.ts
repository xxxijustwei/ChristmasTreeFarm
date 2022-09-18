import hre from "hardhat";

describe("Test", function () {
    it('deploy contents and test', async function () {
        const factory = await hre.ethers.getContractFactory("ChristmasTree");
        const contract = await factory.deploy();
        console.log(`deploy address: ${contract.address}`);
    });
});
