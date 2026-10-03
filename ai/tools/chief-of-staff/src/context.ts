import { homedir } from "node:os";
import { join, resolve } from "node:path";

export interface RunResult {
    exitCode: number;
    stdout: string;
    stderr: string;
}

export type Runner = (argv: string[], options?: { cwd?: string }) => Promise<RunResult>;

// Everything the CLI touches outside its own memory. Tests swap in temp dirs, a fixed clock,
// and a runner that fakes `claude`.
export interface Context {
    home: string; // Chief's state directory
    claudeHome: string; // ~/.claude: transcripts and the quota file
    worktreeRoot: string; // parent of spawned worktrees
    cliPath: string; // absolute path to cli.ts, for commands written into hooks and prompts
    now: () => Date;
    run: Runner;
    stdin: () => Promise<string>;
}

export class ChiefError extends Error {}

export const realRunner: Runner = async (argv, options = {}) => {
    const proc = Bun.spawn(argv, {
        cwd: options.cwd,
        stdin: "ignore",
        stdout: "pipe",
        stderr: "pipe",
    });
    const [stdout, stderr, exitCode] = await Promise.all([
        new Response(proc.stdout).text(),
        new Response(proc.stderr).text(),
        proc.exited,
    ]);
    return { exitCode, stdout, stderr };
};

export function defaultContext(env: Record<string, string | undefined> = process.env): Context {
    const dataHome = env.XDG_DATA_HOME ?? join(homedir(), ".local/share");
    return {
        home: env.CHIEF_HOME ?? join(dataHome, "ai/chief-of-staff"),
        claudeHome: env.CLAUDE_CONFIG_DIR ?? join(homedir(), ".claude"),
        worktreeRoot: env.CHIEF_WORKTREE_ROOT ?? join(dataHome, "ai/worktrees"),
        cliPath: resolve(import.meta.dir, "cli.ts"),
        now: () => new Date(),
        run: realRunner,
        stdin: () => Bun.stdin.text(),
    };
}
