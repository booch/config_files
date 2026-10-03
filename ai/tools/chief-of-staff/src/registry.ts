import { mkdir, rm, stat } from "node:fs/promises";
import { join } from "node:path";
import { ChiefError, type Context } from "./context";
import { isNotFound, readTextIfExists, writeAtomically } from "./files";

export const HARNESSES = ["claude", "codex", "opencode"] as const;
export const STATES = ["running", "waiting", "blocked", "done", "abandoned"] as const;
export const AUTONOMIES = ["auto", "checkpointed"] as const;
export type Harness = (typeof HARNESSES)[number];
export type SessionState = (typeof STATES)[number];
export type Autonomy = (typeof AUTONOMIES)[number];

export interface SessionRecord {
    id: string;
    slug: string;
    goal: string;
    harness: Harness;
    harness_ref: string | null; // the harness's own handle (e.g. the short id `claude attach` takes)
    harness_session_id: string | null; // the harness's full session id (transcripts, resume); null until known
    model: string;
    effort: string;
    repo: string;
    worktree: string;
    branch: string;
    autonomy: Autonomy;
    state: SessionState;
    waiting_on: string | null;
    summary: string | null;
    cross_check: string | null;
    spawned_at: string;
    last_activity_at: string;
    closed_at: string | null; // set by the human's `chief close`; a worker's own `done` leaves it null
    attach: { terminal: string | null; resume: string | null };
}

const MIN_PREFIX = 4;
const LOCK_TIMEOUT_MS = 5_000;
const STALE_LOCK_MS = 30_000;
const LOCK_RETRY_MS = 20;

export function isActive(session: SessionRecord): boolean {
    return session.closed_at === null;
}

export async function loadRegistry(ctx: Context): Promise<SessionRecord[]> {
    const path = registryPath(ctx);
    const text = await readTextIfExists(path);
    if (text === null) return [];
    try {
        return JSON.parse(text).sessions;
    } catch (error) {
        throw new ChiefError(
            `${path} is not valid JSON (${(error as Error).message}); fix or move it aside`,
        );
    }
}

export async function addSession(ctx: Context, record: SessionRecord): Promise<void> {
    await mutateRegistry(ctx, (sessions) => {
        if (sessions.some((s) => s.id === record.id)) {
            throw new ChiefError(`duplicate session id ${record.id}`);
        }
        return [...sessions, record];
    });
}

export async function updateSession(
    ctx: Context,
    id: string,
    change: (session: SessionRecord) => Partial<SessionRecord>,
): Promise<SessionRecord> {
    const sessions = await mutateRegistry(ctx, (all) => {
        if (!all.some((s) => s.id === id)) throw new ChiefError(`no session with id ${id}`);
        return all.map((s) => (s.id === id ? { ...s, ...change(s), id } : s));
    });
    return sessions.find((s) => s.id === id) as SessionRecord;
}

export async function findSession(ctx: Context, ref: string): Promise<SessionRecord> {
    const sessions = await loadRegistry(ctx);
    const exact = sessions.find((s) => s.id === ref);
    if (exact) return exact;
    const bySlug = sessions.filter((s) => s.slug === ref).at(-1);
    if (bySlug) return bySlug;
    if (ref.length >= MIN_PREFIX) {
        const byPrefix = sessions.filter((s) => s.id.startsWith(ref));
        if (byPrefix.length > 1) {
            throw new ChiefError(
                `"${ref}" is ambiguous: ${byPrefix.map((s) => s.slug).join(", ")}`,
            );
        }
        if (byPrefix[0]) return byPrefix[0];
    }
    throw new ChiefError(`no session matches "${ref}"`);
}

function registryPath(ctx: Context): string {
    return join(ctx.home, "registry.json");
}

// Returns the sessions as written.
async function mutateRegistry(
    ctx: Context,
    mutate: (sessions: SessionRecord[]) => SessionRecord[],
): Promise<SessionRecord[]> {
    await mkdir(ctx.home, { recursive: true });
    return withLock(join(ctx.home, "registry.lock"), async () => {
        const sessions = mutate(await loadRegistry(ctx));
        await writeAtomically(
            registryPath(ctx),
            `${JSON.stringify({ version: 1, sessions }, null, 2)}\n`,
        );
        return sessions;
    });
}

// mkdir is atomic, so it doubles as a cross-process mutex. A lock older than STALE_LOCK_MS
// belongs to a crashed process and is broken.
async function withLock<T>(lock: string, body: () => Promise<T>): Promise<T> {
    const deadline = Date.now() + LOCK_TIMEOUT_MS;
    while (!(await tryLock(lock))) {
        if (await isStale(lock)) {
            await rm(lock, { recursive: true, force: true });
        } else if (Date.now() > deadline) {
            throw new ChiefError(`registry is locked (${lock}); remove it if no chief is running`);
        } else {
            await Bun.sleep(LOCK_RETRY_MS);
        }
    }
    try {
        return await body();
    } finally {
        await rm(lock, { recursive: true, force: true });
    }
}

async function tryLock(lock: string): Promise<boolean> {
    try {
        await mkdir(lock);
        return true;
    } catch (error) {
        if ((error as NodeJS.ErrnoException).code === "EEXIST") return false;
        throw error;
    }
}

async function isStale(lock: string): Promise<boolean> {
    try {
        return Date.now() - (await stat(lock)).mtimeMs > STALE_LOCK_MS;
    } catch (error) {
        return isNotFound(error); // released between our mkdir and stat: retry immediately
    }
}
