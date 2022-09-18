import { ethers } from "hardhat";
import { Signer } from "ethers";
import * as fs from "fs";

let deploy_address: {[index: string]: string} = {};
let contract_inst: {[key: string]: any} = {};
let contracts: {[key: string]: any[]} = {
  "ChristmasTree": []
}

async function deploy_contract() {
  let deployer: Signer;
  [deployer, ,] = await ethers.getSigners();
  let address = await deployer.getAddress();
  console.log(`Deploy contract by ${address}`);

  let contract_names = [];
  for (let key in contracts) {
    contract_names.push(key);
  }

  for await (const key of contract_names) {
    const factory = await ethers.getContractFactory(key);
    let instance = await factory.deploy(...contracts[key]);
    deploy_address[key] = instance.address;
    contract_inst[key] = instance;
    console.log(`contract ${key} deploy to: ${instance.address}`);
  }
}

async function main() {
  await deploy_contract();

  fs.writeFile(
      "../client/src/common/deploy_address.json",
      JSON.stringify(deploy_address),
      (err) => {
        if (err) console.log("deploy contract address write failed!", err);
        else console.log("deploy contract address write successful!")
      });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
