import { readdir, readFile } from "node:fs/promises";
import { basename, dirname, join } from "node:path";
import { loadConfig } from "./config";
import { ChiefError, type Context } from "./context";
import { ifExists, readJsonIfExists, writeJson } from "./files";

const DATED_REPORT = /^(\d{4}-\d{2}-\d{2})\.md$/;
const HIGHLIGHTS = 3;

export interface Update {
    task: string; // the watched directory's name
    date: string;
    path: string;
    highlights: string[];
}

type Watermarks = Record<string, string>; // watched dir → latest reviewed date

export async function unreviewedUpdates(ctx: Context): Promise<Update[]> {
    const [{ watch }, marks] = await Promise.all([loadConfig(ctx), loadWatermarks(ctx)]);
    const perDir = await Promise.all(watch.dirs.map((dir) => reportsAfter(dir, marks[dir] ?? "")));
    return perDir
        .flat()
        .sort((a, b) => b.date.localeCompare(a.date) || a.task.localeCompare(b.task));
}

export async function markReviewed(ctx: Context, task?: string): Promise<number> {
    const marking = (await unreviewedUpdates(ctx)).filter((u) => !task || u.task === task);
    const marks = await loadWatermarks(ctx);
    for (const { path, date } of marking) {
        const dir = dirname(path);
        if (date > (marks[dir] ?? "")) marks[dir] = date;
    }
    await writeJson(watermarkPath(ctx), marks);
    return marking.length;
}

export function highlights(markdown: string, limit = HIGHLIGHTS): string[] {
    return markdown
        .split("\n")
        .map((line) => line.trim())
        .filter((line) => line && !line.startsWith("#") && line !== "---")
        .map((line) => line.replace(/^[-*]\s+/, ""))
        .slice(0, limit);
}

async function reportsAfter(dir: string, after: string): Promise<Update[]> {
    const names = (await ifExists(readdir(dir))) ?? []; // a task that has not run yet
    const dates = names
        .map((name) => DATED_REPORT.exec(name)?.[1])
        .filter((date): date is string => date !== undefined && date > after);
    return Promise.all(
        dates.map(async (date) => {
            const path = join(dir, `${date}.md`);
            return {
                task: basename(dir),
                date,
                path,
                highlights: highlights(await readFile(path, "utf8")),
            };
        }),
    );
}

async function loadWatermarks(ctx: Context): Promise<Watermarks> {
    const path = watermarkPath(ctx);
    const parsed = await readJsonIfExists(path);
    if (parsed === null) return {};
    if (typeof parsed !== "object" || Array.isArray(parsed)) {
        throw new ChiefError(`${path} must be a JSON object of dir → date; fix or move it aside`);
    }
    return parsed as Watermarks;
}

function watermarkPath(ctx: Context): string {
    return join(ctx.home, "reviewed.json");
}
