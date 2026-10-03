import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { ChiefError } from "./context";

// Chief's state holds goals, summaries, and hook commands: keep it to its owner.
export async function makePrivateDir(path: string): Promise<void> {
    await mkdir(path, { recursive: true, mode: 0o700 });
}

export function isNotFound(error: unknown): boolean {
    return (error as NodeJS.ErrnoException)?.code === "ENOENT";
}

// Resolves to null when the file or directory does not exist; any other failure still throws.
export async function ifExists<T>(op: Promise<T>): Promise<T | null> {
    try {
        return await op;
    } catch (error) {
        if (isNotFound(error)) return null;
        throw error;
    }
}

export function readTextIfExists(path: string): Promise<string | null> {
    return ifExists(readFile(path, "utf8"));
}

// Chief's own state files: a missing file is a fresh start, but one that does not parse (even an
// empty one) is never guessed at.
export async function readJsonIfExists(path: string): Promise<unknown | null> {
    const text = await readTextIfExists(path);
    if (text === null) return null;
    try {
        return JSON.parse(text);
    } catch (error) {
        throw new ChiefError(
            `${path} is not valid JSON (${(error as Error).message}); fix or move it aside`,
        );
    }
}

export async function writeJson(path: string, value: unknown): Promise<void> {
    await writeAtomically(path, `${JSON.stringify(value, null, 2)}\n`);
}

// Readers never see a half-written file: write beside the target, then rename over it.
export async function writeAtomically(path: string, content: string): Promise<void> {
    const temp = `${path}.${process.pid}.${crypto.randomUUID()}.tmp`;
    await writeFile(temp, content);
    await rename(temp, path);
}
