// Linter registry for the pre-commit regression gate.
//
// Each linter reports an issue COUNT for a given file (or null when it cannot run —
// tool missing, timed out, or unparseable output). The gate compares the count of the
// staged file against the same file at HEAD and blocks only on an increase, so
// pre-existing lint debt never blocks a commit.
//
// `count` must FAIL OPEN: any uncertainty returns null (skip), never a fabricated
// number. Adding a language = add a linter here and map its extensions in `lintersFor`.
import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";

export type Linter = {
  name: string;
  // Issue count for `filePath`, or null if the linter could not produce a reliable count.
  count: (filePath: string) => number | null;
  // When a file is brand-new (no HEAD version), block if it has any issues?
  // True for config-respecting correctness linters; false for Markdown, whose house
  // style legitimately diverges from the configured rules.
  gateNewFiles: boolean;
};

type RunResult = { stdout: string; stderr: string; status: number | null };

// Runs a tool and returns its output, or null if the tool is missing or timed out
// (spawnSync sets `error` for ENOENT and for the timeout kill). Linting in the file's
// own directory lets each tool resolve its project config (.shellcheckrc, .rubocop.yml,
// pyproject.toml, .markdownlint*) exactly as it would for the real file.
function run(cmd: string, args: string[], filePath: string, timeoutMs = 15_000): RunResult | null {
  const r = spawnSync(cmd, args, {
    cwd: dirname(filePath),
    encoding: "utf8",
    timeout: timeoutMs,
    maxBuffer: 16 * 1024 * 1024,
  });
  if (r.error) return null;
  return { stdout: r.stdout ?? "", stderr: r.stderr ?? "", status: r.status };
}

function jsonArrayLength(out: string): number | null {
  try {
    const arr = JSON.parse(out);
    return Array.isArray(arr) ? arr.length : null;
  } catch {
    return null;
  }
}

const shellcheck: Linter = {
  name: "shellcheck",
  gateNewFiles: true,
  count: (f) => {
    const r = run("shellcheck", ["-S", "warning", "-f", "json", f], f);
    if (!r) return null;
    return jsonArrayLength(r.stdout); // exit is 0 (clean) or 1 (issues); both emit JSON
  },
};

const shfmt: Linter = {
  name: "shfmt",
  gateNewFiles: true,
  count: (f) => {
    const r = run("shfmt", ["-d", f], f);
    if (!r) return null;
    if (r.status === 0) return 0; // already formatted
    if (r.status === 1) return r.stdout.trim() ? 1 : 0; // 1 = diff present
    return null; // 2+ = parse/other error → skip
  },
};

const markdownlint: Linter = {
  name: "markdownlint",
  gateNewFiles: false,
  count: (f) => {
    const r = run("markdownlint-cli2", [f], f);
    if (!r) return null;
    const m = `${r.stdout}\n${r.stderr}`.match(/Summary:\s*(\d+)\s*error/);
    return m ? Number(m[1]) : null;
  },
};

const ruff: Linter = {
  name: "ruff",
  gateNewFiles: true,
  count: (f) => {
    const r = run("ruff", ["check", "--quiet", "--output-format", "json", f], f);
    if (!r) return null;
    return jsonArrayLength(r.stdout); // `[]` when clean
  },
};

function hasGemfileAbove(startDir: string): boolean {
  let dir = startDir;
  for (let i = 0; i < 30; i++) {
    if (existsSync(join(dir, "Gemfile"))) return true;
    const parent = dirname(dir);
    if (parent === dir) return false;
    dir = parent;
  }
  return false;
}

const rubocop: Linter = {
  name: "rubocop",
  gateNewFiles: true,
  count: (f) => {
    // Prefer the project's pinned rubocop via Bundler; fall back to a global rubocop
    // for loose scripts. --force-exclusion honors the project's Exclude list even for
    // an explicit path. Longer timeout: rubocop boots a Ruby VM. Best-effort — fails
    // open (null) if the tool is absent, slow, or emits no parseable JSON.
    const args = ["--format", "json", "--force-exclusion", f];
    const r = hasGemfileAbove(dirname(f))
      ? run("bundle", ["exec", "rubocop", ...args], f, 30_000)
      : run("rubocop", args, f, 25_000);
    if (!r) return null;
    try {
      const n = JSON.parse(r.stdout)?.summary?.offense_count;
      return typeof n === "number" ? n : null;
    } catch {
      return null;
    }
  },
};

const BY_EXTENSION: Record<string, Linter[]> = {
  ".sh": [shellcheck, shfmt],
  ".bash": [shellcheck, shfmt],
  ".zsh": [shellcheck, shfmt],
  ".md": [markdownlint],
  ".markdown": [markdownlint],
  ".py": [ruff],
  ".pyi": [ruff],
  ".rb": [rubocop],
  ".rake": [rubocop],
};

export function lintersFor(path: string): Linter[] {
  const dot = path.lastIndexOf(".");
  if (dot < 0) return [];
  return BY_EXTENSION[path.slice(dot).toLowerCase()] ?? [];
}
