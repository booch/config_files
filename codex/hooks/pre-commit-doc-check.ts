#!/usr/bin/env -S bun run
import { readFileSync, existsSync } from "node:fs";

async function main(): Promise<void> {
  const input = await readJsonStdin();
  const ti = (input.tool_input ?? {}) as Record<string, unknown>;
  const cmd = String(ti.cmd ?? ti.command ?? "");
  if (!isGitCommit(cmd)) return;

  if (corpusMentionsDocSkill(loadTranscriptCorpus(input.transcript_path as string | undefined))) return;

  const reason = [
    "Documentation skill not invoked this task — run `$boochtek:documentation` (or `$documentation`) before committing.",
    "",
    `Blocked command: ${cmd.slice(0, 200)}`,
  ].join("\n");
  process.stdout.write(JSON.stringify({ decision: "block", reason }));
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

function loadTranscriptCorpus(path?: string): string {
  if (!path || !existsSync(path)) return "";
  const lines = readFileSync(path, "utf8").split("\n").filter(Boolean);
  const text: string[] = [];
  for (const line of lines) {
    try {
      const o = JSON.parse(line);
      if (o.type !== "response_item" || o.payload?.type !== "message") continue;
      for (const c of o.payload.content ?? []) {
        if (typeof c.text === "string") text.push(c.text);
      }
    } catch {
      // skip malformed lines
    }
  }
  return text.join("\n");
}

function corpusMentionsDocSkill(corpus: string): boolean {
  return /(?:\$|\/|@)(?:boochtek:)?documentation\b/i.test(corpus);
}

async function readJsonStdin(): Promise<Record<string, unknown>> {
  try {
    const chunks: Buffer[] = [];
    for await (const chunk of process.stdin) chunks.push(chunk as Buffer);
    return JSON.parse(Buffer.concat(chunks).toString("utf8")) as Record<string, unknown>;
  } catch {
    return {};
  }
}

main().catch((e) => {
  process.stderr.write(`codex pre-commit-doc-check error: ${e?.message ?? e}\n`);
  process.exit(0);
});
