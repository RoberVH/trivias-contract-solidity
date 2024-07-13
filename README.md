## TriviasContract
### Contract for Trivia game for the Course Introduccion a Blokcchain

- It controls if Trivia is corrected solved. 
- Acruee result for users
- Grants contract's 10 tokens TTS (Trivia Tokens Game) for each trivia solved


#### **Author:** Roberto Vicuña
####  **Date:** July 2024

 Created on Foundry environment
 Deploy to Sepolia Network

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ source .env
$ forge script script/DeployTriviasContract.s.sol:DeployTriviasContract --rpc-url $ALCHEMY_SEPOLIA_URL --private-key $PRIVATE_KEY --broadcast
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
