import { ethers } from "hardhat"
import { Signer } from "ethers"
import { save_contract_address } from "./address";

let deploy_address: {[key: string]: string} = {}
let contract_inst: {[key: string]: any} = {}
let library_inst: {[key: string]: any} = {}
let contract_name: string = "ChristmasTree"
let libs: string[] = ["Utils"]

async function deploy_library() {
    console.log("start deploy libs...")
    for await (const name of libs) {
        const factory = await ethers.getContractFactory(name)
        let instance = await factory.deploy()
        await instance.deployed()

        deploy_address[name] = instance.address
        library_inst[name] = instance
        console.log(`library ${name} deploy to: ${instance.address}`)
    }
    console.log("libs deploy finished...")
    console.log(" ")
}

async function deploy_contract() {
    let deployer: Signer
    [deployer, ,] = await ethers.getSigners()
    let address = await deployer.getAddress()
    console.log(`Deploy contract by ${address}`)

    const factory = await ethers.getContractFactory(contract_name, {
        libraries: {
            Utils: deploy_address["Utils"]
        }
    })
    let instance = await factory.deploy()
    await instance.deployed()

    deploy_address[contract_name] = instance.address
    contract_inst[contract_name] = instance
    console.log(`contract ${contract_name} deploy to: ${instance.address}`)
    console.log(" ")
}

async function main() {
    await deploy_library()
    await deploy_contract()
    save_contract_address(deploy_address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
