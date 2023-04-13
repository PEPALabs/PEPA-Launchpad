import { BytesLike, StorageSlot, CreateTransactionRequestLike } from 'fuels';

type DeployContractOptions = {
    salt?: BytesLike;
    storageSlots?: StorageSlot[];
    stateRoot?: BytesLike;
} & CreateTransactionRequestLike;
declare enum Commands {
    "build" = "build",
    "deploy" = "deploy",
    "types" = "types",
    "run" = "run"
}
type BuildDeploy = {
    name: string;
    contractId: string;
};
type Event = {
    type: Commands.build;
    data: unknown;
} | {
    type: Commands.deploy;
    data: Array<BuildDeploy>;
} | {
    type: Commands.run;
    data: Array<BuildDeploy>;
};
type OptionsFunction = (contracts: Array<ContractDeployed>) => DeployContractOptions;
type ContractConfig = {
    name: string;
    path: string;
    options?: DeployContractOptions | OptionsFunction;
};
type ContractDeployed = {
    name: string;
    contractId: string;
};
type Config = {
    onSuccess?: (event: Event) => void;
    onFailure?: (err: unknown) => void;
    env?: {
        [key: string]: string;
    };
    types: {
        artifacts: string;
        output: string;
    };
    contracts: Array<ContractConfig>;
};

declare function createConfig(config: Config): Config;

/**
 * Use event output data to replace
 * on the provide path env the new
 * contract ids.
 *
 * It uses the name inform on the config.contracts.name
 * as a key to the new value. If it didn't found the key
 * on the provide path nothing happens
 */
declare function replaceEventOnEnv(path: string, event: Event): Promise<void>;

export { BuildDeploy, Commands, Config, ContractConfig, ContractDeployed, DeployContractOptions, Event, OptionsFunction, createConfig, replaceEventOnEnv };
