import { join } from "node:path";
import type { Context } from "./context";
import { readTextIfExists } from "./files";

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

export async function readQuota(ctx: Context): Promise<Quota | null> {
    const text = await readTextIfExists(join(ctx.claudeHome, QUOTA_FILE));
    if (text === null) return null;
    try {
        const raw = JSON.parse(text) as {
            five_hour?: Window;
            seven_day?: Window;
            updated_at?: string;
        };
        return {
            five_hour_percent: raw.five_hour?.used_percentage ?? null,
            five_hour_resets_at: epochToIso(raw.five_hour?.resets_at),
            seven_day_percent: raw.seven_day?.used_percentage ?? null,
            seven_day_resets_at: epochToIso(raw.seven_day?.resets_at),
            updated_at: raw.updated_at ?? null,
        };
    } catch {
        return null; // advisory data: a bad file must not break the briefing
    }
}

function epochToIso(seconds: number | undefined): string | null {
    return typeof seconds === "number" ? new Date(seconds * 1000).toISOString() : null;
}
