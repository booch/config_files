// Shared git helpers for the pre-commit hooks.
//
// `isGitCommit` is the single source of truth for "does this Bash command run a
// `git commit`?" — used by both pre-commit-doc-check and pre-commit-lint-check so
// the two stay in sync. It splits on newlines as well as `;`/`&&`/`||`/`|`, because
// commands are frequently issued as multi-line blocks (e.g. `git add …\ngit commit …`).
import { spawnSync } from "node:child_process";

const GIT_TIMEOUT_MS = 10_000;

export function isGitCommit(command: string): boolean {
  for (const segRaw of command.split(/[\n\r;]|&&|\|\||\|/)) {
    const seg = segRaw.trim();
    // Match an optional run of `VAR=value` prefixes, then `git`, optional global
    // flags (`-C path`, `--no-pager`, …), then the `commit` subcommand.
    if (!/^(?:[A-Z_][A-Z0-9_]*=\S+\s+)*git(?:\s+-[^\s]+(?:\s+\S+)?)*\s+commit(?:\s|$)/.test(seg)) continue;
    if (/\bcommit\b[^;|&]*\s(?:--help|-h)\b/.test(seg)) continue; // `git commit --help` is not a commit
    return true;
  }
  return false;
}

type GitResult = { stdout: string; status: number | null };

export function git(root: string, args: string[], timeoutMs = GIT_TIMEOUT_MS): GitResult | null {
  const r = spawnSync("git", ["-C", root, ...args], {
    encoding: "utf8",
    timeout: timeoutMs,
    maxBuffer: 16 * 1024 * 1024,
  });
  if (r.error) return null; // git missing, or timed out
  return { stdout: r.stdout ?? "", status: r.status };
}

export function gitRoot(cwd: string | undefined | null): string | null {
  if (!cwd) return null;
  const r = git(cwd, ["rev-parse", "--show-toplevel"], 5_000);
  if (!r || r.status !== 0) return null;
  return r.stdout.trim() || null;
}

// Staged files that still exist after the commit: Added/Copied/Modified/Renamed.
// Deletions are excluded — there is nothing to lint.
export function stagedFiles(root: string): string[] {
  const r = git(root, ["diff", "--cached", "--name-only", "--diff-filter=ACMR"]);
  if (!r || r.status !== 0) return [];
  return r.stdout.split("\n").map((s) => s.trim()).filter(Boolean);
}

export function existsAtHead(root: string, path: string): boolean {
  const r = git(root, ["cat-file", "-e", `HEAD:${path}`]);
  return !!r && r.status === 0;
}

export function headContent(root: string, path: string): string | null {
  const r = git(root, ["show", `HEAD:${path}`]);
  if (!r || r.status !== 0) return null;
  return r.stdout;
}
