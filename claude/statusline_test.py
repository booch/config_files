"""Fixture tests for ~/.claude/statusline.py.

Run: /opt/homebrew/bin/python3 ~/.claude/statusline_test.py

Builds throwaway transcripts in a temp dir; never touches ~/.claude/projects
or the real cache in ~/.cache/claude-statusline.
"""
import importlib.util, json, os, re, shutil, sys, tempfile, time
from datetime import datetime, date, time as dtime, timedelta, timezone

spec = importlib.util.spec_from_file_location("sl", os.path.expanduser("~/.claude/statusline.py"))
sl = importlib.util.module_from_spec(spec); spec.loader.exec_module(sl)

root = tempfile.mkdtemp(prefix="statusline-test-")
sl.PROJECTS = os.path.join(root, "projects")
sl.STATE_DIR = os.path.join(root, "state")
sl.STATE_FILE = os.path.join(sl.STATE_DIR, "state.json")
sl.ERROR_LOG = os.path.join(sl.STATE_DIR, "error.log")
proj = os.path.join(sl.PROJECTS, "-Users-x-repo")
os.makedirs(os.path.join(proj, "S1", "subagents"))

today = date.today(); monday = today - timedelta(days=today.weekday())
prev = monday - timedelta(days=1)  # last Sunday: before this week
# "Earlier this week" is yesterday, or early today when today is Monday.
early_day, early_h = (today - timedelta(days=1), 10) if today > monday else (today, 0)

def at(d, h, m=0):
    return datetime.combine(d, dtime(h, m)).astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")
def prompt(ts, text="hi"):
    return {"type": "user", "timestamp": ts, "message": {"role": "user", "content": text}}
def asst(ts, mid, u, side=False):
    return {"type": "assistant", "timestamp": ts, "isSidechain": side, "message": {"id": mid, "usage": dict(zip(sl.USAGE_KEYS, u))}}
def edit(ts, tid, lines):
    return {"type": "user", "timestamp": ts, "toolUseResult": {"structuredPatch": [{"lines": lines}]},
            "message": {"content": [{"type": "tool_result", "tool_use_id": tid}]}}
def create(ts, tid, text):
    return {"type": "user", "timestamp": ts, "isSidechain": True, "toolUseResult": {"type": "create", "content": text, "structuredPatch": []},
            "message": {"content": [{"type": "tool_result", "tool_use_id": tid}]}}
def write(path, recs, mode="w", tail=""):
    with open(path, mode) as f:
        f.write("".join(json.dumps(r) + "\n" for r in recs) + tail)

S1, S2 = os.path.join(proj, "S1.jsonl"), os.path.join(proj, "S2.jsonl")
write(S1, [
    prompt(at(prev, 20)), asst(at(prev, 20, 1), "m0", (1, 1, 1, 1)),                       # before Monday
    prompt(at(early_day, early_h)), asst(at(early_day, early_h, 1), "m1", (10, 100, 1000, 10000)),
    asst(at(early_day, early_h, 1), "m1", (10, 200, 1000, 10000)),                        # streamed dup, output grew
    prompt(at(today, 9)), asst(at(today, 9, 1), "m2", (1, 2, 3, 4)),
    edit(at(today, 9, 2), "t1", [" ctx", "-old", "+new1", "+new2", "+new3"]),
    asst(at(today, 9, 3), "m3", (5, 6, 7, 8)),
])
write(os.path.join(proj, "S1", "subagents", "agent-x.jsonl"),
      [asst(at(today, 9, 2), "m4", (100, 100, 100, 100), side=True), create(at(today, 9, 2), "t2", "a\nb\nc\nd\ne\n")])
write(S2, [prompt(at(today, 8)), asst(at(today, 8, 1), "m5", (1000, 0, 0, 0)),
           edit(at(today, 9, 2), "t1", [" ctx", "-old", "+new1", "+new2", "+new3"])])  # same tool_use_id: dedupe
# An S1 subagent that ran last week (file untouched since): still part of S1's session total.
SUB_OLD = os.path.join(proj, "S1", "subagents", "agent-old.jsonl")
write(SUB_OLD, [asst(at(prev, 21), "m7", (2, 2, 2, 2), side=True)])
# A session with no activity this week: not scanned at all.
S3 = os.path.join(proj, "S3.jsonl")
write(S3, [prompt(at(prev, 9)), asst(at(prev, 9, 1), "m8", (5, 5, 5, 5))])
before_monday = datetime.combine(monday, dtime(0)).timestamp() - 3600
for f in (SUB_OLD, S3):
    os.utime(f, (before_monday, before_monday))

now = datetime.now().timestamp()
fails = 0
def check(name, got, want):
    global fails
    ok = got == want; fails += not ok
    print(f"{'PASS' if ok else 'FAIL'}  {name}: {got}" + ("" if ok else f"  (want {want})"))

# ── aggregation ─────────────────────────────────────────────────────────────
WEEK = [1116, 308, 1110, 10112]                      # m1 (deduped by max) + m2..m5
DAY = [1106, 108, 110, 112] if today > monday else WEEK
session, day, week, lines = sl.aggregates({"session_id": "S1"}, now)
check("week excludes pre-Monday, dedupes m1 by max", week, WEEK)
check("day = today's calls across sessions + subagent", day, DAY)
check("session = all of S1 incl. pre-Monday call, subagents, last week's subagent file", session, [119, 311, 1113, 10115])
check("lines today: edit +3/-1, create +5, dup t1 once", lines, (8, 1))
check("second (cached) run is stable", sl.aggregates({"session_id": "S1"}, now)[:3], (session, day, week))
check("session inactive this week is not scanned", sl.aggregates({"session_id": "S3"}, now)[0], None)
check("unknown / not-yet-started session shows —", sl.aggregates({"session_id": "nope"}, now)[0], None)

# Incremental: a partial (unterminated) line isn't counted until it completes.
write(S1, [prompt(at(today, 11))], mode="a", tail=json.dumps(asst(at(today, 11, 1), "m6", (7, 7, 7, 7)))[:40])
check("partial line: session unchanged", sl.aggregates({"session_id": "S1"}, now)[0], [119, 311, 1113, 10115])
with open(S1, "rb+") as f:                                 # finish the partial line
    data = f.read(); cut = data.rfind(b"\n") + 1; f.seek(cut); f.truncate()
write(S1, [asst(at(today, 11, 1), "m6", (7, 7, 7, 7))], mode="a")
session, day, week, _ = sl.aggregates({"session_id": "S1"}, now)
check("completed line added to session", session, [126, 318, 1120, 10122])
check("day picked up m6 incrementally", day, [a + 7 for a in DAY])
check("S2 session is its own (not S1's)", sl.aggregates({"session_id": "S2"}, now)[0], [1000, 0, 0, 0])

# Weekly renewal later than Monday: the week starts at resets_at - 7d, just after m1.
renew = datetime.combine(early_day, dtime(early_h + 2)).timestamp() + 7 * 86400
WEEK_AFTER_RENEWAL = [1113, 115, 117, 119]           # m2..m6, without m1
week = sl.aggregates({"session_id": "S1", "rate_limits": {"seven_day": {"resets_at": renew}}}, now)[2]
check("renewal after Monday drops m1 from week", week, WEEK_AFTER_RENEWAL)
check("renewal remembered when a later payload lacks rate_limits", sl.aggregates({"session_id": "S1"}, now)[2], WEEK_AFTER_RENEWAL)

# ── housekeeping ────────────────────────────────────────────────────────────
orphan, inflight = (os.path.join(sl.STATE_DIR, n) for n in (".state.orphan", ".state.inflight"))
for f in (orphan, inflight):
    open(f, "w").close()
os.utime(orphan, (time.time() - 300,) * 2)
sl.save_state(json.load(open(sl.STATE_FILE)))
check("orphaned temp file swept, in-flight one kept", (os.path.exists(orphan), os.path.exists(inflight)), (False, True))

with open(sl.ERROR_LOG, "w") as f:
    f.write("x" * 150_000)
for n in (1, 2):
    try:
        raise RuntimeError(f"simulated {n}")
    except RuntimeError:
        sl.log_error()
log = open(sl.ERROR_LOG).read()
check("error log starts over past ~100 KB, then appends", (len(log) < 10_000, log.count("RuntimeError: simulated")), (True, 2))

# ── prompt count (history.jsonl) ────────────────────────────────────────────
sl.HISTORY = os.path.join(root, "history.jsonl")
write(sl.HISTORY, [{"sessionId": "S1", "display": "hi"}, {"sessionId": "S1", "display": "/model"},
                   {"sessionId": "S2", "display": "mentions S1 in the text"}, {"sessionId": "S1", "display": "mid-turn note"}])
check("prompt count per session; text mentioning another id doesn't count",
      [sl.prompt_count(s) for s in ("S1", "S2", "nope", None)], [3, 1, 0, None])
sl.HISTORY = os.path.join(root, "missing.jsonl")
check("missing history file: no count", sl.prompt_count("S1"), None)

# ── presentation ────────────────────────────────────────────────────────────
check("fmt", [sl.fmt(n) for n in (0, 999, 1000, 2140, 9960, 43158, 999_600, 1_393_151, 12_000_000, 180_400_000, 2_500_000_000)],
      ["0", "999", "1k", "2.1k", "10k", "43k", "1M", "1.4M", "12M", "180M", "2.5B"])
check("hit_rate", [sl.hit_rate(*c) for c in ((0, 0, 0), (2, 30_222, 27_017), (180, 228_153, 15_390_499), (0, 0, 5000), (1, 0, 99_999))],
      ["—", "47%", "99%", "100%", "99%"])
strip = lambda s: re.sub(r"\x1b\[[0-9;]*m", "", s)
check("context null", strip(sl.context_segment({"used_percentage": None, "current_usage": None, "context_window_size": 1000000})), "—% □□□□□□□□□□")
check("context 59% green / 60% orange / 80% red",
      [c in sl.context_segment({"used_percentage": p, "context_window_size": 1000000}) for p, c in ((59, sl.OK), (60, sl.WARN), (80, sl.BAD))],
      [True, True, True])
real = os.path.join(root, "real"); os.makedirs(os.path.join(real, "sub")); link = os.path.join(root, "link"); os.symlink(real, link)
os.environ["PWD"] = link
check("directory keeps the shell's symlinked spelling", sl.shell_spelling(os.path.realpath(real) + "/sub"), link + "/sub")
os.environ["PWD"] = "/"
check("unrelated $PWD falls back to the reported path", sl.shell_spelling(real), real)

shutil.rmtree(root)
print("ALL PASS" if not fails else f"{fails} FAILED"); sys.exit(1 if fails else 0)
