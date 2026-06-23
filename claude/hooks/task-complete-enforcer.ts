#!/usr/bin/env -S bun run
import { existsSync, statSync } from "node:fs";
import { loadTranscript, analyseTranscript, missingRequiredSkills } from "./lib/task-scope";

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
