#!/usr/bin/env -S bun run
// PreToolUse(Bash) gate: blocks a `git commit` when a staged file has MORE lint
// issues than the same file at HEAD (a regression). Pre-existing issues never block —
// only net-new ones — so this is safe to run over a repo carrying lint debt.
//
// Fails open: any error, missing tool, or non-git-repo lets the commit through.
import { writeFileSync, unlinkSync, existsSync } from "node:fs";
import { dirname, basename, join } from "node:path";
import { isGitCommit, gitRoot, stagedFiles, existsAtHead, headContent, stagedContent } from "./lib/git";
import { lintersFor, type Linter } from "./lib/lint-registry";

const MAX_FILES = 40; // cap work per commit; larger commits get a partial check (noted)

type Regression = { file: string; linter: string; base: number | null; now: number };

let tmpCounter = 0;

async function main(): Promise<void> {
  const input = await readJsonStdin();
  const command = String((input.tool_input as any)?.command ?? "");
  if (!isGitCommit(command)) return;

  const root = gitRoot(input.cwd as string | undefined);
  if (!root) return;

  const all = stagedFiles(root);
  const files = all.slice(0, MAX_FILES);
  const truncated = all.length > files.length ? all.length : 0;

  const regressions: Regression[] = [];
  for (const file of files) {
    for (const linter of lintersFor(file)) {
      const reg = checkFile(root, file, linter);
      if (reg) regressions.push(reg);
    }
  }

  if (regressions.length === 0) return;

  const reason = buildReason(regressions, truncated);
  process.stdout.write(
    JSON.stringify({
      decision: "block",
      reason,
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: reason,
      },
    }),
  );
}

// Lints the STAGED (index) content of the file — what the commit will actually
// contain — and compares it to the HEAD baseline. Under partial staging the
// working tree differs from the index, and linting the working tree would
// misattribute unstaged issues to the commit. Returns a Regression only on a
// genuine increase.
function checkFile(root: string, file: string, linter: Linter): Regression | null {
  const abs = join(root, file);

  const staged = stagedContent(root, file);
  if (staged === null) return null; // couldn't read the index version → don't block
  const now = materializedCount(abs, staged, linter);
  if (now === null || now === 0) return null; // unavailable, or clean → nothing to regress

  if (!existsAtHead(root, file)) {
    return linter.gateNewFiles ? { file, linter: linter.name, base: null, now } : null;
  }

  const base = headContent(root, file);
  if (base === null) return null; // couldn't establish a baseline → don't block
  const baseCount = materializedCount(abs, base, linter);
  if (baseCount === null) return null;
  return now > baseCount ? { file, linter: linter.name, base: baseCount, now } : null;
}

// Materializes the given content beside the real file so the linter resolves the
// same project config, counts its issues, then removes the temp file.
function materializedCount(abs: string, content: string, linter: Linter): number | null {
  const tmp = join(dirname(abs), `pclint-base-${process.pid}-${tmpCounter++}-${basename(abs)}`);
  try {
    writeFileSync(tmp, content);
    return linter.count(tmp);
  } catch {
    return null;
  } finally {
    try {
      if (existsSync(tmp)) unlinkSync(tmp);
    } catch {
      /* best-effort cleanup */
    }
  }
}

function buildReason(regs: Regression[], truncated: number): string {
  const lines = ["Pre-commit blocked: new lint issues in staged files (regressions vs HEAD).", ""];
  for (const r of regs) {
    const from = r.base === null ? "new file" : `${r.base}`;
    lines.push(`  - ${r.file}: ${r.linter} ${from} → ${r.now} issue(s)`);
  }
  lines.push(
    "",
    "Only net-new issues block — pre-existing lint debt is ignored.",
    "Fix the new issues (or run the formatter), re-stage, and commit again.",
  );
  if (truncated) lines.push("", `(Note: ${truncated} staged files; checked the first ${MAX_FILES}.)`);
  return lines.join("\n");
}

async function readJsonStdin(): Promise<Record<string, unknown>> {
  try {
    return JSON.parse(await Bun.stdin.text()) as Record<string, unknown>;
  } catch {
    return {};
  }
}

main().catch((e) => {
  process.stderr.write(`pre-commit-lint-check error: ${e?.message ?? e}\n`);
  process.exit(0);
});
