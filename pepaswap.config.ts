import dotenv from 'dotenv';
import { createConfig, replaceEventOnEnv } from 'swayswap-scripts';

const { NODE_ENV, OUTPUT_ENV } = process.env;

function getEnvName() {
  return NODE_ENV === 'test' ? '.env.test' : '.env';
}

dotenv.config({
  path: `./${getEnvName()}`,
});

const getDeployOptions = () => ({
  gasPrice: Number(process.env.GAS_PRICE || 0),
});

// building types and contracts
export default createConfig({
  types: {
    artifacts: './contracts/**/out/debug/**-abi.json',
    output: './packages/init-script/src/types/contracts',
  },
  contracts: [
    {
      name: 'VITE_FACTORY_ID',
      path: './contracts/factory_contract',
      options: getDeployOptions(),
    },
    {
      name: 'VITE_IDO_ID',
      path: './contracts/ido_contract',
      options: getDeployOptions(),
    },
    {
      name: 'VITE_VENDING_ID',
      path: './contracts/vending_machine_contract',
      options: getDeployOptions(),
    },
  ],
  onSuccess: (event) => {
    replaceEventOnEnv(`./packages/init-script/${OUTPUT_ENV || getEnvName()}`, event);
  },
});
