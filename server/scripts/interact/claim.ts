import hre from "hardhat";
import { load_contract_address, contract_name } from "../address";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";


async function interact_contract(address: string) {
    let contract = await hre.ethers.getContractAt(contract_name, address)
    let [account1, account2] = await hre.ethers.getSigners();

    console.log("account1 start claim...")
    await claim(contract, account1)
    console.log("account2 start claim...")
    await claim(contract, account2)
}

async function claim(contract: Contract, account: SignerWithAddress) {
    let key = "taylor swift 1989"

    let ok = await contract.canClaim(key)
    if (!ok) {
        console.log(`invalid key: ${key}`)
        return
    }

    let contractWithSigner = contract.connect(account)
    let tx = await contractWithSigner.claimPresent(key)
    let txReceipt = await tx.wait()

    let abi = ["event ClaimedPresentEvent(address indexed sender, string indexed key, uint value)"]
    let iface = new hre.ethers.utils.Interface(abi)
    let log = iface.parseLog(txReceipt.logs[0])
    let value = log.args[2]

    console.log(`address ${account.address} claim: ${hre.ethers.utils.formatEther(value)}`)
}

async function main() {
    let address = load_contract_address()[contract_name]
    await interact_contract(address)
}

main().catch((err) => {
    console.log(err)
    process.exitCode = 1
})