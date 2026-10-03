import { mkdir } from "node:fs/promises";
import { join } from "node:path";
import { type ParseArgsConfig, parseArgs } from "node:util";
import { ChiefError, type Context } from "./context";
import { appendJournal } from "./journal";
import {
    AUTONOMIES,
    findSession,
    HARNESSES,
    isActive,
    loadRegistry,
    type SessionRecord,
    STATES,
    updateSession,
} from "./registry";
import { reportState, reportStopped } from "./report";
import { spawnSession } from "./spawn";
import { minutesBetween } from "./time";

export interface CommandResult {
    output: string;
}

type Command = (ctx: Context, args: string[]) => Promise<CommandResult>;

const USAGE = `usage: chief <command> [options]

  init                                   create the state directory
  list [--all] [--json]                  sessions in flight
  status <session>                       one session's record
  note <text…>                           append to the journal
  close <session> [--abandon] [--summary <text>]
  spawn --goal <text> [--slug s] [--repo dir] [--model m] [--effort e] [--autonomy auto|checkpointed]
  report <session> --state <state> [--waiting-on <checkpoint>] [--summary <text>]
  report <session> --stopped             (Stop hook; reads hook JSON on stdin)`;

const json = (value: unknown): CommandResult => ({ output: JSON.stringify(value, null, 2) });

export const COMMANDS: Record<string, Command> = {
    init: async (ctx) => {
        await initHome(ctx);
        return { output: `Initialized ${ctx.home}` };
    },
    list: async (ctx, args) => {
        const { values } = parse(args, { all: { type: "boolean" }, json: { type: "boolean" } });
        const sessions = (await loadRegistry(ctx)).filter((s) => values.all || isActive(s));
        if (values.json) return json(sessions);
        if (sessions.length === 0) return { output: "No sessions in flight." };
        return { output: sessions.map((s) => describeLine(ctx, s)).join("\n") };
    },
    status: async (ctx, args) =>
        json(await findSession(ctx, requirePositional(args, 0, "session"))),
    note: async (ctx, args) => {
        if (args.length === 0) throw usage("note needs text");
        await appendJournal(ctx, args.join(" "));
        return { output: "Noted." };
    },
    close: async (ctx, args) => {
        const { values, positionals } = parse(args, {
            abandon: { type: "boolean" },
            summary: { type: "string" },
        });
        const state = values.abandon ? "abandoned" : "done";
        return json(
            await closeSession(
                ctx,
                requirePositional(positionals, 0, "session"),
                state,
                values.summary,
            ),
        );
    },
    report: async (ctx, args) => {
        const { values, positionals } = parse(args, {
            state: { type: "string" },
            "waiting-on": { type: "string" },
            summary: { type: "string" },
            stopped: { type: "boolean" },
        });
        const ref = requirePositional(positionals, 0, "session");
        if (values.stopped) return json(await reportStopped(ctx, ref, await ctx.stdin()));
        if (!values.state) throw usage("report needs --state or --stopped");
        return json(
            await reportState(ctx, ref, {
                state: oneOf(STATES, values.state, "state"),
                waitingOn: values["waiting-on"],
                summary: values.summary,
            }),
        );
    },
    spawn: async (ctx, args) => {
        const { values } = parse(args, {
            goal: { type: "string" },
            slug: { type: "string" },
            repo: { type: "string", default: process.cwd() },
            harness: { type: "string", default: "claude" },
            model: { type: "string", default: "opus" },
            effort: { type: "string", default: "high" },
            autonomy: { type: "string", default: "auto" },
        });
        if (!values.goal) throw usage("spawn needs --goal");
        return json(
            await spawnSession(ctx, {
                goal: values.goal,
                slug: values.slug,
                repo: values.repo,
                harness: oneOf(HARNESSES, values.harness, "harness"),
                model: values.model,
                effort: values.effort,
                autonomy: oneOf(AUTONOMIES, values.autonomy, "autonomy"),
            }),
        );
    },
};

export function oneOf<T extends string>(allowed: readonly T[], value: string, name: string): T {
    if (!(allowed as readonly string[]).includes(value)) {
        throw usage(`--${name} must be one of: ${allowed.join(", ")}`);
    }
    return value as T;
}

export async function runCommand(ctx: Context, argv: string[]): Promise<CommandResult> {
    const [name, ...args] = argv;
    const command = name ? COMMANDS[name] : undefined;
    if (!command) throw usage(name ? `unknown command "${name}"` : "no command given");
    return command(ctx, args);
}

export async function initHome(ctx: Context): Promise<void> {
    await Promise.all(
        ["journal", "hooks"].map((dir) => mkdir(join(ctx.home, dir), { recursive: true })),
    );
}

export async function closeSession(
    ctx: Context,
    ref: string,
    state: "done" | "abandoned",
    summary?: string,
): Promise<SessionRecord> {
    const session = await findSession(ctx, ref);
    const closed = await updateSession(ctx, session.id, (s) => ({
        state,
        waiting_on: null,
        summary: summary ?? s.summary,
    }));
    await appendJournal(
        ctx,
        `closed \`${closed.slug}\` (${state})${summary ? `: ${summary}` : ""}`,
    );
    return closed;
}

function describeLine(ctx: Context, s: SessionRecord): string {
    const detail = s.state === "waiting" ? `waiting on ${s.waiting_on}` : s.state;
    const idle = minutesBetween(s.last_activity_at, ctx.now());
    return `${s.slug.padEnd(20)} ${detail.padEnd(28)} ${s.harness}/${s.model}  idle ${idle}m  ${s.summary ?? ""}`.trimEnd();
}

type Options = NonNullable<ParseArgsConfig["options"]>;

export function parse<T extends Options>(args: string[], options: T) {
    try {
        return parseArgs({ args, options, allowPositionals: true, strict: true });
    } catch (error) {
        throw usage((error as Error).message);
    }
}

export function requirePositional(positionals: string[], index: number, name: string): string {
    const value = positionals[index];
    if (!value) throw usage(`missing <${name}>`);
    return value;
}

export function usage(problem: string): ChiefError {
    return new ChiefError(`${problem}\n\n${USAGE}`);
}
