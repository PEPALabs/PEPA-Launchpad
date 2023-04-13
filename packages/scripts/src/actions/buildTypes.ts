// import {ProgramTypeEnum, runTypegen} from 'fuels';
const { glob } = require("glob");
import type { Config } from "src/types";
import { spawn } from "child_process";
import { log } from "src/log";

// Generate types using typechain
// and typechain-target-fuels modules

// export async function buildTypes(config: Config) {
//   const cwd = process.cwd();
//   // find all files matching the glob
//   console.log(cwd);
//   console.log(config)
//   const allFiles = glob(cwd, [config.types.artifacts]);
//   await runTypegen({
//     cwd,
//     filesToProcess: allFiles,
//     allFiles,
//     outDir: config.types.output,
//     target: 'fuels',
//   });
// }

// Build contracts using forc
// We assume forc is install on the local
// if is not install it would result on
// throwing a error
export async function buildTypes(config: Config) {
  const cwd = process.cwd();
  // find all files matching the glob
  // console.log(cwd);
  // console.log(config)
  const allFiles = glob(cwd, [config.types.artifacts]);
  // console.log(allFiles);
  const promise = new Promise((resolve, reject) => {
    const typeGen = spawn(
      "npx",
      [
        "fuels-typegen",
        "-i",
        config.types.artifacts,
        "-o",
        config.types.output,
      ],
      { stdio: "inherit" }
    );
    log("Generating types...");
    typeGen.on("exit", (code) => {
      if (!code) return resolve(code);
      typeGen.kill();
      reject();
    });
  });
  Promise.all(config.types.output);
}
