import { ethers } from "hardhat"
import { save_contract_address, contract_name } from "./utils";


let deploy_address: {[key: string]: string} = {}
let contract_inst: {[key: string]: any} = {}

async function deploy() {
    let [owner,] = await ethers.getSigners()
    let address = await owner.getAddress()
    console.log(`Deploy contract by ${address}`)

    const factory = await ethers.getContractFactory(contract_name)
    let instance = await factory.deploy()
    await instance.deployed()

    deploy_address[contract_name] = instance.address
    contract_inst[contract_name] = instance
    console.log(`Contract ${contract_name} deploy to: ${instance.address}`)
    console.log(" ")
}

async function main() {
    await deploy()
    save_contract_address(deploy_address)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
