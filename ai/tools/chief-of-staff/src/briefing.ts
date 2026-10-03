import { stat } from "node:fs/promises";
import type { Context } from "./context";
import { isNotFound } from "./files";
import { transcriptPath } from "./harness/claude";
import { tailJournal } from "./journal";
import { type Quota, readQuota } from "./quota";
import { isActive, loadRegistry, type SessionRecord, type SessionState } from "./registry";
import { minutesBetween } from "./time";

export const STALL_HOURS = 24;
export const JOURNAL_TAIL = 15;
const STATE_ORDER: SessionState[] = ["waiting", "blocked", "running"];
const CONTEXT_FILES = {
    projects: "~/Personal/Projects/Current.md",
    human: "~/.config/ai/HUMAN.md",
};

export type BriefingSession = Pick<
    SessionRecord,
    | "id"
    | "slug"
    | "goal"
    | "harness"
    | "model"
    | "state"
    | "waiting_on"
    | "summary"
    | "autonomy"
    | "worktree"
    | "attach"
> & { idle_minutes: number; stalled: boolean };

export interface Briefing {
    generated_at: string;
    sessions: BriefingSession[];
    journal_tail: string[];
    quota: Quota | null;
    context_files: typeof CONTEXT_FILES;
}

export async function buildBriefing(ctx: Context): Promise<Briefing> {
    const active = (await loadRegistry(ctx)).filter(isActive);
    const sessions = await Promise.all(active.map((s) => briefSession(ctx, s)));
    return {
        generated_at: ctx.now().toISOString(),
        sessions: sessions.sort(byUrgency),
        journal_tail: await tailJournal(ctx, JOURNAL_TAIL),
        quota: await readQuota(ctx),
        context_files: CONTEXT_FILES,
    };
}

async function briefSession(ctx: Context, s: SessionRecord): Promise<BriefingSession> {
    const lastActivity = latest(s.last_activity_at, await transcriptModifiedAt(ctx, s));
    const idle = minutesBetween(lastActivity, ctx.now());
    const {
        id,
        slug,
        goal,
        harness,
        model,
        state,
        waiting_on,
        summary,
        autonomy,
        worktree,
        attach,
    } = s;
    return {
        id,
        slug,
        goal,
        harness,
        model,
        state,
        waiting_on,
        summary,
        autonomy,
        worktree,
        attach,
        idle_minutes: idle,
        stalled: state === "running" && idle >= STALL_HOURS * 60,
    };
}

// The file's mtime is a cheap liveness signal that works even when a Stop hook never fired.
async function transcriptModifiedAt(ctx: Context, s: SessionRecord): Promise<string | null> {
    if (s.harness !== "claude" || !s.harness_session_id) return null;
    try {
        const path = transcriptPath(ctx.claudeHome, s.worktree, s.harness_session_id);
        return (await stat(path)).mtime.toISOString();
    } catch (error) {
        if (isNotFound(error)) return null;
        throw error;
    }
}

function latest(a: string, b: string | null): string {
    return b && b > a ? b : a;
}

// Most urgent first; within a state, the longest idle first.
function byUrgency(a: BriefingSession, b: BriefingSession): number {
    return (
        STATE_ORDER.indexOf(a.state) - STATE_ORDER.indexOf(b.state) ||
        b.idle_minutes - a.idle_minutes
    );
}
