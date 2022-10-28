<script>
    import {page} from '$app/stores';
    import {ethers} from "ethers";

    let wallet = "Connect Wallet";

    async function connect() {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const accounts = await provider.send("eth_requestAccounts", []);
        let address = accounts[0];
        wallet = address.substring(0, 6) + "...." + address.substring(36, address.length);

        const { chainId } = await provider.getNetwork();
        if (chainId !== 0x507) {
            window.ethereum.request({
                method: "wallet_addEthereumChain",
                params: [{
                    chainId: "0x507",
                    rpcUrls: ["https://rpc.api.moonbase.moonbeam.network"],
                    chainName: "Moonbase Alpha",
                    nativeCurrency: {
                        name: "DEV",
                        symbol: "DEV",
                        decimals: 18
                    },
                    blockExplorerUrls: ["https://moonbase.moonscan.io/"]
                }]
            });
        }
    }
</script>

<header>
    <div style="width: 159px; height: 48px;">
        <img class="m-2 w-10 h-10 rounded-full" src="./src/lib/images/favicon.png" alt="Rounded avatar">
    </div>

    <nav>
        <svg viewBox="0 0 2 3" aria-hidden="true">
            <path d="M0,0 L1,2 C1.5,3 1.5,3 2,3 L2,0 Z" />
        </svg>
        <ul>
            <li class:active={$page.url.pathname === '/create'}>
                <a href="/create">Create</a>
            </li>
            <li class:active={$page.url.pathname.startsWith('/receive')}>
                <a href="/receive">Receive</a>
            </li>
        </ul>
        <svg viewBox="0 0 2 3" aria-hidden="true">
            <path d="M0,0 L0,3 C0.5,3 0.5,3 1,2 L2,0 Z" />
        </svg>
    </nav>

    <button on:click={ connect } class="conn px-3 py-2 m-3 text-xs tracking-wide text-white capitalize transition-colors duration-300 transform bg-blue-600 rounded-md hover:bg-blue-500 focus:outline-none focus:ring focus:ring-blue-300 focus:ring-opacity-80">
        { wallet }
    </button>

</header>

<style>
    header {
        display: flex;
        justify-content: space-between;
    }

    nav {
        display: flex;
        justify-content: center;
        --background: rgba(255, 255, 255, 0.7);
    }

    svg {
        width: 2em;
        height: 3em;
        display: block;
    }

    path {
        fill: var(--background);
    }

    ul {
        position: relative;
        padding: 0;
        margin: 0;
        height: 3em;
        display: flex;
        justify-content: center;
        align-items: center;
        list-style: none;
        background: var(--background);
        background-size: contain;
    }

    li {
        position: relative;
        height: 100%;
    }

    li.active::before {
        --size: 6px;
        content: '';
        width: 0;
        height: 0;
        position: absolute;
        top: 0;
        left: calc(50% - var(--size));
        border: var(--size) solid transparent;
        border-top: var(--size) solid var(--color-theme-1);
    }

    nav a {
        display: flex;
        height: 100%;
        align-items: center;
        padding: 0 0.5rem;
        color: var(--color-text);
        font-weight: 700;
        font-size: 0.8rem;
        text-transform: uppercase;
        letter-spacing: 0.1em;
        text-decoration: none;
        transition: color 0.2s linear;
    }

    a:hover {
        color: var(--color-theme-1);
    }

    .conn {
        width: 146px;
    }
</style>
