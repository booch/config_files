import { afterEach, expect, test } from "bun:test";
import { writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { CONFIG_TEMPLATE, loadConfig } from "../src/config";
import { testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

const writeConfig = (text: string) => writeFileSync(join(env.ctx.home, "config.toml"), text);

test("defaults to watching nothing when there is no config", async () => {
    env = testContext();
    expect(await loadConfig(env.ctx)).toEqual({ watch: { dirs: [] } });
});

test("expands ~ in watch dirs", async () => {
    env = testContext();
    writeConfig('[watch]\ndirs = ["~/a", "/b"]\n');
    expect((await loadConfig(env.ctx)).watch.dirs).toEqual([join(homedir(), "a"), "/b"]);
});

test("the template parses and watches mac-software-updates", async () => {
    env = testContext();
    writeConfig(CONFIG_TEMPLATE);
    expect((await loadConfig(env.ctx)).watch.dirs).toEqual([
        join(homedir(), ".local/share/ai/mac-software-updates"),
    ]);
});

test("reports bad TOML and bad shapes, naming the file", async () => {
    env = testContext();
    writeConfig("[watch\n");
    await expect(loadConfig(env.ctx)).rejects.toThrow(/config\.toml/);
    writeConfig('[watch]\ndirs = "not-a-list"\n');
    await expect(loadConfig(env.ctx)).rejects.toThrow(/list of strings/);
});
