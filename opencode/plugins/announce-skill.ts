import type { Plugin } from "@opencode-ai/plugin"

export const AnnounceSkill: Plugin = async () => ({
  "tool.execute.before": async (input, output) => {
    if (input.tool !== "skill") return
    const name = output.args?.name ?? "<unknown>"
    console.log(`[skill] loading: ${name}`)
  },
})
