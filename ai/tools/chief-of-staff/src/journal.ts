import { appendFile } from "node:fs/promises";
import { join } from "node:path";
import type { Context } from "./context";
import { makePrivateDir, readTextIfExists } from "./files";
import { oneLine } from "./text";
import { localDate, localMonth, localTime } from "./time";

export async function appendJournal(ctx: Context, text: string): Promise<void> {
    const now = ctx.now();
    const dir = journalDir(ctx);
    await makePrivateDir(dir);
    const file = join(dir, `${localMonth(now)}.md`);
    const existing = (await readTextIfExists(file)) ?? "";
    const heading = `## ${localDate(now)}`;
    const opening =
        lastHeading(existing) === heading ? "" : `${existing ? "\n" : ""}${heading}\n\n`;
    await appendFile(file, `${opening}- ${localTime(now)} ${oneLine(text)}\n`);
}

export async function tailJournal(ctx: Context, count: number): Promise<string[]> {
    const now = ctx.now();
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const texts = await Promise.all(
        [lastMonth, now].map((d) => readTextIfExists(join(journalDir(ctx), `${localMonth(d)}.md`))),
    );
    const lines = texts.flatMap((text) => (text ?? "").split("\n")).filter((line) => line.trim());
    return lines.slice(-count);
}

function journalDir(ctx: Context): string {
    return join(ctx.home, "journal");
}

function lastHeading(text: string): string | undefined {
    return text
        .split("\n")
        .filter((line) => line.startsWith("## "))
        .at(-1);
}
