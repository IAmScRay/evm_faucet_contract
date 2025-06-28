# Faucet contract for EVM-compatible blockchains

This repo contains a simple, yet fully functional and production-ready smart contract written in **Solidity** for creating a faucet service.

## Deployment details
At deployment, there's single constructor argument `_amount` which sets initial distribution amount in Wei for single address. If decided afterwards, this parameter can be changed by calling `setDistributionAmount()` method with new amount.

EOA or multi-sig that deploys the contract becomes its owner, ownership is not transferable.

You can use [Remix IDE](https://remix.ethereum.org), VS Code with Solidity extensions or any other of many ways to compile deploy the contract. I used `eth-brownie` inside of PyCharm IDE with an EOA as a deployer.

## Security
All methods involving parameters changes (pausing / changing distribution amount) and `distribute()` method are protected from unauthorized calls with `onlyOwner` modifier.

Also, contract can be paused for maintenance or other reasons, making `distribute()` uncallable with `notPaused` modifier. Reentrancy attacks are also taken into account: `fallback()` reverts automatically, and since only contract's owner can call most of the methods, unauthorized access is only possible if owner's private key or a whole multi-sig is compromised.

## Logic insights
Contract uses `payable(address).transfer()` method for distribution which is sufficient for sending ETH to EOAs, but if there are contracts' addresses in the `recipients` argument of `distribute()` method, there may not be enough gas if those contracts perform arbitrary functions when ETH is received (`transfer` sends 2300 units of gas only) – that's why it's recommended to check if an address is contract's one or not on the backend of faucet website.

Faucet contract uses its own balance for distribution, and it's checked depending on the length of `recipients` list and `distributionAmount` parameter when calling `distribute()` method. When there's not enough ETH, transaction reverts with a message. If it succeeds, `Distribution` event is emitted for each address in the list.

When needed, remaining balance can be withdrawn using `withdraw()` method which sends all ETH to the owner, emitting `Withdrawal` event. Since an owner can be a multi-sig, `payable(owner).call{value: balance}("");` is used if multi-sig's logic requires more than 2300 units of gas.

## Is this being used anywhere?
Yes! This version is being used for Holesky Faucet here: https://holesky-faucet.iamscray.dev.

Frontend is pretty simple by itself: it sends requests to FastAPI service where addresses are queued, bundled together and sent for distribution in one shot using this smart contract every 2 minutes.
