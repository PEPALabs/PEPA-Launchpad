import type { BigNumberish } from 'fuels';
import { bn, NativeAssetId } from 'fuels';

import type { SwapContractAbi } from '../../src/types/contracts';
import type { TokenContractAbi } from '../../src/types/contracts';

const { TOKEN_AMOUNT, ETH_AMOUNT } = process.env;
export async function initializePool(
  tokenContract: TokenContractAbi,
  exchangeContract: SwapContractAbi,
  overrides: { gasPrice: BigNumberish }
) {
  const wallet = tokenContract.wallet!;
  const tokenAmountMint = bn(TOKEN_AMOUNT || '0x44360000');
  const tokenAmount = bn(TOKEN_AMOUNT || '0x40000');
  const ethAmount = bn(ETH_AMOUNT || '0xAAAA00');
  const address = {
    value: wallet.address.toB256(),
  };
  // clean up after initialization to avoid unassigned id
  const tokenId = {
    value: tokenContract.id.toB256(),
  };
  const NativeAsset = {
    value: NativeAssetId,
  }
  process.stdout.write('Mint tokens\n');
  await tokenContract.functions.mint_coins(tokenAmountMint).txParams(overrides).call();
  await tokenContract.functions
    .transfer_token_to_output(tokenAmountMint, tokenId, address)
    .txParams({
      ...overrides,
      variableOutputs: 1,
    })
    .call();

  process.stdout.write('Initialize pool\n');
  const deadline = await wallet.provider.getBlockNumber();
  await exchangeContract
    .multiCall([
      // use custom struct support wrapping parameters
      exchangeContract.functions.initialize(NativeAsset,tokenId),
      exchangeContract.functions.deposit().callParams({
        forward: [ethAmount, NativeAssetId],
      }),
      exchangeContract.functions.deposit().callParams({
        forward: [tokenAmount, tokenContract.id.toB256()],
      }),
      exchangeContract.functions.add_liquidity().callParams({
        forward: [tokenAmount, tokenContract.id.toB256()],
      }),
    ])
    .txParams({
      ...overrides,
      variableOutputs: 2,
      gasLimit: 100_000_000,
    })
    .call();
}
