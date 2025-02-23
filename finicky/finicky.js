// See full docs at https://github.com/johnste/finicky/wiki/Configuration.

// Get bundle ID with `defaults read "/Applications/${APP_NAME}.app/Contents/Info" CFBundleIdentifier`
const Chrome = "com.google.Chrome";
const Firefox = "com.mozilla.Firefox";
const Safari = "com.apple.Safari";
const Vivaldi = "com.vivaldi.Vivaldi";
const Brave = "com.brave.Browser";
const VSCode = "com.microsoft.VSCode";
const AppleMusic = "com.apple.Music";
const Figma = "com.figma.Desktop";
const iTerm = "com.googlecode.iterm2";
const Slack = "com.tinyspeck.slackmacgap";
const Discord = "com.hnc.Discord";
const GoogleMeet = "com.google.Chrome.app.Google Meet";
const Obsidian = "md.obsidian";
const Zoom = "us.zoom.xos";

const DEFAULT = Chrome;
const WORK = Safari;


module.exports = {
    defaultBrowser: DEFAULT,
    options: {
        hideIcon: false,
        checkForUpdate: true,
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
            match: ({ url }) => url.protocol === "file" || url.protocol === "vscode",
        },
        {
            browser: Obsidian,
            match: ({ url }) => url.protocol === "obsidian",
        },
        {
            browser: Slack,
            match: ({ url }) => url.protocol === "slack",
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
            url: {
                protocol: "itmss",
            },
        },
        {
            browser: Figma,
            match: "https://www.figma.com/file/*",
        },
        {
            browser: Discord,
            match: "https://discord.com/*",
            url: { protocol: "discord" },
        },
    ],
    rewrite: [
        {
            match: "amazon.com/*",
            url: {
                host: "smile.amazon.com",
            },
        },
    ],
};
