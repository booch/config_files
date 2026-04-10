#!/usr/bin/env bun
// Custom Claude Code status line — 3-4 lines
// Line 1: project + git + model + duration + cost
// Line 2: context bar + 5h usage + 7d usage
// Line 3: tokens
// Line 4: tool activity (only when tools are active)

const Clr = {
  reset: '\x1b[0m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[1;34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
} as const;

const SEPARATOR = ` ${Clr.dim}|${Clr.reset} `;
const COMMAND_PREVIEW_LENGTH = 30;

interface StdinData {
  cwd?: string;
  model?: { display_name?: string };
  context_window?: {
    context_window_size?: number;
    current_usage?: {
      input_tokens?: number;
      output_tokens?: number;
      cache_creation_input_tokens?: number;
      cache_read_input_tokens?: number;
    };
  };
  cost?: {
    total_cost_usd?: number;
    total_duration_ms?: number;
    total_api_duration_ms?: number;
  };
  rate_limits?: {
    five_hour?: { used_percentage?: number; resets_at?: number };
    seven_day?: { used_percentage?: number; resets_at?: number };
  };
  transcript_path?: string;
}

// --- Formatting helpers ---

function shortenModel(name: string): string {
  return name.replace(/^Claude\s+/i, '').replace(/\s*\(.*\)$/, '');
}

function fmtDuration(ms: number): string {
  const totalMinutes = Math.floor(ms / 60_000);
  if (totalMinutes < 1) return '<1m';
  if (totalMinutes < 60) return `${totalMinutes}m`;
  const hours = Math.floor(totalMinutes / 60);
  if (hours < 24) return `${hours}h${totalMinutes % 60}m`;
  const days = Math.floor(hours / 24);
  return `${days}d ${hours % 24}h`;
}

function fmtTokens(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1000) return `${Math.floor(n / 1000)}k`;
  return n.toString();
}

/** Format time remaining until reset. `resets_at` is Unix epoch seconds. */
function fmtResetTime(resets_at: number): string {
  const remainingSeconds = Math.max(0, resets_at - Date.now() / 1000);
  const minutes = Math.floor(remainingSeconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  if (days > 0) return `${days}d ${hours % 24}h`;
  if (hours > 0) return `${hours}h ${minutes % 60}m`;
  return `${minutes}m`;
}

function contextBar(pct: number, width = 10): string {
  const clamped = Math.max(0, Math.min(100, pct));
  const filled = Math.round((clamped / 100) * width);
  const empty = width - filled;
  const color = pct < 50 ? Clr.green : pct < 80 ? Clr.yellow : Clr.red;
  return `${color}${'█'.repeat(filled)}${'░'.repeat(empty)}${Clr.reset}`;
}

function usageColor(pct: number): string {
  if (pct >= 80) return Clr.red;
  if (pct >= 50) return Clr.yellow;
  return Clr.reset;
}

// --- Git ---

async function getGitInfo(cwd: string): Promise<string> {
  if (!cwd) return '';
  try {
    const proc = Bun.spawn(
      ['git', '--no-optional-locks', 'status', '--porcelain=v2', '--branch'],
      { cwd, stdout: 'pipe', stderr: 'ignore' },
    );
    const output = await new Response(proc.stdout).text();
    const code = await proc.exited;
    if (code !== 0) return '';

    let branch = '';
    let ahead = 0;
    let behind = 0;
    let dirty = false;

    const BRANCH_HEAD_PREFIX = '# branch.head ';
    const BRANCH_AB_PREFIX = '# branch.ab ';
    for (const line of output.split('\n')) {
      if (line.startsWith(BRANCH_HEAD_PREFIX)) branch = line.slice(BRANCH_HEAD_PREFIX.length);
      else if (line.startsWith(BRANCH_AB_PREFIX)) {
        const m = line.match(/\+(\d+) -(\d+)/);
        if (m) { ahead = +m[1]; behind = +m[2]; }
      } else if (/^[12?] /.test(line)) dirty = true;
    }
    if (!branch) return '';

    let label = `${Clr.magenta}git:(${Clr.reset}${Clr.cyan}${branch}${dirty ? '*' : ''}`;
    if (ahead > 0) label += ` ↑${ahead}`;
    if (behind > 0) label += ` ↓${behind}`;
    label += `${Clr.magenta})${Clr.reset}`;
    return label;
  } catch {
    return '';
  }
}

// --- Transcript parsing (lightweight) ---

interface CumulativeTokens {
  input: number;
  output: number;
  cacheCreation: number;
  cacheRead: number;
}

interface ToolActivity {
  running: Array<{ name: string; target: string }>;
  completed: Map<string, number>;
}

interface TranscriptData {
  tokens: CumulativeTokens | null;
  toolActivity: ToolActivity;
}

function partitionTools(
  toolUses: Map<string, { name: string; target: string }>,
  toolResults: Set<string>,
): ToolActivity {
  const running: Array<{ name: string; target: string }> = [];
  const completed = new Map<string, number>();

  for (const [id, tool] of toolUses) {
    if (toolResults.has(id)) {
      completed.set(tool.name, (completed.get(tool.name) ?? 0) + 1);
    } else {
      running.push({ name: tool.name, target: tool.target });
    }
  }

  return { running, completed };
}

const EMPTY_TRANSCRIPT: TranscriptData = Object.freeze({
  tokens: null,
  toolActivity: Object.freeze({ running: Object.freeze([]), completed: new Map() }),
}) as TranscriptData;

const MAX_TRANSCRIPT_BYTES = 100 * 1024 * 1024; // 100 MB safety limit

async function parseTranscript(transcriptPath: string): Promise<TranscriptData> {
  try {
    const file = Bun.file(transcriptPath);
    if (!(await file.exists())) return EMPTY_TRANSCRIPT;
    if (file.size > MAX_TRANSCRIPT_BYTES) return EMPTY_TRANSCRIPT;

    const text = await file.text();

    let input = 0;
    let output = 0;
    let cacheCreation = 0;
    let cacheRead = 0;
    const toolUses = new Map<string, { name: string; target: string }>();
    const toolResults = new Set<string>();

    for (const line of text.split('\n')) {
      if (!line.trim()) continue;
      try {
        const entry = JSON.parse(line);

        if (entry.type === 'assistant') {
          if (entry.message?.usage) {
            const u = entry.message.usage;
            input += u.input_tokens ?? 0;
            output += u.output_tokens ?? 0;
            cacheCreation += u.cache_creation_input_tokens ?? 0;
            cacheRead += u.cache_read_input_tokens ?? 0;
          }

          if (Array.isArray(entry.message?.content)) {
            for (const block of entry.message.content) {
              if (block.type === 'tool_use' && block.id && block.name) {
                const target = block.input?.file_path ?? block.input?.command?.slice(0, COMMAND_PREVIEW_LENGTH) ?? '';
                toolUses.set(block.id, { name: block.name, target });
              }
            }
          }
        }

        if (entry.type === 'tool_result' && entry.tool_use_id) {
          toolResults.add(entry.tool_use_id);
        }
      } catch {
        // skip malformed JSONL lines
      }
    }

    const totalTokens = input + output + cacheCreation + cacheRead;
    const tokens = totalTokens > 0 ? { input, output, cacheCreation, cacheRead } : null;

    return { tokens, toolActivity: partitionTools(toolUses, toolResults) };
  } catch {
    return EMPTY_TRANSCRIPT;
  }
}

function formatToolActivity(activity: ToolActivity): string {
  const parts: string[] = [];

  for (const tool of activity.running.slice(-3)) {
    const target = tool.target ? `: ${tool.target.split('/').pop()}` : '';
    parts.push(`${Clr.yellow}◐${Clr.reset} ${tool.name}${target}`);
  }
  for (const [name, count] of [...activity.completed].slice(-5)) {
    parts.push(`${Clr.green}✓${Clr.reset} ${name}${count > 1 ? ` ×${count}` : ''}`);
  }

  return parts.join(' │ ');
}

// --- Token extraction helpers ---

interface TokenBreakdown {
  input: number;
  output: number;
  cache: number;
  total: number;
}

function tokensFromContextWindow(data: StdinData): TokenBreakdown {
  const usage = data.context_window?.current_usage;
  const input = usage?.input_tokens ?? 0;
  const output = usage?.output_tokens ?? 0;
  const cache = (usage?.cache_creation_input_tokens ?? 0) + (usage?.cache_read_input_tokens ?? 0);
  return { input, output, cache, total: input + output + cache };
}

function tokensFromCumulative(cumulative: CumulativeTokens): TokenBreakdown {
  const cache = cumulative.cacheCreation + cumulative.cacheRead;
  return {
    input: cumulative.input,
    output: cumulative.output,
    cache,
    total: cumulative.input + cumulative.output + cache,
  };
}

// --- Line renderers ---

function fmtRateLimit(label: string, limit: { used_percentage?: number; resets_at?: number }): string | null {
  if (limit.used_percentage == null) return null;
  const pct = Math.round(limit.used_percentage);
  const reset = limit.resets_at ? ` (${fmtResetTime(limit.resets_at)} left)` : '';
  return `${usageColor(pct)}${label}: ${pct}%${reset}${Clr.reset}`;
}

async function renderProjectLine(data: StdinData): Promise<string> {
  const parts: string[] = [];

  const cwd = data.cwd ?? '';
  const home = process.env.HOME ?? '';
  const shortPath = home && cwd.startsWith(home) ? '~' + cwd.slice(home.length) : cwd;
  parts.push(`${Clr.blue}${shortPath}${Clr.reset}`);

  const git = await getGitInfo(cwd);
  if (git) parts.push(git);

  const model = shortenModel(data.model?.display_name ?? 'unknown');
  parts.push(`${Clr.magenta}[${model}]${Clr.reset}`);

  const duration = fmtDuration(data.cost?.total_duration_ms ?? 0);
  parts.push(`⏱️  ${duration}`);

  const cost = data.cost?.total_cost_usd ?? 0;
  parts.push(`${Clr.green}$${cost.toFixed(2)}${Clr.reset}`);

  return parts.join(SEPARATOR);
}

function renderContextAndUsage(data: StdinData): string {
  const ctxSize = data.context_window?.context_window_size ?? 0;
  const { total } = tokensFromContextWindow(data);
  const contextPct = ctxSize > 0 ? Math.round((total / ctxSize) * 100) : 0;

  const parts: string[] = [];
  parts.push(`${contextBar(contextPct)} ${contextPct}%`);

  const fiveHour = fmtRateLimit('5h', data.rate_limits?.five_hour ?? {});
  if (fiveHour) parts.push(fiveHour);

  const sevenDay = fmtRateLimit('7d', data.rate_limits?.seven_day ?? {});
  if (sevenDay) parts.push(sevenDay);

  return parts.join(SEPARATOR);
}

function renderTokenSummary(data: StdinData, cumulative?: CumulativeTokens | null): string | null {
  const tokens = cumulative
    ? tokensFromCumulative(cumulative)
    : tokensFromContextWindow(data);

  if (tokens.total === 0) return null;

  return `${Clr.dim}Tokens${Clr.reset} ${fmtTokens(tokens.total)} (in: ${fmtTokens(tokens.input)}, out: ${fmtTokens(tokens.output)}, cache: ${fmtTokens(tokens.cache)})`;
}

// --- Main ---

async function main() {
  let data: StdinData;
  try {
    data = JSON.parse(await Bun.stdin.text());
  } catch {
    return;
  }

  const transcript = data.transcript_path
    ? await parseTranscript(data.transcript_path)
    : null;

  const lines: string[] = [];
  lines.push(await renderProjectLine(data));
  lines.push(renderContextAndUsage(data));

  const tokenLine = renderTokenSummary(data, transcript?.tokens);
  if (tokenLine) lines.push(tokenLine);

  if (transcript) {
    const toolLine = formatToolActivity(transcript.toolActivity);
    if (toolLine) lines.push(toolLine);
  }

  process.stdout.write(lines.join('\n'));
}

main().catch(() => {});
