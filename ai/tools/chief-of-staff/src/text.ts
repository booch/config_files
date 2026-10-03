import { homedir } from "node:os";
import { join } from "node:path";

export function oneLine(text: string): string {
    return text.replace(/\s+/g, " ").trim();
}

export function truncate(text: string, max: number): string {
    return text.length <= max ? text : `${text.slice(0, max - 1)}…`;
}

export function firstLine(text: string): string {
    return (
        text
            .split("\n")
            .map((line) => line.trim())
            .find(Boolean) ?? ""
    );
}

// For external input: undefined when the text is not JSON.
export function tryParseJson(text: string): unknown {
    try {
        return JSON.parse(text);
    } catch {
        return undefined;
    }
}

export function shellQuote(text: string): string {
    return `'${text.replaceAll("'", `'\\''`)}'`;
}

export function expandHome(path: string): string {
    return path.startsWith("~/") ? join(homedir(), path.slice(2)) : path;
}
