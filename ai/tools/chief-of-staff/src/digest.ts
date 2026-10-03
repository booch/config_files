import { ChiefError, type Context } from "./context";
import { readTextIfExists } from "./files";
import { digestTranscript, type TranscriptDigest, transcriptPath } from "./harness/claude";
import { findSession, type SessionState, updateSession } from "./registry";

export type SessionDigest = {
    id: string;
    slug: string;
    state: SessionState;
    transcript: string | null;
    available: boolean;
} & Partial<TranscriptDigest>;

export async function digestSession(ctx: Context, ref: string, recent = 3): Promise<SessionDigest> {
    const session = await findSession(ctx, ref);
    if (session.harness !== "claude")
        throw new ChiefError(`digest is not supported for ${session.harness} yet`);

    const transcript = session.harness_session_id
        ? transcriptPath(ctx.claudeHome, session.worktree, session.harness_session_id)
        : null;
    const header = { id: session.id, slug: session.slug, state: session.state, transcript };
    const text = transcript ? await readTextIfExists(transcript) : null;
    if (text === null) return { ...header, available: false };

    const digest = digestTranscript(text, recent);
    const seen = digest.lastActivityAt;
    if (seen)
        await updateSession(ctx, session.id, (s) =>
            seen > s.last_activity_at ? { last_activity_at: seen } : {},
        );
    return { ...header, available: true, ...digest };
}
