import { ChiefError, type Context } from "./context";
import { AGENTS_ARGV, isListed, resumeArgv, stopArgv } from "./harness/claude";
import { appendJournal } from "./journal";
import { findSession, type SessionRecord, updateSession } from "./registry";
import { firstLine } from "./text";

export const DEFAULT_APPROVAL = "Approved. Continue.";

const STOP_POLL_MS = 250;
const STOP_TIMEOUT_MS = 15_000;

export async function approveSession(
    ctx: Context,
    ref: string,
    message = DEFAULT_APPROVAL,
): Promise<SessionRecord> {
    const session = await findSession(ctx, ref);
    if (session.state !== "waiting" && session.state !== "blocked") {
        throw new ChiefError(`\`${session.slug}\` is ${session.state}, not waiting`);
    }
    if (session.harness !== "claude") {
        throw new ChiefError(`approve is not supported for ${session.harness} yet`);
    }
    if (!session.harness_ref || !session.harness_session_id) {
        throw new ChiefError(
            `\`${session.slug}\` has no Claude session id yet; attach to it by hand`,
        );
    }
    await stopAndWait(ctx, session.slug, session.harness_ref);
    const result = await ctx.run(resumeArgv(session.harness_session_id, message), {
        cwd: session.worktree,
    });
    if (result.exitCode !== 0) {
        throw new ChiefError(`could not resume \`${session.slug}\`: ${firstLine(result.stderr)}`);
    }
    const released = await updateSession(ctx, session.id, () => ({
        state: "running",
        waiting_on: null,
        last_activity_at: ctx.now().toISOString(),
    }));
    await appendJournal(
        ctx,
        `released \`${session.slug}\` (was waiting on ${session.waiting_on ?? session.state}): ${message}`,
    );
    return released;
}

// Resuming a live session starts a copy, and `claude stop` returns before the process exits.
// Any doubt that it stopped is an error, never a resume.
async function stopAndWait(ctx: Context, slug: string, ref: string): Promise<void> {
    const stop = await ctx.run(stopArgv(ref));
    if (stop.exitCode !== 0) {
        throw new ChiefError(`could not stop \`${slug}\`: ${firstLine(stop.stderr)}`);
    }
    const deadline = Date.now() + STOP_TIMEOUT_MS;
    while (await isRunning(ctx, ref)) {
        if (Date.now() > deadline) {
            throw new ChiefError(`session ${ref} did not stop within ${STOP_TIMEOUT_MS / 1000}s`);
        }
        await Bun.sleep(STOP_POLL_MS);
    }
}

async function isRunning(ctx: Context, ref: string): Promise<boolean> {
    const agents = await ctx.run(AGENTS_ARGV);
    if (agents.exitCode !== 0) {
        throw new ChiefError(`claude agents failed: ${firstLine(agents.stderr)}`);
    }
    return isListed(agents.stdout, ref);
}
