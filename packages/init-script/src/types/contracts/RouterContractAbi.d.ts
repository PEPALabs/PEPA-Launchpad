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

export type AddressInput = { value: string };

export type AddressOutput = { value: string };

export type ContractIdInput = { value: string };

export type ContractIdOutput = { value: string };

export type SwapResultInput = {
  amount_0_out: BigNumberish;
  amount_1_out: BigNumberish;
};

export type SwapResultOutput = { amount_0_out: BN; amount_1_out: BN };

export type RawVecInput = { ptr: any; cap: BigNumberish };

export type RawVecOutput = { ptr: any; cap: BN };

export type VecInput = { buf: RawVecInput; len: BigNumberish };

export type VecOutput = { buf: RawVecOutput; len: BN };

export type IdentityInput = Enum<{
  Address: AddressInput;
  ContractId: ContractIdInput;
}>;

export type IdentityOutput = Enum<{
  Address: AddressOutput;
  ContractId: ContractIdOutput;
}>;

interface RouterContractAbiInterface extends Interface {
  functions: {
    initialize: FunctionFragment;
    add_liquidity: FunctionFragment;
    remove_liquidity: FunctionFragment;
    swap_exact_input_for_output: FunctionFragment;
    swap_input_for_exact_output: FunctionFragment;
    swap_exact_input_for_output_multihop: FunctionFragment;
    swap_input_for_exact_output_multihop: FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "initialize",
    values: [string]
  ): Uint8Array;
  encodeFunctionData(
    functionFragment: "add_liquidity",
    values: [string, BigNumberish, BigNumberish, BigNumberish, BigNumberish]
  ): Uint8Array;
  encodeFunctionData(
    functionFragment: "remove_liquidity",
    values: [
      string,
      string,
      string,
      BigNumberish,
      BigNumberish,
      BigNumberish,
      BigNumberish
    ]
  ): Uint8Array;
  encodeFunctionData(
    functionFragment: "swap_exact_input_for_output",
    values: [string, BigNumberish, BigNumberish, BigNumberish, IdentityInput]
  ): Uint8Array;
  encodeFunctionData(
    functionFragment: "swap_input_for_exact_output",
    values: [
      string,
      BigNumberish,
      BigNumberish,
      BigNumberish,
      BigNumberish,
      IdentityInput
    ]
  ): Uint8Array;
  encodeFunctionData(
    functionFragment: "swap_exact_input_for_output_multihop",
    values: [string, VecInput, BigNumberish, BigNumberish, IdentityInput]
  ): Uint8Array;
  encodeFunctionData(
    functionFragment: "swap_input_for_exact_output_multihop",
    values: [string, VecInput, BigNumberish, BigNumberish, IdentityInput]
  ): Uint8Array;

  decodeFunctionData(
    functionFragment: "initialize",
    data: BytesLike
  ): DecodedValue;
  decodeFunctionData(
    functionFragment: "add_liquidity",
    data: BytesLike
  ): DecodedValue;
  decodeFunctionData(
    functionFragment: "remove_liquidity",
    data: BytesLike
  ): DecodedValue;
  decodeFunctionData(
    functionFragment: "swap_exact_input_for_output",
    data: BytesLike
  ): DecodedValue;
  decodeFunctionData(
    functionFragment: "swap_input_for_exact_output",
    data: BytesLike
  ): DecodedValue;
  decodeFunctionData(
    functionFragment: "swap_exact_input_for_output_multihop",
    data: BytesLike
  ): DecodedValue;
  decodeFunctionData(
    functionFragment: "swap_input_for_exact_output_multihop",
    data: BytesLike
  ): DecodedValue;
}

export class RouterContractAbi extends Contract {
  interface: RouterContractAbiInterface;
  functions: {
    initialize: InvokeFunction<[factory: string], void>;

    add_liquidity: InvokeFunction<
      [
        swap_address: string,
        amount_0: BigNumberish,
        amount_1: BigNumberish,
        amount_0_min: BigNumberish,
        amount_1_min: BigNumberish
      ],
      [BN, BN]
    >;

    remove_liquidity: InvokeFunction<
      [
        swap_address: string,
        token_0_address: string,
        token_1_address: string,
        amount_0: BigNumberish,
        amount_1: BigNumberish,
        amount_0_min: BigNumberish,
        amount_1_min: BigNumberish
      ],
      [BN, BN]
    >;

    swap_exact_input_for_output: InvokeFunction<
      [
        swap_address: string,
        asset_0_amount: BigNumberish,
        asset_1_amount: BigNumberish,
        amount_out_min: BigNumberish,
        to: IdentityInput
      ],
      SwapResultOutput
    >;

    swap_input_for_exact_output: InvokeFunction<
      [
        swap_address: string,
        asset_0_amount: BigNumberish,
        asset_1_amount: BigNumberish,
        amount_in_max: BigNumberish,
        amount_out: BigNumberish,
        to: IdentityInput
      ],
      SwapResultOutput
    >;

    swap_exact_input_for_output_multihop: InvokeFunction<
      [
        swap_factory: string,
        path: VecInput,
        amount_in: BigNumberish,
        amount_out_min: BigNumberish,
        to: IdentityInput
      ],
      SwapResultOutput
    >;

    swap_input_for_exact_output_multihop: InvokeFunction<
      [
        swap_factory: string,
        path: VecInput,
        amount_out: BigNumberish,
        amount_in_max: BigNumberish,
        to: IdentityInput
      ],
      SwapResultOutput
    >;
  };
}
