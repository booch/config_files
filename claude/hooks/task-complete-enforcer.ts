#!/usr/bin/env -S bun run
import { existsSync, statSync, readFileSync, mkdirSync, appendFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { loadTranscript, analyseTranscript, missingRequiredSkills, type Requirement } from "./lib/task-scope";

const TRANSCRIPT_FLUSH_WINDOW_MS = 250;

async function main(): Promise<void> {
  const input = await readJsonStdin();

  if (input.stop_hook_active === true) return;

  const transcriptPath = input.transcript_path as string | undefined;
  await waitForTranscriptFlush(transcriptPath);

  const scope = analyseTranscript(loadTranscript(transcriptPath));
  if (!scope.hasCompletionSignal) return;

  const missing = missingRequiredSkills(scope);
  if (missing.length === 0) return;

  const sessionId = typeof input.session_id === "string" ? input.session_id : undefined;
  if (reminderAlreadyDelivered(sessionId, missing)) return;

  const lines: string[] = [];
  if (scope.markerKind === "phrase") {
    lines.push(
      "(Detected via fallback completion phrase — prefer the explicit `[[task-complete]]` marker.)",
      "",
    );
  }
  lines.push("`[[task-complete]]` emitted but required skills were not invoked this task:");
  for (const m of missing) lines.push(`  - \`${m.skill}\` — ${m.reason}`);
  lines.push("", "Invoke each via the Skill tool — for example:");
  for (const m of missing) lines.push(`  Skill(skill: "${m.skill}")`);
  lines.push("", "Then re-emit `[[task-complete]]` on its own line at the end of your next message.");

  process.stdout.write(JSON.stringify({ decision: "block", reason: lines.join("\n") }));
}

async function waitForTranscriptFlush(path: string | undefined): Promise<void> {
  if (!path || !existsSync(path)) return;
  const ageMs = Date.now() - statSync(path).mtimeMs;
  if (ageMs < TRANSCRIPT_FLUSH_WINDOW_MS) {
    await new Promise((r) => setTimeout(r, TRANSCRIPT_FLUSH_WINDOW_MS - ageMs));
  }
}

// Block at most once per session per distinct missing-skill set. A blocking Stop re-invokes
// the assistant, but the condition only clears by acting (not by replying) — so without this
// guard the same block fires endlessly. Recording the fingerprint we just warned about lets
// later identical Stops pass through. `stop_hook_active` remains the backstop for runaway loops.
function reminderAlreadyDelivered(sessionId: string | undefined, missing: Requirement[]): boolean {
  const file = stateFile(sessionId);
  const fingerprint = missing.map((m) => m.skill).sort().join(",");
  try {
    const delivered = existsSync(file) ? readFileSync(file, "utf8").split("\n") : [];
    if (delivered.includes(fingerprint)) return true;
    mkdirSync(dirname(file), { recursive: true });
    appendFileSync(file, `${fingerprint}\n`);
  } catch {
    // Fail open: never silently drop a first reminder.
  }
  return false;
}

function stateFile(sessionId: string | undefined): string {
  const cacheHome = process.env.XDG_CACHE_HOME || join(homedir(), ".cache");
  const id = (sessionId || "unknown-session").replace(/[^A-Za-z0-9_-]/g, "_");
  return join(cacheHome, "claude-hooks", "task-complete-enforcer", `${id}.txt`);
}

async function readJsonStdin(): Promise<Record<string, unknown>> {
  try {
    return JSON.parse(await Bun.stdin.text()) as Record<string, unknown>;
  } catch {
    return {};
  }
}

main().catch((e) => {
  process.stderr.write(`task-complete-enforcer error: ${e?.message ?? e}\n`);
  process.exit(0);
});
