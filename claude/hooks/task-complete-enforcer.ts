#!/usr/bin/env -S bun run
import { loadTranscript, analyseTranscript, missingRequiredSkills } from "./lib/task-scope";

async function main(): Promise<void> {
  const input = await readJsonStdin();

  if (input.stop_hook_active === true) return;

  const transcriptPath: string | undefined = input.transcript_path;
  const entries = loadTranscript(transcriptPath);
  const scope = analyseTranscript(entries);

  if (!scope.hasCompletionSignal) return;

  const missing = missingRequiredSkills(scope);
  if (missing.length === 0) return;

  const lines = [
    "`<task-complete/>` emitted but required skills were not invoked this task:",
    ...missing.map((m) => `  - \`${m.skill}\` — ${m.reason}`),
    "",
    "Invoke each missing skill via the Skill tool, then re-emit `<task-complete/>` on its own line.",
  ];
  if (scope.markerKind === "phrase") {
    lines.unshift("(Detected via fallback completion phrase — prefer the explicit `<task-complete/>` marker.)", "");
  }

  process.stdout.write(JSON.stringify({ decision: "block", reason: lines.join("\n") }));
}

async function readJsonStdin(): Promise<Record<string, unknown>> {
  try {
    const raw = await Bun.stdin.text();
    return JSON.parse(raw) as Record<string, unknown>;
  } catch {
    return {};
  }
}

main().catch((e) => {
  process.stderr.write(`task-complete-enforcer error: ${e?.message ?? e}\n`);
  process.exit(0);
});
