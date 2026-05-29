import type { Plugin } from "@opencode-ai/plugin"

export const EnforceCommitDocs: Plugin = async ({ client }) => ({
  "tool.execute.before": async (input, output) => {
    if (String(input.tool ?? "").toLowerCase() !== "bash") return
    const command = String((output.args as any)?.command ?? "")
    if (!isGitCommit(command)) return

    try {
      const result: any = await client.session.messages({ sessionID: input.sessionID })
      const messages = result?.data ?? result ?? []
      if (sessionInvokedDocSkill(Array.isArray(messages) ? messages : [])) return
      console.warn("[pre-commit-docs] `boochtek:documentation` skill not invoked this session — run it before committing.")
    } catch (e: any) {
      console.error("[pre-commit-docs] error fetching session messages:", e?.message ?? e)
    }
  },
})

function isGitCommit(cmd: string): boolean {
  for (const segRaw of cmd.split(/;|&&|\|\||\|/)) {
    const seg = segRaw.trim()
    if (!/^(?:[A-Z_][A-Z0-9_]*=\S+\s+)*git(?:\s+-[^\s]+(?:\s+\S+)?)*\s+commit(?:\s|$)/.test(seg)) continue
    if (/\bcommit\b[^;|&]*\s(?:--help|-h)\b/.test(seg)) continue
    return true
  }
  return false
}

function sessionInvokedDocSkill(messages: any[]): boolean {
  for (const m of messages) {
    for (const p of m?.parts ?? []) {
      if (p?.type !== "tool") continue
      if (String(p.tool ?? "").toLowerCase() !== "skill") continue
      const name = p.state?.input?.name ?? p.state?.input?.skill
      if (typeof name === "string" && name.split(":").pop() === "documentation") return true
    }
  }
  return false
}
