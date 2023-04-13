import { NativeAssetId, Provider, Wallet, WalletUnlocked } from "fuels";
import { log } from "src/log";

require("dotenv").config();

export async function getWalletInstance() {
  // Avoid early load of process env
  const { WALLET_SECRET, GENESIS_SECRET, PROVIDER_URL } = process.env;
  if (WALLET_SECRET) {
    log("WALLET_SECRET detected");
    // return Wallet.fromPrivateKey(WALLET_SECRET, PROVIDER_URL);
    // return new Wallet(WALLET_SECRET, PROVIDER_URL);
    const provider = new Provider(PROVIDER_URL!);
    const wallet: WalletUnlocked = Wallet.fromPrivateKey(
      WALLET_SECRET,
      provider
    );
    return wallet;
  }
  // If no WALLET_SECRET is informed we assume
  // We are on a test environment
  // In this case it must provide a GENESIS_SECRET
  // on this case the origen of balances should be
  // almost limitless assuming the genesis has enough
  // balances configured
  // if (GENESIS_SECRET) {
  //   log('Funding wallet with some coins');
  //   const provider = new Provider(PROVIDER_URL!);
  //   return TestUtils.generateTestWallet(provider, [[100_000_000, NativeAssetId]]);
  // }
  throw new Error("You must provide a WALLET_SECRET");
}
