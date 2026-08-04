import {
  CustomEditor,
  SessionManager,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import type { KeybindingsManager } from "@earendil-works/pi-coding-agent";
import type { EditorTheme, TUI } from "@earendil-works/pi-tui";

const HISTORY_LIMIT = 100;

type HistoryItem = {
  text: string;
  timestamp: number;
};

function getTextContent(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";

  return content
    .filter(
      (part): part is { type: "text"; text: string } =>
        typeof part === "object" &&
        part !== null &&
        (part as { type?: unknown }).type === "text" &&
        typeof (part as { text?: unknown }).text === "string",
    )
    .map((part) => part.text)
    .join("\n");
}

export async function loadGlobalPromptHistory(): Promise<string[]> {
  const sessions = await SessionManager.listAll();
  const newestByText = new Map<string, HistoryItem>();

  for (const session of sessions) {
    try {
      const manager = SessionManager.open(session.path);
      for (const entry of manager.getEntries()) {
        if (entry.type !== "message" || entry.message.role !== "user") continue;

        const text = getTextContent(entry.message.content).trim();
        if (!text) continue;

        const parsedTimestamp = Date.parse(entry.timestamp);
        const timestamp = Number.isNaN(parsedTimestamp)
          ? session.modified.getTime()
          : parsedTimestamp;
        const previous = newestByText.get(text);
        if (!previous || timestamp > previous.timestamp) {
          newestByText.set(text, { text, timestamp });
        }
      }
    } catch {
      // Ignore malformed, deleted, or unreadable session files.
    }
  }

  return [...newestByText.values()]
    .sort((a, b) => b.timestamp - a.timestamp)
    .slice(0, HISTORY_LIMIT)
    .map((item) => item.text);
}

class GlobalHistoryEditor extends CustomEditor {
  private hydrationPromptsRemaining: number;

  constructor(
    tui: TUI,
    theme: EditorTheme,
    keybindings: KeybindingsManager,
    history: string[],
    hydrationPromptCount: number,
  ) {
    super(tui, theme, keybindings);
    this.hydrationPromptsRemaining = hydrationPromptCount;

    // Editor.addToHistory() prepends, so load oldest first to keep newest at index 0.
    for (const text of history.toReversed()) super.addToHistory(text);
  }

  override addToHistory(text: string): void {
    // Pi adds current-session prompts while rendering the initial transcript.
    // They are already present in the globally sorted history.
    if (this.hydrationPromptsRemaining > 0) {
      this.hydrationPromptsRemaining--;
      return;
    }
    super.addToHistory(text);
  }
}

export default function globalPromptHistory(pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    try {
      const history = await loadGlobalPromptHistory();
      const hydrationPromptCount = ctx.sessionManager
        .buildContextEntries()
        .filter(
          (entry) =>
            entry.type === "message" &&
            entry.message.role === "user" &&
            getTextContent(entry.message.content).length > 0,
        ).length;
      ctx.ui.setEditorComponent(
        (tui, theme, keybindings) =>
          new GlobalHistoryEditor(
            tui,
            theme,
            keybindings,
            history,
            hydrationPromptCount,
          ),
      );
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      ctx.ui.notify(`Could not load global prompt history: ${message}`, "warning");
    }
  });
}
