#!/opt/homebrew/bin/python3
"""Claude Code status line. Run `statusline.py --help` to print this guide.

HOW TO READ IT

  ~/Work/juno  CLOUDENG-3862-rails7.2 ✓  +585 −41  Opus 5.5  3.17
  10% ■□□□□□□□□□ 96k/1M  42 1.2M ↑19k ↓15k 98%   4.4M ↑134k ↓78k 97%   4.4M ↑134k ↓78k 97%

Line 1 — where you are
  ~/Work/juno     Current directory, spelled the way your shell's pwd
                  shows it (symlinks kept). Paths over 40 characters show
                  only their last two parts: …/parent/dir.
  <branch> ✓ / ●  Git branch: ✓ clean, ● uncommitted or untracked changes.
                  Shows a short commit hash when detached; hidden outside
                  a git repo.
  +585 −41        Lines Claude added / removed today with Edit and Write,
                  across all sessions and subagents (a new file counts as
                  all added). Edits you make yourself are not counted.
  Opus 5.5        Model in use.
  3.17           This session's estimated cost in US dollars.

Line 2 — context, then three token groups: this session ( prompts), day (), week ()
  10% ■□□□□□□□□□ 96k/1M
                  Context window: the % and bar are how full it is (green
                  under 60%, orange 60–80%, red 80% and up); then tokens
                  now in context / the window size. Both come straight from
                  Claude Code. Shows —% before the first response and right
                  after /compact.
  42 1.2M …      This session (the group right after the context window).
                  42 is how many prompts you've submitted: everything
                  typed in the prompt box, including slash commands and
                  messages sent while Claude is working. Then the tokens
                  of every API call since the session started, including
                  its subagents, even from before this week. Shows —
                  before the session's first response.
   4.4M ↑134k …  Today since 00:00 local time, all projects and sessions.
   4.4M ↑134k …  This week, since the later of Monday 00:00 local time and
                  the weekly usage-limit renewal. The renewal time is only
                  sent on some plans; without it the week starts Monday.

  Each token group is: bold total of all four token types, then —
    ↑ cache write  input tokens written to the prompt cache
    ↓ output       output tokens, including thinking
     cache hits   share of input served from the prompt cache: cache reads
                   / (input + cache writes + cache reads). Cache reads are
                   in the bold total, and usually most of it. A low rate
                   means the cache was cold: a new session, /compact, over
                   an hour idle, a model switch, or a new subagent.
  The total also includes uncached input, which isn't shown: Claude Code
  caches nearly everything it sends, leaving about 2 uncached tokens per
  API call. k = thousand, M = million, B = billion.

  In narrow terminals line 2 shrinks to fit: first the ↑ and  cache parts
  go (the bold totals still include them), then the context bar (the % and
  counts stay).

  "⚠ stats failed" on line 2 means the totals couldn't be computed; details
  are in ~/.cache/claude-statusline/error.log.

HOW IT WORKS

Claude Code pipes session JSON to this script on each assistant message,
permission-mode change, /compact, and every refreshInterval seconds (60, set
in ~/.claude/settings.json). Model, cost, context, and directory come from
that JSON; the directory is re-spelled with $PWD's symlinks, and the context %
and window size are never inferred from the model id.

Totals walk ~/.claude/projects/**/*.jsonl (subagent transcripts included)
incrementally: per-file byte offsets are cached in
~/.cache/claude-statusline/state.json, API calls are deduped by message.id
(each id is written once per content block, and usage only grows while
streaming, so the per-field max is the final value), and only records since
Monday 00:00 local are kept, except that sessions active this week keep
their whole history for the session total. The week's start uses
rate_limits.seven_day.resets_at - 7 days when that is later than Monday.

Every glyph comes from JetBrains Mono, Symbols Nerd Font, or Ghostty's own
sprites (check with `ghostty +show-face --string=X`): glyphs Ghostty borrows
from fallback fonts such as STIX Two Math overflow their cell and cover the
next character.

Fixture tests: /opt/homebrew/bin/python3 ~/.claude/statusline_test.py
"""
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import traceback
from datetime import datetime, timedelta

HOME = os.path.expanduser("~")
PROJECTS = os.path.join(HOME, ".claude", "projects")
STATE_DIR = os.path.join(HOME, ".cache", "claude-statusline")
STATE_FILE = os.path.join(STATE_DIR, "state.json")
ERROR_LOG = os.path.join(STATE_DIR, "error.log")
HISTORY = os.path.join(HOME, ".claude", "history.jsonl")
STATE_VERSION = 2
WEEK = 7 * 86400
USAGE_KEYS = ("input_tokens", "output_tokens", "cache_creation_input_tokens", "cache_read_input_tokens")


# ── presentation ────────────────────────────────────────────────────────────
def rgb(h):
    return "\033[38;2;%d;%d;%dm" % tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


R, B, D = "\033[0m", "\033[1m", "\033[2m"
MODEL, DIR, BRANCH = rgb("#6a1b9a"), rgb("#0d47a1"), rgb("#6d4c41")
DIRTY, COST, GRAY = rgb("#d84315"), rgb("#15803d"), rgb("#9e9e9e")
OUT, CW, HIT = rgb("#3949ab"), rgb("#8e24aa"), rgb("#1b7f4c")  # output, cache write, hit rate
OK, WARN, BAD = rgb("#2e7d32"), rgb("#ef6c00"), rgb("#c62828")
ADD, DEL, LBL = rgb("#2e7d32"), rgb("#c62828"), rgb("#546e7a")

# Nerd Font: fa-dollar, oct-sun, oct-moon, fa-recycle, oct-comment
I_COST, I_DAY, I_WEEK, I_HIT, I_PROMPTS = "\uf155", "\uf522", "\uf4ee", "\uf1b8", "\uf41f"
SEPARATOR = "  "
BAR_FULL, BAR_EMPTY = "■", "□"  # JetBrains Mono; ▰▱ would come from fallback fonts
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def fmt(n):
    n = int(n or 0)
    if n < 1000:
        return str(n)
    for div, suffix in ((1e3, "k"), (1e6, "M"), (1e9, "B")):
        v = n / div
        if v < 9.95:
            return f"{v:.1f}".rstrip("0").rstrip(".") + suffix
        if v < 999.5:
            return f"{v:.0f}{suffix}"
    return f"{n / 1e9:.0f}B"


def tokens(marker, t, cache=True):
    head = [f"{LBL}{marker}{R}"] if marker else []
    if t is None:
        return " ".join(head + [f"{D}—{R}"])
    i, o, w, r = t
    # Uncached input (i) is only the few tokens after Claude Code's last cache marker,
    # so it counts toward the total but isn't shown.
    parts = f"{OUT}↓{fmt(o)}{R}"
    if cache:
        parts = f"{CW}↑{fmt(w)}{R} {parts} {HIT}{I_HIT}{hit_rate(i, w, r)}{R}"
    return " ".join(head + [f"{B}{fmt(i + o + w + r)}{R}", parts])


def hit_rate(i, w, r):
    # Share of input served from the prompt cache, as Claude Code's prompt_cache.hit_ratio
    # defines it. Only a miss-free group shows 100%, so a small miss never rounds up to it.
    total = i + w + r
    if not total:
        return "—"
    return "100%" if r == total else f"{min(round(r * 100 / total), 99)}%"


def visible_width(parts):
    return len(ANSI.sub("", SEPARATOR.join(parts)))


def shell_spelling(path):
    # Claude Code reports the symlink-resolved path; $PWD keeps the shell's spelling
    # (e.g. ~/Work/juno for ~/repos/juno), so swap the resolved prefix back.
    pwd = os.environ.get("PWD")
    if not pwd:
        return path
    real_pwd, real_path = os.path.realpath(pwd), os.path.realpath(path)
    if real_path == real_pwd or real_path.startswith(real_pwd + os.sep):
        return pwd + real_path[len(real_pwd):]
    return path


def short_dir(path):
    if path == HOME or path.startswith(HOME + os.sep):
        path = "~" + path[len(HOME):]
    if len(path) > 40:
        path = "…/" + "/".join(path.split("/")[-2:])
    return path


def git_info(cwd):
    try:
        out = subprocess.run(
            ["git", "--no-optional-locks", "-C", cwd, "status", "--porcelain=v2", "--branch"],
            capture_output=True, text=True, timeout=1.5)
    except (OSError, subprocess.SubprocessError):
        return None
    if out.returncode != 0:
        return None
    branch, oid, dirty = None, "", False
    for line in out.stdout.splitlines():
        if line.startswith("# branch.head "):
            branch = line[len("# branch.head "):]
        elif line.startswith("# branch.oid "):
            oid = line[len("# branch.oid "):]
        elif line and not line.startswith("#"):
            dirty = True
    if branch == "(detached)":
        branch = oid[:8]
    if branch and len(branch) > 48:
        branch = branch[:47] + "…"
    return branch, dirty


def context_segment(ctx, cells=10):
    size = ctx.get("context_window_size")
    used = ctx.get("total_input_tokens")
    if not used and ctx.get("current_usage"):
        cu = ctx["current_usage"]
        used = sum(cu.get(k) or 0 for k in USAGE_KEYS if k != "output_tokens")
    pct = ctx.get("used_percentage")
    if pct is None and size and used:
        pct = used * 100.0 / size
    if pct is None:
        return f"{D}—%{' ' + BAR_EMPTY * cells if cells else ''}{R}"
    color = OK if pct < 60 else WARN if pct < 80 else BAD
    filled = max(0, min(cells, round(pct * cells / 100)))
    bar = f" {color}{BAR_FULL * filled}{GRAY}{BAR_EMPTY * (cells - filled)}{R}" if cells else ""
    absolute = f" {D}{fmt(used)}/{fmt(size)}{R}" if size else ""
    return f"{color}{pct:.0f}%{R}{bar}{absolute}"


# ── aggregation ─────────────────────────────────────────────────────────────
def parse_ts(s):
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()
    except (AttributeError, TypeError, ValueError):
        return None


def load_state(floor):
    try:
        with open(STATE_FILE) as f:
            state = json.load(f)
        if state.get("v") == STATE_VERSION and state.get("floor", floor) <= floor:
            return state
    except (OSError, ValueError):
        pass
    return {"v": STATE_VERSION, "floor": floor, "files": {}, "msgs": {}, "edits": {}, "sessions": {}}


def save_state(state):
    os.makedirs(STATE_DIR, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=STATE_DIR, prefix=".state.")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(state, f, separators=(",", ":"))
        os.replace(tmp, STATE_FILE)
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise
    # Claude Code kills a run that's still going when the next refresh starts,
    # which can orphan a temp file; runs in progress are younger than a minute.
    cutoff = time.time() - 60
    for name in os.listdir(STATE_DIR):
        if name.startswith(".state."):
            try:
                if os.path.getmtime(os.path.join(STATE_DIR, name)) < cutoff:
                    os.unlink(os.path.join(STATE_DIR, name))
            except OSError:
                pass


def session_of(path):
    # <project>/<sid>.jsonl, or <project>/<sid>/subagents/<agent>.jsonl
    parts = os.path.relpath(path, PROJECTS).split(os.sep)
    if len(parts) == 2:
        return parts[1][:-len(".jsonl")]
    return parts[1] if len(parts) > 2 else None


def edit_counts(result):
    if result.get("type") == "create":
        text = result.get("content") or ""
        return (text.count("\n") + (0 if text.endswith("\n") else 1) if text else 0), 0
    patch = result.get("structuredPatch")
    if not isinstance(patch, list):
        return None
    added = removed = 0
    for hunk in patch:
        for line in hunk.get("lines") or ():
            if line.startswith("+"):
                added += 1
            elif line.startswith("-"):
                removed += 1
    return added, removed


def merge_max(cur, vals):
    # Each message.id is written once per content block, and usage only grows
    # while streaming, so the per-field max is the final value.
    return [max(a, b) for a, b in zip(cur, vals)] if cur else vals


def ingest(line, sid, state, floor):
    try:
        rec = json.loads(line)
    except ValueError:
        return
    kind = rec.get("type")
    if kind not in ("assistant", "user"):
        return
    ts = parse_ts(rec.get("timestamp"))
    if ts is None:
        return

    if kind == "assistant":
        msg = rec.get("message") or {}
        mid, usage = msg.get("id"), msg.get("usage")
        if not mid or not isinstance(usage, dict):
            return
        vals = [int(usage.get(k) or 0) for k in USAGE_KEYS]
        if sid:  # session totals cover the whole session, not just this week
            calls = state["sessions"].setdefault(sid, {})
            calls[mid] = merge_max(calls.get(mid), vals)
        if ts >= floor:
            cur = state["msgs"].get(mid)
            state["msgs"][mid] = [min(cur[0], ts)] + merge_max(cur[1:], vals) if cur else [ts] + vals
        return

    result = rec.get("toolUseResult")
    if ts >= floor and isinstance(result, dict):
        counts = edit_counts(result)
        if counts and any(counts):
            content = (rec.get("message") or {}).get("content")
            key = rec.get("uuid")
            if isinstance(content, list) and content and isinstance(content[0], dict):
                key = content[0].get("tool_use_id") or key
            if key:
                state["edits"][key] = [ts, counts[0], counts[1]]


def scan(state, floor):
    found = []
    for root, _dirs, names in os.walk(PROJECTS):
        for name in names:
            if name.endswith(".jsonl"):
                path = os.path.join(root, name)
                try:
                    found.append((path, os.stat(path)))
                except OSError:
                    pass
    # Sessions touched this week. Their older files (say, a subagent that ran
    # last week) are still read, so session totals are complete.
    active = {session_of(path) for path, st in found if st.st_mtime >= floor}
    seen = {}
    for path, st in found:
        sid = session_of(path)
        if st.st_mtime < floor and sid not in active:
            continue
        entry = state["files"].get(path) or {}
        offset = entry.get("offset", 0)
        if entry.get("ino") != st.st_ino or offset > st.st_size:
            offset = 0
        if offset < st.st_size:
            with open(path, "rb") as f:
                f.seek(offset)
                data = f.read()
            end = data.rfind(b"\n")
            if end >= 0:
                for line in data[:end + 1].splitlines():
                    if line:
                        ingest(line, sid, state, floor)
                offset += end + 1
        seen[path] = {"ino": st.st_ino, "offset": offset}
    state["files"] = seen
    return active


def prune(state, floor, active):
    state["msgs"] = {k: v for k, v in state["msgs"].items() if v[0] >= floor}
    state["edits"] = {k: v for k, v in state["edits"].items() if v[0] >= floor}
    state["sessions"] = {k: v for k, v in state["sessions"].items() if k in active}
    state["floor"] = floor


def aggregates(data, now):
    today = datetime.fromtimestamp(now).date()
    day_start = datetime.combine(today, datetime.min.time()).timestamp()
    monday = datetime.combine(today - timedelta(days=today.weekday()), datetime.min.time()).timestamp()

    state = load_state(monday)
    resets_at = ((data.get("rate_limits") or {}).get("seven_day") or {}).get("resets_at")
    if resets_at:
        state["seven_day_resets_at"] = resets_at
    resets_at = state.get("seven_day_resets_at")
    week_start = monday
    if resets_at and resets_at > now:
        week_start = max(monday, resets_at - WEEK)

    active = scan(state, monday)
    prune(state, monday, active)

    calls = state["sessions"].get(data.get("session_id"))
    session = [sum(c[k] for c in calls.values()) for k in range(4)] if calls else None
    day, week = [0] * 4, [0] * 4
    for ts, *vals in state["msgs"].values():
        if ts >= week_start:
            week = [a + b for a, b in zip(week, vals)]
        if ts >= day_start:
            day = [a + b for a, b in zip(day, vals)]
    added = sum(e[1] for e in state["edits"].values() if e[0] >= day_start)
    removed = sum(e[2] for e in state["edits"].values() if e[0] >= day_start)

    save_state(state)
    return session, day, week, (added, removed)


def prompt_count(sid):
    # Claude Code's prompt history: one line per submission typed in the prompt
    # box, including slash commands and messages sent while Claude is working.
    if not sid:
        return None
    needle, count = sid.encode(), 0
    try:
        with open(HISTORY, "rb") as f:
            for line in f:
                if needle in line:  # cheap filter; confirm on the parsed field
                    try:
                        count += json.loads(line).get("sessionId") == sid
                    except ValueError:
                        pass
    except OSError:
        return None
    return count


def log_error():
    # A persistent failure repeats on every refresh, so start over past ~100 KB.
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        big = os.path.exists(ERROR_LOG) and os.path.getsize(ERROR_LOG) > 100_000
        with open(ERROR_LOG, "w" if big else "a") as f:
            f.write(f"--- {datetime.now().isoformat()}\n{traceback.format_exc()}")
    except OSError:
        pass


# ── main ────────────────────────────────────────────────────────────────────
def main():
    if {"-h", "--help"} & set(sys.argv[1:]):
        print(__doc__)
        return
    try:
        data = json.loads(sys.stdin.read() or "{}")
    except ValueError:
        data = {}
    now = time.time()
    cwd = (data.get("workspace") or {}).get("current_dir") or data.get("cwd") or os.getcwd()

    model = f"{MODEL}{B}{(data.get('model') or {}).get('display_name') or '?'}{R}"
    line1 = [f"{DIR}{B}{short_dir(shell_spelling(cwd))}{R}"]
    git = git_info(cwd)
    if git and git[0]:
        flag = f"{DIRTY}●{R}" if git[1] else f"{OK}✓{R}"
        line1.append(f"{BRANCH}{B}{git[0]}{R} {flag}")
    usd = (data.get("cost") or {}).get("total_cost_usd")
    cost = f"{COST}{I_COST}{usd or 0:.2f}{R}"

    ctx = data.get("context_window") or {}
    # Claude Code sets COLUMNS; the 2-column margin keeps line 2 from ever wrapping.
    columns = int(os.environ.get("COLUMNS") or 0) or 120
    try:
        session, day, week, (added, removed) = aggregates(data, now)
        line1 += [f"{ADD}+{added}{R} {DEL}−{removed}{R}", model, cost]
        # The session group is led by its prompt count instead of an icon of its own.
        prompts = prompt_count(data.get("session_id"))
        groups = ((f"{I_PROMPTS}{prompts}" if prompts else None, session), (I_DAY, day), (I_WEEK, week))
        # Shrink until it fits: drop the cache parts (totals still include them), then the context bar.
        for cells, cache in ((10, True), (10, False), (0, False)):
            line2 = [context_segment(ctx, cells)] + [tokens(marker, t, cache) for marker, t in groups]
            if visible_width(line2) <= columns - 2:
                break
    except Exception:
        log_error()
        line1 += [model, cost]
        line2 = [context_segment(ctx), f"{BAD}⚠ stats failed — see {ERROR_LOG.replace(HOME, '~')}{R}"]

    print("\n".join(SEPARATOR.join(parts) for parts in (line1, line2)))


if __name__ == "__main__":
    main()
