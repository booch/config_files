import { basename, join } from "node:path";
import { ChiefError, type Context } from "./context";
import { firstLine } from "./text";

export interface Worktree {
    repo: string;
    path: string;
    branch: string;
}

export async function createWorktree(
    ctx: Context,
    repoDir: string,
    slug: string,
): Promise<Worktree> {
    const repo = await git(ctx, ["-C", repoDir, "rev-parse", "--show-toplevel"]);
    const path = join(ctx.worktreeRoot, basename(repo), slug);
    await git(ctx, ["-C", repo, "worktree", "add", "-b", slug, path]);
    return { repo, path, branch: slug };
}

// Undoes createWorktree, including uncommitted files. Returns why it failed, or null.
export async function removeWorktree(
    ctx: Context,
    { repo, path, branch }: Worktree,
): Promise<string | null> {
    for (const args of [
        ["worktree", "remove", "--force", path],
        ["branch", "-D", branch],
    ]) {
        const result = await ctx.run(["git", ...args], { cwd: repo });
        if (result.exitCode !== 0) return firstLine(result.stderr);
    }
    return null;
}

async function git(ctx: Context, args: string[]): Promise<string> {
    const result = await ctx.run(["git", ...args]);
    if (result.exitCode !== 0)
        throw new ChiefError(`git ${args.slice(2).join(" ")} failed: ${result.stderr.trim()}`);
    return result.stdout.trim();
}
