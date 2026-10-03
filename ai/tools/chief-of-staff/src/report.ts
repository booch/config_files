import { ChiefError, type Context } from "./context";
import { attachCommands } from "./harness/claude";
import { appendJournal } from "./journal";
import { findSession, type SessionRecord, type SessionState, updateSession } from "./registry";
import { oneLine, truncate } from "./text";

export const UNREPORTED_STOP = "unreported-stop";
const MAX_SUMMARY = 200;

export interface Report {
    state: SessionState;
    waitingOn?: string;
    summary?: string;
}

export async function reportState(
    ctx: Context,
    ref: string,
    { state, waitingOn, summary }: Report,
): Promise<SessionRecord> {
    if (state === "waiting" && !waitingOn) {
        throw new ChiefError("--state waiting needs --waiting-on <checkpoint>");
    }
    const session = await findSession(ctx, ref);
    const updated = await updateSession(ctx, session.id, (s) => ({
        state,
        waiting_on: state === "waiting" ? (waitingOn ?? null) : null,
        summary: summary ?? s.summary,
        last_activity_at: ctx.now().toISOString(),
    }));
    const detail = updated.waiting_on ? `${state} on ${updated.waiting_on}` : state;
    await appendJournal(ctx, `\`${updated.slug}\` ${detail}${summary ? `: ${summary}` : ""}`);
    return updated;
}

// Called by the worker's Stop hook after every turn. A worker that stops while still
// `running` never said why, so it needs a human look.
export async function reportStopped(
    ctx: Context,
    ref: string,
    hookInput: string,
): Promise<SessionRecord | null> {
    const input = parseHookInput(hookInput);
    if (input.stop_hook_active === true) return null;
    const session = await findSession(ctx, ref);
    const now = ctx.now().toISOString();
    const lastMessage =
        typeof input.last_assistant_message === "string" ? input.last_assistant_message : null;
    let unreported = false;
    const updated = await updateSession(ctx, session.id, (s) => {
        const backfill =
            s.harness_session_id || typeof input.session_id !== "string"
                ? {}
                : {
                      harness_session_id: input.session_id,
                      attach: attachCommands(input.session_id, s.harness_ref, s.worktree),
                  };
        if (s.state !== "running") return { last_activity_at: now, ...backfill };
        unreported = true;
        return {
            state: "waiting",
            waiting_on: UNREPORTED_STOP,
            summary: lastMessage ? truncate(oneLine(lastMessage), MAX_SUMMARY) : s.summary,
            last_activity_at: now,
            ...backfill,
        };
    });
    if (unreported) {
        await appendJournal(
            ctx,
            `\`${updated.slug}\` stopped without reporting; treating as waiting`,
        );
    }
    return updated;
}

function parseHookInput(text: string): Record<string, unknown> {
    try {
        const parsed = JSON.parse(text);
        return parsed && typeof parsed === "object" ? parsed : {};
    } catch {
        return {};
    }
}
