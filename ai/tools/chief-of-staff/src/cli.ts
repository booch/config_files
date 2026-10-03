#!/usr/bin/env bun
import { runCommand } from "./commands";
import { ChiefError, defaultContext } from "./context";

const argv = process.argv.slice(2);
// A Stop hook must never break the worker it runs in: report problems, exit 0.
const isStopHook = argv[0] === "report" && argv.includes("--stopped");

try {
    const { output } = await runCommand(defaultContext(), argv);
    // Claude treats hook stdout as possible control JSON, so a Stop hook prints nothing.
    if (output && !isStopHook) console.log(output);
} catch (error) {
    if (!(error instanceof ChiefError) && !isStopHook) throw error;
    console.error(`chief: ${(error as Error).message}`);
    process.exit(isStopHook ? 0 : 1);
}
