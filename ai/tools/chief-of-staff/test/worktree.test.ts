import { afterEach, expect, test } from "bun:test";
import { existsSync } from "node:fs";
import { basename, join } from "node:path";
import { realRunner } from "../src/context";
import { createWorktree } from "../src/worktree";
import { makeGitRepo, testContext } from "./helpers";

let env: ReturnType<typeof testContext>;
afterEach(() => env.cleanup());

test("creates a branch and worktree under the worktree root, named for the repo", async () => {
    env = testContext();
    const repo = await makeGitRepo(env.root);
    const worktree = await createWorktree(env.ctx, repo, "fix-login");
    expect(worktree).toEqual({
        repo,
        path: join(env.ctx.worktreeRoot, basename(repo), "fix-login"),
        branch: "fix-login",
    });
    expect(existsSync(worktree.path)).toBe(true);
    const branch = await realRunner(["git", "-C", worktree.path, "branch", "--show-current"]);
    expect(branch.stdout.trim()).toBe("fix-login");
});

test("resolves a subdirectory to the repository root", async () => {
    env = testContext();
    const repo = await makeGitRepo(env.root);
    await realRunner(["mkdir", "-p", join(repo, "sub")]);
    expect((await createWorktree(env.ctx, join(repo, "sub"), "x")).repo).toBe(repo);
});

test("fails clearly outside a git repository", async () => {
    env = testContext();
    await expect(createWorktree(env.ctx, env.root, "x")).rejects.toThrow(
        /not a git repository|rev-parse/i,
    );
});

test("fails clearly when the branch already exists", async () => {
    env = testContext();
    const repo = await makeGitRepo(env.root);
    await createWorktree(env.ctx, repo, "dup");
    await expect(createWorktree(env.ctx, repo, "dup")).rejects.toThrow(/worktree add/);
});
