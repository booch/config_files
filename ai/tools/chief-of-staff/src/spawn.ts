import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { ChiefError, type Context } from "./context";
import {
    AGENTS_ARGV,
    attachCommands,
    launchArgv,
    parseBgRef,
    sessionIdFor,
    stopHookSettings,
} from "./harness/claude";
import { appendJournal } from "./journal";
import { KICKOFF_FILE, kickoffPrompt, slugify, validateSlug } from "./kickoff";
import {
    type Autonomy,
    addSession,
    type Harness,
    isActive,
    loadRegistry,
    type SessionRecord,
} from "./registry";
import { firstLine, shellQuote } from "./text";
import { createWorktree, removeWorktree, type Worktree } from "./worktree";

export interface SpawnOptions {
    goal: string;
    slug?: string;
    repo: string;
    harness: Harness;
    model: string;
    effort: string;
    autonomy: Autonomy;
}

export function chiefCommand(ctx: Context): string {
    return `bun ${shellQuote(ctx.cliPath)}`;
}

export async function spawnSession(ctx: Context, options: SpawnOptions): Promise<SessionRecord> {
    const { goal, harness, model, effort, autonomy } = options;
    if (harness !== "claude") throw new ChiefError(`harness "${harness}" is not supported yet`);
    const slug = options.slug ? validateSlug(options.slug) : slugify(goal);
    await ensureSlugAvailable(ctx, slug);

    const worktree = await createWorktree(ctx, options.repo, slug);
    const id = Bun.randomUUIDv7();
    await writeFile(
        join(worktree.path, KICKOFF_FILE),
        kickoffPrompt({ id, slug, goal, autonomy, chief: chiefCommand(ctx) }),
    );
    const settingsPath = await writeStopHook(ctx, id);
    const launch = await ctx.run(launchArgv({ slug, model, effort, settingsPath }), {
        cwd: worktree.path,
    });
    const launched = launch.exitCode === 0;
    const harnessRef = launched ? parseBgRef(launch.stdout) : null;
    const harnessSessionId = harnessRef
        ? sessionIdFor((await ctx.run(AGENTS_ARGV)).stdout, harnessRef)
        : null;
    const failure = launched ? null : await cleanUpFailedLaunch(ctx, worktree, launch.stderr);

    const now = ctx.now().toISOString();
    const record: SessionRecord = {
        id,
        slug,
        goal,
        harness,
        harness_ref: harnessRef,
        harness_session_id: harnessSessionId,
        model,
        effort,
        repo: worktree.repo,
        worktree: worktree.path,
        branch: worktree.branch,
        autonomy,
        state: launched ? "running" : "blocked",
        waiting_on: null,
        summary: failure,
        cross_check: null,
        spawned_at: now,
        last_activity_at: now,
        closed_at: null,
        attach: attachCommands(harnessSessionId, harnessRef, worktree.path),
    };
    await addSession(ctx, record);
    await appendJournal(
        ctx,
        `spawned \`${slug}\` (${harness}/${model}/${effort}, ${autonomy}) — goal: ${goal}${launched ? "" : " — LAUNCH FAILED"}`,
    );
    return record;
}

// The record stays (blocked) so the human sees why; the worktree and branch go, so closing the
// record frees the slug for a retry. Returns the summary to record.
async function cleanUpFailedLaunch(
    ctx: Context,
    worktree: Worktree,
    stderr: string,
): Promise<string> {
    const reason = `launch failed: ${firstLine(stderr)}`;
    const cleanupError = await removeWorktree(ctx, worktree);
    return cleanupError ? `${reason}; cleanup failed: ${cleanupError}` : reason;
}

async function ensureSlugAvailable(ctx: Context, slug: string): Promise<void> {
    const clash = (await loadRegistry(ctx)).find((s) => s.slug === slug && isActive(s));
    if (clash) {
        throw new ChiefError(`slug "${slug}" is already in use by an active session (${clash.id})`);
    }
}

async function writeStopHook(ctx: Context, id: string): Promise<string> {
    const dir = join(ctx.home, "hooks");
    await mkdir(dir, { recursive: true });
    const path = join(dir, `${id}.json`);
    const settings = stopHookSettings(`${chiefCommand(ctx)} report ${id} --stopped`);
    await writeFile(path, `${JSON.stringify(settings, null, 2)}\n`);
    return path;
}
