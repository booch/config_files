import { readFile, rename, writeFile } from "node:fs/promises";
import { ChiefError } from "./context";

export function isNotFound(error: unknown): boolean {
    return (error as NodeJS.ErrnoException)?.code === "ENOENT";
}

export async function readTextIfExists(path: string): Promise<string | null> {
    try {
        return await readFile(path, "utf8");
    } catch (error) {
        if (isNotFound(error)) return null;
        throw error;
    }
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
