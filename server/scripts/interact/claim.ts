import hre from "hardhat";
import {load_contract_address} from "../address";
import {Contract} from "ethers";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";

let contract_name: string = "ChristmasTree"

async function interact_contract(address: string) {
    let contract = await hre.ethers.getContractAt(contract_name, address)
    let [account1, account2] = await hre.ethers.getSigners();

    console.log("account1 start claim...")
    await claim(contract, account1)
    console.log("account2 start claim...")
    await claim(contract, account2)
}

async function claim(contract: Contract, account: SignerWithAddress) {
    let key = "taylor"

    let [,,,,balance,,] = await contract.getPresentInfo(key)
    if (Number(balance) == 0) {
        console.log(`invalid key: ${key}`)
        return
    }

    let contractWithSigner = contract.connect(account)
    let tx = await contractWithSigner.claimPresent(key)
    let receipt = await tx.wait()

    console.log(receipt)
}

async function main() {
    let address = load_contract_address()[contract_name]
    await interact_contract(address)
}

main().catch((err) => {
    console.log(err)
    process.exitCode = 1
})