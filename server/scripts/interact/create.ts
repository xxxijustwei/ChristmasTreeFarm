import hre from "hardhat";
import { load_contract_address, contract_name } from "../address";


async function interact_contract(address: string) {
    const contract = await hre.ethers.getContractAt(contract_name, address)
    let overrides = {
        value: hre.ethers.utils.parseEther("0.01")
    }
    let tx = await contract.createPresent(
            "taylor swift 1989",
            2,
            hre.ethers.utils.parseEther("0.01"),
            false,
            overrides
        )
    await tx.wait()
    const sent = await contract.getSentPresents()
    console.log(`sent presents: ${sent}`)
}

async function main() {
    let address = load_contract_address()[contract_name]
    await interact_contract(address)
}

main().catch((error) => {
    console.log(error)
    process.exitCode = 1
})