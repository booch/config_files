import { join, resolve } from "node:path";
import { ChiefError, type Context } from "./context";
import { readTextIfExists } from "./files";
import { expandHome } from "./text";

export interface ChiefConfig {
    watch: { dirs: string[] };
}

export const CONFIG_TEMPLATE = `# Chief of Staff configuration. The only hand-edited file in this directory.

[watch]
# Directories where scheduled tasks write dated Markdown reports (YYYY-MM-DD.md).
dirs = [
  "~/.local/share/ai/mac-software-updates",
]
`;

// Bun's TOML parser silently accepts a table header missing its closing bracket ("[watch").
const UNTERMINATED_HEADER = /^\s*\[\[?\s*[\w."-][\w."\- ]*\s*(#.*)?$/m;

export function configPath(ctx: Context): string {
    return join(ctx.home, "config.toml");
}

export async function loadConfig(ctx: Context): Promise<ChiefConfig> {
    const path = configPath(ctx);
    const text = await readTextIfExists(path);
    if (text === null) return { watch: { dirs: [] } };
    let parsed: { watch?: { dirs?: unknown } };
    try {
        if (UNTERMINATED_HEADER.test(text))
            throw new Error("table header is missing its closing ]");
        parsed = Bun.TOML.parse(text) as typeof parsed;
    } catch (error) {
        throw new ChiefError(`${path}: ${(error as Error).message}`);
    }
    const dirs = parsed.watch?.dirs ?? [];
    if (!Array.isArray(dirs) || !dirs.every((d) => typeof d === "string")) {
        throw new ChiefError(`${path}: [watch] dirs must be a list of strings`);
    }
    return { watch: { dirs: dirs.map((dir) => resolve(expandHome(dir))) } };
}
