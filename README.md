## Getting Started

### Requirements

- [Node.js v16.15.0 or latest stable](https://nodejs.org/en/). We recommend using [nvm](https://github.com/nvm-sh/nvm) to install.
- [PNPM v7.1.7 or latest stable](https://pnpm.io/installation/)
- [Rust toolchain v0.16.0 or latest `stable`](https://www.rust-lang.org/tools/install)
- [Forc v0.28.1](https://fuellabs.github.io/pepa/v0.28.1/introduction/installation.html#installing-from-pre-compiled-binaries)
- [Docker v0.8.2 or latest stable](https://docs.docker.com/get-docker/)
- [Docker Compose v2.6.0 or latest stable](https://docs.docker.com/get-docker/)

### Testing Contracts in Local Machine

First step is to set up and running a local Fuel node.

#### Install dependencies and build contracts

```
pnpm install
pnpm run --filter=pepaswap-scripts build && pnpm install
pnpm exec pepaswap-scripts build
```

#### Run local node

```
make -C docker services-run
```

#### Deploy contracts to local Fuel node with 

`pnpm exec swayswap-scripts deploy`

#### Writing and Running Cargo Tests on contracts

For auto-generation of contracts test we utilize `cargo-generate` package from Fuel repo: https://github.com/FuelLabs/sway-test-rs 

First installing `cargo-generate` with command

`cargo install cargo-generate`

Then change into directory of contract and generate test with (you can supply your own template with different version set):

`cargo generate --init https://github.com/fuellabs/sway-test-rs`

Running test just like you run a regular cargo test

`cargo test`

#### Clean Up Services

`make -C docker services-clean`

