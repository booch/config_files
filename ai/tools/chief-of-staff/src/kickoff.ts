import type { Autonomy } from "./registry";

export const KICKOFF_FILE = ".chief-kickoff.md";
interface KickoffInput {
    id: string;
    slug: string;
    goal: string;
    autonomy: Autonomy;
    chief: string; // shell command that runs the chief CLI
}

export function kickoffPrompt({ id, slug, goal, autonomy, chief }: KickoffInput): string {
    const report = `${chief} report ${id}`;
    return `# Chief of Staff kickoff: ${slug}

You are a worker session spawned by the Chief of Staff. Session id: \`${id}\`.

## Goal

${goal}

## How to work

You are in a dedicated git worktree on branch \`${slug}\`. Follow the repository's
AGENTS.md / CLAUDE.md for workflow, testing, linting, reviews, and commit style.

The human has authorized you to **continue without prompting**, as defined in
AGENTS.md, **except** for the items under "Always escalate". Commit locally as you go.

${autonomy === "checkpointed" ? checkpointsSection(report) : ""}## Always escalate

Stop and report \`waiting\` before any of these. Do not do them yourself.

- Test and spec design for non-trivial work (\`--waiting-on approve-tests\`)
- git push, or opening a pull request (\`--waiting-on approve-push\`)
- Any destructive operation: deleting files outside this task, rewriting history, dropping data (\`--waiting-on approve-destructive\`)
- A change of scope from the goal above (\`--waiting-on approve-scope\`)

## Reporting status

Report with these exact commands, then end your turn:

- Need a human decision: \`${report} --state waiting --waiting-on <checkpoint> --summary "<one line>"\`
- Blocked by something outside your control: \`${report} --state blocked --summary "<what and why>"\`
- Finished: \`${report} --state done --summary "<what changed; branch ${slug}>"\`

If you stop without reporting, Chief assumes you are waiting on the human.
`;
}

const checkpointsSection = (report: string) => `## Checkpoints

This session is **checkpointed**. Also stop and report \`waiting\` at each of these:

1. After writing a plan, before any code: \`${report} --state waiting --waiting-on approve-plan --summary "<plan in one line>"\`
2. After writing tests, before implementing: \`${report} --state waiting --waiting-on approve-tests --summary "<what the tests specify>"\`

`;
