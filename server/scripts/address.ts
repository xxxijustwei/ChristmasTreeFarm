import fs from "fs";

export let contract_name = "ChristmasTree"

export function load_contract_address() {
    let deploy_address: {[key: string]: string} = {}

    let data = fs.readFileSync("../client/src/common/deploy_address.json", "utf-8")
    let obj = JSON.parse(data)
    for (let key in obj) {
        deploy_address[key] = obj[key]
    }

    return deploy_address
}

export function save_contract_address(deploy_address: {[key: string]: string}) {
    fs.writeFile(
        "../client/src/common/deploy_address.json",
        JSON.stringify(deploy_address),
        (err) => {
            if (err) console.log("deploy contract address write failed!", err)
            else console.log("deploy contract address write successful!")
        })
}