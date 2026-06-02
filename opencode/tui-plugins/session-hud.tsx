/** @jsxImportSource @opentui/solid */
import type { TuiPluginModule, TuiPluginApi, TuiPromptRef } from "@opencode-ai/plugin/tui"
import type { Message, Provider } from "@opencode-ai/sdk/v2"

type AssistantMessage = Extract<Message, { role: "assistant" }>

type Totals = {
  input: number
  output: number
  reasoning: number
  cacheRead: number
  cacheWrite: number
  cost: number
}

type Segment = {
  text: string
  fg?: string
  bold?: boolean
}

const COLOR = {
  key: "#000000",
  muted: "#808080",
  success: "#7ddc8f",
  warning: "#f5a742",
  error: "#e06c75",
  path: "#56b6c2",
  cost: "#98c379",
} as const

const PREFERENCES = {
  theme: "opencode",
  sidebar: "hide",
  thinking_visibility: false,
  timestamps: "show",
  tool_details_visibility: false,
  assistant_metadata_visibility: true,
  scrollbar_visible: true,
  diff_wrap_mode: "word",
  animations_enabled: true,
  generic_tool_output_visibility: false,
} as const

const HOME_PLACEHOLDERS = {
  normal: ["Fix a TODO in the codebase", "What is the tech stack of this project?", "Fix broken tests"],
  shell: ["ls -la", "git status", "pwd"],
}

function assistantMessages(messages: ReadonlyArray<Message>): AssistantMessage[] {
  return messages.filter((message): message is AssistantMessage => message.role === "assistant")
}

function latestAssistant(messages: ReadonlyArray<Message>): AssistantMessage | undefined {
  return assistantMessages(messages).at(-1)
}

function requestTokens(message: AssistantMessage): number {
  return message.tokens.input + message.tokens.cache.read + message.tokens.cache.write
}

function sessionTotals(messages: ReadonlyArray<Message>): Totals {
  return assistantMessages(messages).reduce<Totals>(
    (totals, message) => ({
      input: totals.input + message.tokens.input,
      output: totals.output + message.tokens.output,
      reasoning: totals.reasoning + message.tokens.reasoning,
      cacheRead: totals.cacheRead + message.tokens.cache.read,
      cacheWrite: totals.cacheWrite + message.tokens.cache.write,
      cost: totals.cost + message.cost,
    }),
    { input: 0, output: 0, reasoning: 0, cacheRead: 0, cacheWrite: 0, cost: 0 },
  )
}

function formatNumber(value: number): string {
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}M`
  if (value >= 10_000) return `${Math.round(value / 1_000)}k`
  if (value >= 1_000) return `${(value / 1_000).toFixed(1)}k`
  return String(value)
}

function formatCost(value: number): string {
  if (value >= 1) return `$${value.toFixed(2)}`
  if (value > 0) return `$${value.toFixed(4)}`
  return "$0"
}

function separator(): string {
  return " | "
}

function part(text: string, fg?: string, bold = false): Segment {
  return { text, fg, bold }
}

function joinParts(groups: Segment[][]): Segment[] {
  return groups.flatMap((group, index) => (index === 0 ? group : [part(separator(), COLOR.muted), ...group]))
}

function muted(text: string): Segment[] {
  return [part(text, COLOR.muted)]
}

function pathSummary(api: TuiPluginApi): string {
  const directory = api.state.path.directory || process.cwd()
  const home = process.env.HOME
  const relative = home && directory.startsWith(home) ? `~${directory.slice(home.length)}` : directory
  const branch = api.state.vcs?.branch
  return branch ? `${relative}:${branch}` : relative
}

function modelLimit(providers: ReadonlyArray<Provider>, message: AssistantMessage | undefined): number | undefined {
  if (!message) return undefined
  return providers.find((provider) => provider.id === message.providerID)?.models[message.modelID]?.limit.context
}

function contextSummary(api: TuiPluginApi, message: AssistantMessage | undefined): Segment[] {
  if (!message) return muted("ctx n/a")
  const limit = modelLimit(api.state.provider, message)
  const used = requestTokens(message)
  if (!limit) return muted(`ctx ${formatNumber(used)}`)
  const percentage = Math.round((used / limit) * 100)
  const color = percentage >= 80 ? COLOR.error : percentage >= 50 ? COLOR.warning : COLOR.success
  return [
    part("ctx ", COLOR.muted),
    part(contextBar(percentage), color, true),
    part(` ${formatNumber(used)}/${formatNumber(limit)} `, COLOR.muted),
    part(`${percentage}%`, color),
  ]
}

function contextBar(percentage: number): string {
  const clamped = Math.max(0, Math.min(100, percentage))
  const width = 10
  const filled = Math.round((clamped / 100) * width)
  return `${"#".repeat(filled)}${"-".repeat(width - filled)}`
}

function statusParts(api: TuiPluginApi, sessionID: string): Segment[] {
  const status = api.state.session.status(sessionID)
  if (!status || status.type === "idle") return [part("idle", COLOR.success, true)]
  if (status.type === "busy") return [part("busy", COLOR.warning, true)]
  return [part(`retry ${status.attempt}`, COLOR.error, true)]
}

function persistPreferences(api: TuiPluginApi): void {
  if (api.theme.has(PREFERENCES.theme)) api.theme.set(PREFERENCES.theme)
  for (const [key, value] of Object.entries(PREFERENCES)) api.kv.set(key, value)
}

function Inline(props: { segments: Segment[] }) {
  return (
    <text wrapMode="none">
      {props.segments.map((segment) => (
        <span style={{ fg: segment.fg, bold: segment.bold }}>{segment.text}</span>
      ))}
    </text>
  )
}

function ShortcutHints() {
  return (
    <text wrapMode="none">
      <span style={{ fg: COLOR.key, bold: true }}>tab</span>
      <span style={{ fg: COLOR.muted }}> agents • </span>
      <span style={{ fg: COLOR.key, bold: true }}>ctrl+p</span>
      <span style={{ fg: COLOR.muted }}> commands • </span>
      <span style={{ fg: COLOR.key, bold: true }}>ctrl+space</span>
      <span style={{ fg: COLOR.muted }}> leader • </span>
      <span style={{ fg: COLOR.key, bold: true }}>leader b</span>
      <span style={{ fg: COLOR.muted }}> sidebar</span>
    </text>
  )
}

function SessionPrompt(props: {
  api: TuiPluginApi
  session_id: string
  visible?: boolean
  disabled?: boolean
  on_submit?: () => void
  ref?: (ref: TuiPromptRef | undefined) => void
}) {
  const api = props.api

  return (
    <box width="100%">
      <api.ui.Prompt
        sessionID={props.session_id}
        visible={props.visible}
        disabled={props.disabled}
        onSubmit={props.on_submit}
        ref={props.ref}
        right={<api.ui.Slot name="session_prompt_right" session_id={props.session_id} />}
      />
      <box
        position="absolute"
        right={0}
        bottom={0}
        paddingLeft={1}
        backgroundColor={api.theme.current.background}
        zIndex={10_000}
      >
        <ShortcutHints />
      </box>
    </box>
  )
}

function HomePrompt(props: { api: TuiPluginApi; ref?: (ref: TuiPromptRef | undefined) => void }) {
  const api = props.api

  return (
    <box width="100%">
      <api.ui.Prompt
        ref={props.ref}
        right={<api.ui.Slot name="home_prompt_right" />}
        placeholders={HOME_PLACEHOLDERS}
      />
      <box
        position="absolute"
        right={0}
        bottom={0}
        paddingLeft={1}
        backgroundColor={api.theme.current.background}
        zIndex={10_000}
      >
        <ShortcutHints />
      </box>
    </box>
  )
}

function compactSessionLine(api: TuiPluginApi, sessionID: string): Segment[] {
  const messages = api.state.session.messages(sessionID)
  const latest = latestAssistant(messages)
  const totals = sessionTotals(messages)
  return joinParts([
    [part(pathSummary(api), COLOR.path, true)],
    statusParts(api, sessionID),
    contextSummary(api, latest),
    [part(formatCost(totals.cost), COLOR.cost, true)],
  ])
}

const plugin: TuiPluginModule = {
  id: "session-hud",
  async tui(api) {
    persistPreferences(api)

    api.slots.register({
      order: 100,
      slots: {
        home_prompt(_ctx, props) {
          return <HomePrompt api={api} {...props} />
        },
        session_prompt(_ctx, props) {
          return <SessionPrompt api={api} {...props} />
        },
        session_prompt_right(_ctx, props) {
          return <Inline segments={compactSessionLine(api, props.session_id)} />
        },
      },
    })
  },
}

export default plugin
