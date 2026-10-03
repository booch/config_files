import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { type ParseArgsConfig, parseArgs } from "node:util";
import { approveSession } from "./approve";
import { buildBriefing } from "./briefing";
import { closeSession } from "./close";
import { CONFIG_TEMPLATE, configPath } from "./config";
import { ChiefError, type Context } from "./context";
import { DEFAULT_RECENT, digestSession } from "./digest";
import { readTextIfExists } from "./files";
import { appendJournal } from "./journal";
import {
    AUTONOMIES,
    findSession,
    HARNESSES,
    isActive,
    loadRegistry,
    type SessionRecord,
    STATES,
} from "./registry";
import { reportState, reportStopped } from "./report";
import { spawnSession } from "./spawn";
import { minutesBetween } from "./time";
import { markReviewed, unreviewedUpdates } from "./updates";

interface CommandResult {
    output: string;
}

type Command = (ctx: Context, args: string[]) => Promise<CommandResult>;

export const USAGE = `usage: chief <command> [options]

  init                                   create the state directory
  list [--all] [--json]                  sessions in flight
  status <session>                       one session's record
  note <text…>                           append to the journal
  close <session> [--abandon] [--summary <text>]
  spawn --goal <text> [--slug s] [--repo dir] [--harness claude] [--model m] [--effort e] [--autonomy auto|checkpointed]
  report <session> --state <state> [--waiting-on <checkpoint>] [--summary <text>|-]
  report <session> --stopped             (Stop hook; reads hook JSON on stdin)
  approve <session> [message…]           release a waiting worker
  digest <session> [--recent N]          summarize the worker's transcript
  updates [--mark-reviewed [--task name]]  unreviewed scheduled-task reports
  briefing                               everything a session start needs, as JSON`;

// Workers pass summaries on stdin through a quoted heredoc, so their shell expands nothing in them.
const SUMMARY_FROM_STDIN = "-";

const json = (value: unknown): CommandResult => ({ output: JSON.stringify(value, null, 2) });

const COMMANDS: Record<string, Command> = {
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
        const summaryFromStdin = values.summary === SUMMARY_FROM_STDIN;
        if (values.stopped && summaryFromStdin) {
            throw usage("--summary - cannot be used with --stopped; both read stdin");
        }
        if (values.stopped) return json(await reportStopped(ctx, ref, await ctx.stdin()));
        if (!values.state) throw usage("report needs --state or --stopped");
        return json(
            await reportState(ctx, ref, {
                state: oneOf(STATES, values.state, "state"),
                waitingOn: values["waiting-on"],
                summary: summaryFromStdin ? await ctx.stdin() : values.summary,
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
    approve: async (ctx, args) => {
        const ref = requirePositional(args, 0, "session");
        const message = args.slice(1).join(" ");
        // The message is claude's last argument, so a leading "-" would make it a flag.
        if (message.startsWith("-")) throw usage('approve message must not start with "-"');
        return json(await approveSession(ctx, ref, message || undefined));
    },
    updates: async (ctx, args) => {
        const { values } = parse(args, {
            "mark-reviewed": { type: "boolean" },
            task: { type: "string" },
        });
        if (values["mark-reviewed"]) {
            return { output: `Marked ${await markReviewed(ctx, values.task)} reviewed.` };
        }
        return json(await unreviewedUpdates(ctx));
    },
    briefing: async (ctx) => json(await buildBriefing(ctx)),
    digest: async (ctx, args) => {
        const { values, positionals } = parse(args, {
            recent: { type: "string", default: String(DEFAULT_RECENT) },
        });
        return json(
            await digestSession(
                ctx,
                requirePositional(positionals, 0, "session"),
                Number(values.recent),
            ),
        );
    },
};

function oneOf<T extends string>(allowed: readonly T[], value: string, name: string): T {
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

async function initHome(ctx: Context): Promise<void> {
    await Promise.all(
        ["journal", "hooks"].map((dir) => mkdir(join(ctx.home, dir), { recursive: true })),
    );
    if ((await readTextIfExists(configPath(ctx))) === null) {
        await writeFile(configPath(ctx), CONFIG_TEMPLATE);
    }
}

function describeLine(ctx: Context, s: SessionRecord): string {
    const detail = s.state === "waiting" ? `waiting on ${s.waiting_on}` : s.state;
    const idle = minutesBetween(s.last_activity_at, ctx.now());
    return `${s.slug.padEnd(20)} ${detail.padEnd(28)} ${s.harness}/${s.model}  idle ${idle}m  ${s.summary ?? ""}`.trimEnd();
}

type Options = NonNullable<ParseArgsConfig["options"]>;

function parse<T extends Options>(args: string[], options: T) {
    try {
        return parseArgs({ args, options, allowPositionals: true, strict: true });
    } catch (error) {
        throw usage((error as Error).message);
    }
}

function requirePositional(positionals: string[], index: number, name: string): string {
    const value = positionals[index];
    if (!value) throw usage(`missing <${name}>`);
    return value;
}

function usage(problem: string): ChiefError {
    return new ChiefError(`${problem}\n\n${USAGE}`);
}
