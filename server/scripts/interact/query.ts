import hre from "hardhat";
import { load_contract_address, contract_name } from "../address";


async function interact_contract(address: string) {
    const [account,] = await hre.ethers.getSigners()
    const contract = await hre.ethers.getContractAt(contract_name, address)
    const instance = await contract.connect(account)

    const accumSend = await instance.getAccumSend()
    const accumClaim = await instance.getAccumClaim()
    console.log(`accumulate send: ${hre.ethers.utils.formatEther(accumSend)}`)
    console.log(`accumulate claim: ${hre.ethers.utils.formatEther(accumClaim)}`)

    const sent = await instance.getSentPresents()
    console.log(`presents: ${sent}`)
    console.log(" ")
    for (const key of sent) {
        const [creator, initAmount, initBalance, currentAmount, currentBalance, cBalance, average] = await contract.getPresentInfo(key)
        console.log(`present: ${key}`)
        console.log(`   creator: ${creator}`)
        console.log(`   initAmount: ${initAmount}`)
        console.log(`   initBalance: ${hre.ethers.utils.formatEther(initBalance)}`)
        console.log(`   currentAmount: ${currentAmount}`)
        console.log(`   currentBalance: ${hre.ethers.utils.formatEther(currentBalance)}`)
        console.log(`   cBalance: ${hre.ethers.utils.formatEther(cBalance)}`)
        console.log(`   average: ${average}`)
    }
}

async function main() {
    let address = load_contract_address()[contract_name]
    await interact_contract(address)
}

main().catch((error) => {
    console.log(error)
    process.exitCode = 1
})