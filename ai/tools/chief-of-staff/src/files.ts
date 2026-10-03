import { readFile, rename, writeFile } from "node:fs/promises";

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

// Readers never see a half-written file: write beside the target, then rename over it.
export async function writeAtomically(path: string, content: string): Promise<void> {
    const temp = `${path}.${process.pid}.${crypto.randomUUID()}.tmp`;
    await writeFile(temp, content);
    await rename(temp, path);
}
