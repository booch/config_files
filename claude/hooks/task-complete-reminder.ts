#!/usr/bin/env -S bun run
import { loadTranscript, analyseTranscript } from "./lib/task-scope";

async function main(): Promise<void> {
  const input = await readJsonStdin();
  const transcriptPath: string | undefined = input.transcript_path;
  const entries = loadTranscript(transcriptPath);
  const scope = analyseTranscript(entries);

  if (scope.editWriteCount === 0) return;
  if (scope.hasCompletionSignal) return;

  process.stdout.write(
    "Reminder: when the task is fully complete, end your final message with `<task-complete/>` on its own line.",
  );
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
  process.stderr.write(`task-complete-reminder error: ${e?.message ?? e}\n`);
  process.exit(0);
});
