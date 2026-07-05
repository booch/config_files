#!/usr/bin/env -S bun run
// UserPromptSubmit hook: nudges the model to end its final message with
// `[[task-complete]]` once it has actually made edits, so the Stop-time
// task-complete-enforcer hook has a marker to check for.
import { readFileSync, existsSync } from "node:fs";

const MARKER_RE = /\[\[\s*task-complete\s*\]\]|<task-complete\s*\/?\s*>/i;
const EDIT_TOOLS = new Set(["apply_patch"]);

async function main(): Promise<void> {
  const input = await readJsonStdin();
  const entries = loadTranscript(input.transcript_path as string | undefined);
  const scope = analyseTranscript(entries);

  if (scope.editWriteCount === 0) return;
  if (scope.hasCompletionSignal) return;

  process.stdout.write(
    "Reminder: when the task is fully complete, end your final message with [[task-complete]] on its own line (as plain text, not in a code block or backticks).",
  );
}

function loadTranscript(path: string | undefined): any[] {
  if (!path || !existsSync(path)) return [];
  return readFileSync(path, "utf8")
    .split("\n")
    .filter(Boolean)
    .map((l) => {
      try {
        return JSON.parse(l);
      } catch {
        return null;
      }
    })
    .filter((x) => x !== null);
}

function analyseTranscript(entries: any[]): { editWriteCount: number; hasCompletionSignal: boolean } {
  const scopeStart = findScopeStart(entries);
  const inScope = entries.slice(scopeStart);

  let editWriteCount = 0;
  let lastAssistantText = "";
  for (const e of inScope) {
    if (e?.type !== "response_item") continue;
    const p = e.payload;
    if (p?.type === "function_call" && EDIT_TOOLS.has(p.name)) {
      editWriteCount++;
    } else if (p?.type === "message" && p.role === "assistant") {
      const text = (p.content ?? []).map((c: any) => c?.text ?? "").join("");
      if (text) lastAssistantText = text;
    }
  }

  return { editWriteCount, hasCompletionSignal: MARKER_RE.test(lastAssistantText) };
}

// A prior `[[task-complete]]` closes out the task it was emitted for; only
// activity after that point counts toward the *next* reminder.
function findScopeStart(entries: any[]): number {
  for (let i = entries.length - 2; i >= 0; i--) {
    const e = entries[i];
    if (e?.type !== "response_item" || e?.payload?.type !== "message" || e?.payload?.role !== "assistant") continue;
    const text = (e.payload.content ?? []).map((c: any) => c?.text ?? "").join("");
    if (MARKER_RE.test(text)) return i + 1;
  }
  return 0;
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
  process.stderr.write(`codex task-complete-reminder error: ${e?.message ?? e}\n`);
  process.exit(0);
});
