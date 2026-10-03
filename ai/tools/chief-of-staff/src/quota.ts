import { join } from "node:path";
import type { Context } from "./context";
import { readTextIfExists } from "./files";
import { tryParseJson } from "./text";

// Written by abtop's statusline hook; read to decide when to route work elsewhere.
const QUOTA_FILE = "abtop-rate-limits.json";

export interface Quota {
    five_hour_percent: number | null;
    five_hour_resets_at: string | null;
    seven_day_percent: number | null;
    seven_day_resets_at: string | null;
    updated_at: string | null;
}

interface Window {
    used_percentage?: number;
    resets_at?: number;
}

interface RawQuota {
    five_hour?: Window;
    seven_day?: Window;
    updated_at?: string;
}

// Advisory data: a bad file must not break the briefing.
export async function readQuota(ctx: Context): Promise<Quota | null> {
    const text = await readTextIfExists(join(ctx.claudeHome, QUOTA_FILE));
    if (text === null) return null;
    const raw = tryParseJson(text) as RawQuota | null | undefined;
    if (raw === undefined || raw === null) return null;
    return {
        five_hour_percent: raw.five_hour?.used_percentage ?? null,
        five_hour_resets_at: epochToIso(raw.five_hour?.resets_at),
        seven_day_percent: raw.seven_day?.used_percentage ?? null,
        seven_day_resets_at: epochToIso(raw.seven_day?.resets_at),
        updated_at: raw.updated_at ?? null,
    };
}

function epochToIso(seconds: number | undefined): string | null {
    if (typeof seconds !== "number") return null;
    const date = new Date(seconds * 1000);
    return Number.isNaN(date.getTime()) ? null : date.toISOString();
}
