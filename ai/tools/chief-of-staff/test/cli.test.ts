import { afterEach, expect, test } from "bun:test";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const CLI = join(import.meta.dir, "..", "src", "cli.ts");
let home: string;
afterEach(() => rmSync(home, { recursive: true, force: true }));

async function chief(args: string[], stdin = "") {
    home = mkdtempSync(join(tmpdir(), "chief-cli-"));
    const proc = Bun.spawn([process.execPath, CLI, ...args], {
        env: { ...process.env, CHIEF_HOME: home },
        stdin: new Blob([stdin]),
        stdout: "pipe",
        stderr: "pipe",
    });
    const [stdout, stderr, exitCode] = await Promise.all([
        new Response(proc.stdout).text(),
        new Response(proc.stderr).text(),
        proc.exited,
    ]);
    return { stdout, stderr, exitCode };
}

test("a failing Stop hook exits 0 and prints nothing claude would read as control JSON", async () => {
    const result = await chief(["report", "nonexistent", "--stopped"], "not json");
    expect(result).toMatchObject({ exitCode: 0, stdout: "" });
});

test("any other failure exits 1 with the problem on stderr", async () => {
    const result = await chief(["frobnicate"]);
    expect(result.exitCode).toBe(1);
    expect(result.stderr).toContain("chief:");
});
