#!/usr/bin/env -S bun run
import { loadTranscript, analyseTranscript } from "./lib/task-scope";

const DOC_EXTENSIONS = new Set([".md", ".txt", ".rst", ".adoc"]);

async function main(): Promise<void> {
  const input = await readJsonStdin();
  const command = String((input.tool_input as any)?.command ?? "");
  if (!isGitCommit(command)) return;

  const entries = loadTranscript(input.transcript_path as string | undefined);
  const scope = analyseTranscript(entries);

  if (hasDocSkillInvocation(scope.skillsInvoked)) return;
  if (onlyDocFilesModified(scope.filesModified)) return;

  const reason = [
    "Documentation skill not invoked this task — run `boochtek:documentation` via the Skill tool before committing.",
    "",
    `Blocked command: ${command.slice(0, 200)}`,
  ].join("\n");
  process.stdout.write(JSON.stringify({ decision: "block", reason }));
}

function onlyDocFilesModified(files: Set<string>): boolean {
  if (files.size === 0) return false;
  for (const f of files) {
    const ext = f.slice(f.lastIndexOf(".")).toLowerCase();
    if (!DOC_EXTENSIONS.has(ext)) return false;
  }
  return true;
}

function isGitCommit(cmd: string): boolean {
  for (const segRaw of cmd.split(/;|&&|\|\||\|/)) {
    const seg = segRaw.trim();
    if (!/^(?:[A-Z_][A-Z0-9_]*=\S+\s+)*git(?:\s+-[^\s]+(?:\s+\S+)?)*\s+commit(?:\s|$)/.test(seg)) continue;
    if (/\bcommit\b[^;|&]*\s(?:--help|-h)\b/.test(seg)) continue;
    return true;
  }
  return false;
}

function hasDocSkillInvocation(invoked: Set<string>): boolean {
  for (const s of invoked) {
    if (s.split(":").pop() === "documentation") return true;
  }
  return false;
}

async function readJsonStdin(): Promise<Record<string, unknown>> {
  try {
    return JSON.parse(await Bun.stdin.text()) as Record<string, unknown>;
  } catch {
    return {};
  }
}

main().catch((e) => {
  process.stderr.write(`pre-commit-doc-check error: ${e?.message ?? e}\n`);
  process.exit(0);
});
