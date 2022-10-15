import fs from "fs";

export const contract_name = "ChristmasStocking";
const path = "./cache/deploy_address.json";

export function load_contract_address() {
    let deploy_address: {[key: string]: string} = {};

    try {
        let data = fs.readFileSync(path, "utf-8");
        let obj = JSON.parse(data);
        for (let key in obj) {
            deploy_address[key] = obj[key];
        }
    } catch (err) {}

    return deploy_address
}

export function save_contract_address(deploy_address: {[key: string]: string}) {
    fs.writeFile(
        path,
        JSON.stringify(deploy_address),
        (err) => {
            if (err) console.log("deploy contract address write failed!", err)
        })
}