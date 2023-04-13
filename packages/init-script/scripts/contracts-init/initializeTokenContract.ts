import type { BigNumberish } from 'fuels';
import { bn } from 'fuels';

import type { TokenContractAbi } from '../../src/types/contracts';

const { MINT_AMOUNT } = process.env;

export async function initializeTokenContract(
  tokenContract: TokenContractAbi,
  overrides: any
) {
  const mintAmount = bn(MINT_AMOUNT || '0x1D1A94A2000');
  console.log(tokenContract.wallet!.address.toB256());
  const address = {
    value: tokenContract.wallet!.address.toB256(),
  };

  process.stdout.write('Initialize Token Contract\n');
  await tokenContract.functions.initialize(mintAmount, address).txParams(overrides).call();
  process.stdout.write('Token Contract successfully initialized\n');
  
}
