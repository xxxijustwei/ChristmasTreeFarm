import { ethers } from "hardhat";
import { contract_name, load_contract_address } from "./utils";
import * as Contracts from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

let utils = ethers.utils;
let contract: Contracts.ChristmasStocking;
let key: number = 19891213;
let num: number = 1;

async function create() {
    let tx = await contract.create(
        key,
        2,
        2000,
        {
            value: utils.parseEther("1.000200000000002")
        }
    );

    let receipt = await tx.wait();
    let abi = ["event PresentsCreateEvent(bytes32 indexed ident, uint indexed key, uint indexed num)"];
    let iface = new utils.Interface(abi);
    let args = iface.parseLog(receipt.logs[0]).args;

    console.log(`> Create presents:`)
    console.log(`    key: ${args[0]}`);
    console.log(`    num: ${args[1]}`);
    console.log("");
}

async function fulfillRequest() {
    let ident = getIdent();

    let status = await contract.getRequestStatus(ident);
    if (status.toNumber() != 2) return;

    let tx = await contract.fulfillRequest(ident);
    let receipt = await tx.wait();

    if (receipt.logs[0].topics[0] == "0xf36cbf89dc2c3c5012cc948a9dfeb18671dc41e53febe215cfabc99113e755ed") {
        console.log("> fulfillRequest success");
    } else {
        console.log("> fulfillRequest failure");
    }
}

async function participate() {
    let [account1, account2] = await ethers.getSigners();
    let internal = async(account: SignerWithAddress) => {
        let instance = contract.connect(account);
        let tx = await instance.participate(getIdent());
        let receipt = await tx.wait()
        let abi = ["event PresentsParticipateEvent(bytes32 indexed ident, uint reward)"];
        let iface = new utils.Interface(abi);
        let args = iface.parseLog(receipt.logs[0]).args;

        console.log(` - Account ${account.address} reward: ${utils.formatEther(args[0])}`);
    }

    await Promise.all([internal(account1), internal(account2)]);
    console.log("");
}

async function drawback() {
    let tx = await contract.drawback(getIdent());
    await tx.wait();
    console.log("> drawback successful!")
}

function getIdent() {
    return utils.solidityKeccak256(["uint256", "bytes32", "uint256"], [key, utils.formatBytes32String("taylor swift"), num]);
}

async function main() {
    let address = load_contract_address()[contract_name];
    contract = await ethers.getContractAt(contract_name, address);

    let waiting = (delay: number) => new Promise((resolve) => setTimeout(resolve, delay));

    await create();
    await waiting(60000);
    await fulfillRequest();
    await participate();
    await drawback();
}

main().catch((error) => {
    console.log(error)
    process.exitCode = 1
})