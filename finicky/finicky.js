// See full docs at https://github.com/johnste/finicky/wiki/Configuration-(v4).

// Identify browsers by app name (preferred in Finicky 4) or bundle ID.
// Bundle ID: `defaults read "/Applications/${APP_NAME}.app/Contents/Info" CFBundleIdentifier`
const Chrome = "Google Chrome";
const Firefox = "Firefox";
const Safari = "Safari";
const Vivaldi = "Vivaldi";
const Brave = "Brave Browser";
const VSCode = "Visual Studio Code";
const AppleMusic = "Music";
const Figma = "Figma";
const iTerm = "iTerm";
const Slack = "Slack";
const Discord = "Discord";
const GoogleMeet = "com.google.Chrome.app.Google Meet"; // Chrome PWA: no app-name form
const Obsidian = "Obsidian";
const Zoom = "zoom.us";

const DEFAULT = Chrome;
const WORK = Safari;


export default {
    defaultBrowser: DEFAULT,
    options: {
        hideIcon: false,
        checkForUpdates: true,
        logRequests: true,
    },
    handlers: [
        {
            browser: WORK,
            match: [
                "*.render.com/*", // Render - Fire Text Rescue
                "linkedin.com/*",
                "*.careers/*",
                "*.workday.com/*",
                "*.greenhouse.io/*",
                "localhost:*/*",
                "docs.google.com/*",
            ],
        },
        {
            browser: VSCode,
            match: (url) => url.protocol === "file:" || url.protocol === "vscode:",
        },
        {
            browser: Obsidian,
            match: (url) => url.protocol === "obsidian:",
        },
        {
            browser: Slack,
            match: (url) => url.protocol === "slack:",
        },
        {
            browser: Zoom,
            match: ["*.zoom.us/*"],
        },
        {
            browser: GoogleMeet,
            match: ["meet.google.com/*"],
        },
        {
            browser: Safari,
            match: ["apple.com/*"],
        },
        {
            browser: Chrome,
            match: ["google.com/*", "*.google.com/*"],
        },
        {
            browser: AppleMusic,
            match: ["music.apple.com*", "geo.music.apple.com*"],
            url: (url) => new URL(`itmss://${url.host}${url.pathname}${url.search}`),
        },
        {
            browser: Figma,
            match: "https://www.figma.com/file/*",
        },
        {
            browser: Discord,
            match: "https://discord.com/*",
            url: (url) => new URL(`discord://${url.host}${url.pathname}${url.search}`),
        },
    ],
};
