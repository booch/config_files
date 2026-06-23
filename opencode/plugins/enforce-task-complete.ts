import type { Plugin } from "@opencode-ai/plugin"
import { existsSync, readFileSync, mkdirSync, appendFileSync } from "node:fs"
import { homedir } from "node:os"
import { dirname, join } from "node:path"

const MARKER_RE = /\[\[\s*task-complete\s*\]\]|<task-complete\s*\/?\s*>/i
const FALLBACK_PHRASES: RegExp[] = [
  /\btask\s+complete(?:d|ly)?\b/i,
  /\ball\s+done\b/i,
  /\bready\s+to\s+commit\b/i,
  /\ball\s+tests?\s+pass(?:ing)?\b/i,
  /\bwork\s+is\s+finished\b/i,
]
const EDIT_TOOLS = new Set(["edit", "write", "notebookedit"])
const RETRO = { edits: 3, files: 3, durationMs: 10 * 60 * 1000 }

type Scope = {
  hasCompletionSignal: boolean
  markerKind: "marker" | "phrase" | null
  editWriteCount: number
  filesModified: Set<string>
  durationMs: number
  skillsInvoked: Set<string>
}

export const EnforceTaskComplete: Plugin = async ({ client }) => ({
  event: async ({ event }) => {
    if (event.type !== "session.idle") return
    const sessionID = (event as any).properties?.sessionID
    if (!sessionID) return
    try {
      const result: any = await client.session.messages({ sessionID })
      const messages = result?.data ?? result ?? []
      const scope = analyseMessages(Array.isArray(messages) ? messages : [])
      if (!scope.hasCompletionSignal) return
      const missing = missingRequired(scope)
      if (missing.length === 0) return
      if (reminderAlreadyDelivered(sessionID, missing)) return
      warn(scope, missing)
    } catch (e: any) {
      console.error("[task-complete] error fetching session messages:", e?.message ?? e)
    }
  },
})

function analyseMessages(messages: any[]): Scope {
  const flatParts = flattenAssistantParts(messages)
  const scopeStart = findScopeStart(flatParts)
  const inScope = flatParts.slice(scopeStart)

  const lastText = lastTextOf(inScope)
  const hasMarker = MARKER_RE.test(lastText)
  const hasPhrase = !hasMarker && FALLBACK_PHRASES.some((re) => re.test(lastText))
  const markerKind: Scope["markerKind"] = hasMarker ? "marker" : hasPhrase ? "phrase" : null

  let editWriteCount = 0
  const filesModified = new Set<string>()
  const skillsInvoked = new Set<string>()
  const timestamps: number[] = []
  for (const p of inScope) {
    if (p.time?.start) timestamps.push(p.time.start)
    if (p.type !== "tool") continue
    const toolName = String(p.tool ?? "").toLowerCase()
    const input = p.state?.input ?? {}
    if (EDIT_TOOLS.has(toolName)) {
      editWriteCount++
      const fp = input.file_path ?? input.filePath ?? input.path
      if (typeof fp === "string" && fp) filesModified.add(fp)
    } else if (toolName === "skill") {
      const s = input.name ?? input.skill
      if (typeof s === "string" && s) skillsInvoked.add(s)
    }
  }
  const durationMs = timestamps.length >= 2 ? Math.max(...timestamps) - Math.min(...timestamps) : 0

  return {
    hasCompletionSignal: markerKind !== null,
    markerKind,
    editWriteCount,
    filesModified,
    durationMs,
    skillsInvoked,
  }
}

function flattenAssistantParts(messages: any[]): any[] {
  const out: any[] = []
  for (const m of messages) {
    const role = m?.info?.role ?? m?.role
    if (role !== "assistant") continue
    const parts = m?.parts ?? []
    for (const p of parts) out.push(p)
  }
  return out
}

function findScopeStart(parts: any[]): number {
  for (let i = parts.length - 2; i >= 0; i--) {
    const p = parts[i]
    if (p?.type === "text" && MARKER_RE.test(String(p.text ?? ""))) return i + 1
  }
  return 0
}

function lastTextOf(parts: any[]): string {
  for (let i = parts.length - 1; i >= 0; i--) {
    if (parts[i]?.type !== "text") continue
    const t = String(parts[i].text ?? "")
    if (t) return t
  }
  return ""
}

function missingRequired(scope: Scope): { skill: string; reason: string }[] {
  const req: { skill: string; reason: string }[] = []
  if (scope.editWriteCount > 0) {
    req.push({ skill: "pre-commit", reason: "Edit/Write ran this task" })
    req.push({ skill: "boochtek:documentation", reason: "Edit/Write ran this task" })
  }
  if (
    scope.editWriteCount >= RETRO.edits ||
    scope.filesModified.size >= RETRO.files ||
    scope.durationMs >= RETRO.durationMs
  ) {
    req.push({ skill: "retro", reason: "task crossed effort threshold" })
  }
  return req.filter((r) => !wasInvoked(r.skill, scope.skillsInvoked))
}

function wasInvoked(required: string, invoked: Set<string>): boolean {
  const bare = required.split(":").pop()
  for (const inv of invoked) {
    if (inv === required) return true
    if (inv.split(":").pop() === bare) return true
  }
  return false
}

function warn(scope: Scope, missing: { skill: string; reason: string }[]): void {
  const header = scope.markerKind === "phrase"
    ? "[task-complete] completion-phrase detected (prefer the `[[task-complete]]` marker); missing required skills:"
    : "[task-complete] `[[task-complete]]` emitted; missing required skills:"
  console.warn(header)
  for (const m of missing) console.warn(`  - ${m.skill} — ${m.reason}`)
  console.warn("Invoke each via the skill tool — for example:")
  for (const m of missing) console.warn(`  skill name: ${m.skill}`)
  console.warn("Then re-emit `[[task-complete]]`.")
}

// Warn at most once per session per distinct missing-skill set. session.idle fires repeatedly,
// so without this guard the same warning prints on every idle tick. Recording the fingerprint
// we just warned about lets later identical idles pass silently. The state path is shared with
// the Claude/Codex enforcers for cross-surface parity.
function reminderAlreadyDelivered(sessionId: string | undefined, missing: { skill: string }[]): boolean {
  const file = stateFile(sessionId)
  const fingerprint = missing.map((m) => m.skill).sort().join(",")
  try {
    const delivered = existsSync(file) ? readFileSync(file, "utf8").split("\n") : []
    if (delivered.includes(fingerprint)) return true
    mkdirSync(dirname(file), { recursive: true })
    appendFileSync(file, `${fingerprint}\n`)
  } catch {
    // Fail open: never silently drop a first warning.
  }
  return false
}

function stateFile(sessionId: string | undefined): string {
  const cacheHome = process.env.XDG_CACHE_HOME || join(homedir(), ".cache")
  const id = (sessionId || "unknown-session").replace(/[^A-Za-z0-9_-]/g, "_")
  return join(cacheHome, "claude-hooks", "task-complete-enforcer", `${id}.txt`)
}
