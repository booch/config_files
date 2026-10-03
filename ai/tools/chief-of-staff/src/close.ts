import { ChiefError, type Context } from "./context";
import { appendJournal } from "./journal";
import { findSession, isActive, type SessionRecord, updateSession } from "./registry";

// The human's verdict on a session; a worker's own `done` report leaves it open until this runs.
export async function closeSession(
    ctx: Context,
    ref: string,
    state: "done" | "abandoned",
    summary?: string,
): Promise<SessionRecord> {
    const session = await findSession(ctx, ref);
    const closed = await updateSession(ctx, session.id, (s) => {
        if (!isActive(s)) throw new ChiefError(`\`${s.slug}\` is already closed`);
        return {
            state,
            waiting_on: null,
            summary: summary ?? s.summary,
            closed_at: ctx.now().toISOString(),
        };
    });
    await appendJournal(
        ctx,
        `closed \`${closed.slug}\` (${state})${summary ? `: ${summary}` : ""}`,
    );
    return closed;
}
