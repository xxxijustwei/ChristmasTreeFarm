<svelte:head>
	<title>ChristmasTreeFarm</title>
	<meta name="description" content="lucky money dapp" />
</svelte:head>

<section>
	<h1 class="title">
		Welcome to ChristmasTreeFarm!
	</h1>
	<h1 class="text-3xl" style="color: #1c1917;">coming soon</h1>
</section>

<style lang="less">
	section {
		display: flex;
		flex-direction: column;
		justify-content: center;
		align-items: center;
		flex: 0.85;
	}

	.title {
		line-height: 1;
		font-size: 3rem;
		font-weight: 300;
		color: #d6d3d1;
		text-align: center;
		width: 35rem;
		margin: 0 auto;
		font-variation-settings: 'wght' 100, 'wdth' 85;
		animation: font-animation 4s infinite forwards cubic-bezier(0.48, 0.04, 0.52, 0.96);

		@media screen and (max-width: 750px) {
			font-size: 2rem;
			width: 100%;
		}
	}

</style>
