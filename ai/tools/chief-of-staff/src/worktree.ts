import { basename, join } from "node:path";
import { ChiefError, type Context } from "./context";

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

async function git(ctx: Context, args: string[]): Promise<string> {
    const result = await ctx.run(["git", ...args]);
    if (result.exitCode !== 0)
        throw new ChiefError(`git ${args.slice(2).join(" ")} failed: ${result.stderr.trim()}`);
    return result.stdout.trim();
}
