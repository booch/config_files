import type { Plugin } from "@opencode-ai/plugin"

export const AnnounceSkill: Plugin = async () => ({
  "tool.execute.before": async (input, output) => {
    if (input.tool !== "skill") return
    const name = output.args?.name ?? "<unknown>"
    if (process.env.OPENCODE_ANNOUNCE_SKILLS === "1") {
      console.log(`[skill] loading: ${name}`)
    }
  },
})
