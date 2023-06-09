/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import type {
  Interface,
  FunctionFragment,
  DecodedValue,
  Contract,
  BytesLike,
  BigNumberish,
  InvokeFunction,
  BN,
} from "fuels";

import type { Enum, Option } from "./common";

export type OptionalB256Input = Option<string>;

export type OptionalB256Output = Option<string>;

interface FactoryContractAbiInterface extends Interface {
  functions: {
    add_ido: FunctionFragment;
    get_ido_by_admin: FunctionFragment;
    get_ido_by_token: FunctionFragment;
    initilize: FunctionFragment;
    remove_ido: FunctionFragment;
    update_admin: FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "add_ido",
    values: [string, string, string, string]
  ): Uint8Array;
  encodeFunctionData(
    functionFragment: "get_ido_by_admin",
    values: [string]
  ): Uint8Array;
  encodeFunctionData(
    functionFragment: "get_ido_by_token",
    values: [string, string]
  ): Uint8Array;
  encodeFunctionData(
    functionFragment: "initilize",
    values: [string]
  ): Uint8Array;
  encodeFunctionData(
    functionFragment: "remove_ido",
    values: [string, string, string, string]
  ): Uint8Array;
  encodeFunctionData(
    functionFragment: "update_admin",
    values: [string, string]
  ): Uint8Array;

  decodeFunctionData(
    functionFragment: "add_ido",
    data: BytesLike
  ): DecodedValue;
  decodeFunctionData(
    functionFragment: "get_ido_by_admin",
    data: BytesLike
  ): DecodedValue;
  decodeFunctionData(
    functionFragment: "get_ido_by_token",
    data: BytesLike
  ): DecodedValue;
  decodeFunctionData(
    functionFragment: "initilize",
    data: BytesLike
  ): DecodedValue;
  decodeFunctionData(
    functionFragment: "remove_ido",
    data: BytesLike
  ): DecodedValue;
  decodeFunctionData(
    functionFragment: "update_admin",
    data: BytesLike
  ): DecodedValue;
}

export class FactoryContractAbi extends Contract {
  interface: FactoryContractAbiInterface;
  functions: {
    add_ido: InvokeFunction<
      [
        base_token: string,
        quote_token: string,
        id_address: string,
        owner: string
      ],
      void
    >;

    get_ido_by_admin: InvokeFunction<[owner: string], OptionalB256Output>;

    get_ido_by_token: InvokeFunction<
      [base_token: string, quote_token: string],
      OptionalB256Output
    >;

    initilize: InvokeFunction<[template_ido_id: string], void>;

    remove_ido: InvokeFunction<
      [owner: string, base_token: string, quote_token: string, pool: string],
      void
    >;

    update_admin: InvokeFunction<
      [old_owner: string, new_owner: string],
      OptionalB256Output
    >;
  };
}
