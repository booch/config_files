#!/usr/bin/env bun
import { runCommand } from "./commands";
import { ChiefError, defaultContext } from "./context";

try {
    const { output } = await runCommand(defaultContext(), process.argv.slice(2));
    if (output) console.log(output);
} catch (error) {
    if (!(error instanceof ChiefError)) throw error;
    console.error(`chief: ${error.message}`);
    process.exit(1);
}
