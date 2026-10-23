import { writeFile } from "node:fs/promises";
import { join } from "node:path";
import { ChiefError, type Context } from "./context";
import { isAlreadyExists, makePrivateDir, writeJson } from "./files";
import {
    AGENTS_ARGV,
    attachCommands,
    type LaunchSpec,
    launchArgv,
    parseBgRef,
    sessionIdFor,
    stopHookSettings,
} from "./harness/claude";
import { appendJournal } from "./journal";
import { KICKOFF_FILE, kickoffPrompt } from "./kickoff";
import {
    type Autonomy,
    addSession,
    type Harness,
    isActive,
    loadRegistry,
    type SessionRecord,
} from "./registry";
import { slugify, validateSlug } from "./slug";
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

function chiefCommand(ctx: Context): string {
    return `bun ${shellQuote(ctx.cliPath)}`;
}

export async function spawnSession(ctx: Context, options: SpawnOptions): Promise<SessionRecord> {
    const { goal, harness, model, effort, autonomy } = options;
    if (harness !== "claude") throw new ChiefError(`harness "${harness}" is not supported yet`);
    const slug = options.slug ? validateSlug(options.slug) : slugify(goal);
    await ensureSlugAvailable(ctx, slug);

    const worktree = await createWorktree(ctx, options.repo, slug);
    const id = Bun.randomUUIDv7();
    await writeKickoff(
        ctx,
        worktree,
        kickoffPrompt({ id, slug, goal, autonomy, chief: chiefCommand(ctx) }),
    );
    const settingsPath = await writeStopHook(ctx, id);
    const launch = await launchWorker(ctx, worktree, { slug, model, effort, settingsPath });

    const now = ctx.now().toISOString();
    const record: SessionRecord = {
        id,
        slug,
        goal,
        harness,
        model,
        effort,
        repo: worktree.repo,
        worktree: worktree.path,
        branch: worktree.branch,
        autonomy,
        ...launch,
        waiting_on: null,
        cross_check: null,
        spawned_at: now,
        last_activity_at: now,
        closed_at: null,
        attach: attachCommands(launch.harness_session_id, launch.harness_ref, worktree.path),
    };
    await addSession(ctx, record);
    await appendJournal(
        ctx,
        `spawned \`${slug}\` (${harness}/${model}/${effort}, ${autonomy}) — goal: ${goal}${launch.state === "blocked" ? " — LAUNCH FAILED" : ""}`,
    );
    return record;
}

// Create-only ("wx"), so a file or symlink the repo checked out at that path can't redirect the
// write; the worktree is then useless, so it goes too.
async function writeKickoff(ctx: Context, worktree: Worktree, prompt: string): Promise<void> {
    try {
        await writeFile(join(worktree.path, KICKOFF_FILE), prompt, { flag: "wx" });
    } catch (error) {
        if (!isAlreadyExists(error)) throw error;
        const reason = `${worktree.repo} already has a ${KICKOFF_FILE} (Chief writes that file itself); remove it from the repo and retry`;
        throw new ChiefError(await discardWorktree(ctx, worktree, reason));
    }
}

type LaunchOutcome = Pick<
    SessionRecord,
    "state" | "harness_ref" | "harness_session_id" | "summary"
>;

async function launchWorker(
    ctx: Context,
    worktree: Worktree,
    spec: LaunchSpec,
): Promise<LaunchOutcome> {
    const launch = await ctx.run(launchArgv(spec), { cwd: worktree.path });
    // The record stays (blocked) so the human sees why; the worktree and branch go, so closing the
    // record frees the slug for a retry.
    if (launch.exitCode !== 0) {
        return {
            state: "blocked",
            harness_ref: null,
            harness_session_id: null,
            summary: await discardWorktree(
                ctx,
                worktree,
                `launch failed: ${firstLine(launch.stderr)}`,
            ),
        };
    }
    const harnessRef = parseBgRef(launch.stdout);
    return {
        state: "running",
        harness_ref: harnessRef,
        harness_session_id: harnessRef
            ? sessionIdFor((await ctx.run(AGENTS_ARGV)).stdout, harnessRef)
            : null,
        summary: null,
    };
}

// Undoes createWorktree; returns `reason`, plus why the cleanup failed if it did.
async function discardWorktree(ctx: Context, worktree: Worktree, reason: string): Promise<string> {
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
    await makePrivateDir(dir);
    const path = join(dir, `${id}.json`);
    const settings = stopHookSettings(`${chiefCommand(ctx)} report ${id} --stopped`);
    await writeJson(path, settings);
    return path;
}
