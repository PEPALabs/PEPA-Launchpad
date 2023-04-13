import { bn, Wallet } from 'fuels';

import '../../load.envs';
import './loadDockerEnv';
import { SwapContractAbi__factory, TokenContractAbi__factory } from '../../src/types/contracts';

import { initializePool } from './initializePool';
import { initializeTokenContract } from './initializeTokenContract';

const { WALLET_SECRET, PROVIDER_URL, GAS_PRICE, VITE_CONTRACT_ID, VITE_TOKEN_ID } = process.env;

if (!WALLET_SECRET) {
  process.stdout.write('WALLET_SECRET is not detected!\n');
  process.exit(1);
}

if (!VITE_CONTRACT_ID || !VITE_TOKEN_ID) {
  process.stdout.write('CONTRACT_ID or TOKEN_ID is not detected!\n');
  process.exit(1);
}

async function main() {
  const wallet = new Wallet(WALLET_SECRET!, PROVIDER_URL);
  const exchangeContract = SwapContractAbi__factory.connect(VITE_CONTRACT_ID!, wallet);
  const tokenContract = TokenContractAbi__factory.connect(VITE_TOKEN_ID!, wallet);
  const overrides = {
    gasPrice: bn(GAS_PRICE || 0),
  };

  console.log("Initialization start");

  await initializeTokenContract(tokenContract, overrides);
  await initializePool(tokenContract, exchangeContract, overrides);

  console.log("Initialization complete");
}

main();
