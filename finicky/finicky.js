// See full docs at https://github.com/johnste/finicky/wiki/Configuration.

const Chrome = "Google Chrome";
const Firefox = "Firefox";
const Safari = "Safari";
const Vivaldi = "Vivaldi";
const Brave = "Brave Browser";
const BraveBeta = { name: "com.brave.browser.beta" };

// WARNING: You must get this from `defaults read "$HOME/Applications/Chrome Apps.localized/Google Meet.app/Contents/Info.plist" CrAppModeShortcutID`
const GoogleMeetShortcutID = "kjgfgldnnfoeklkmfkjfagphfepbbdan";
const GoogleMeet = ({ urlString }) => {
    finicky.log(urlString);
    return {
        name: Chrome,
        args: [
            `--app-id=${ GoogleMeetShortcutID }`,
            `--app-launch-url-for-shortcuts-menu-item="${ urlString }"`,
        ],
    };
};

const Zoom = "us.zoom.xos"; // From `defaults read "/Applications/zoom.us.app/Contents/Info" CFBundleIdentifier`

const DEFAULT = Vivaldi;

const WORK = Chrome;


module.exports = {
    defaultBrowser: DEFAULT,
    handlers: [
        {
            match: [
                "localhost:*/*",
                "*.debtbook.com/*",
                "gitlab.com/*",
                "*.datadoghq.com/*",
                "*.rollbar.com/*",
                "mailtrap.io/*",
                "docs.google.com/*",
                "debtbook.slack.com/*",
                "*.figma.com/*",
                "*.release.com/*",
                "*.debtbook.systems/*",
                "debtbook.atlassian.net/*",
                "*.greenhouse.io/*",
                "debtbook.1password.com/*",
                "my.tugboatlogic.com/*",
                "*.immersivelabs.com/*",
                "debtbook.awsapps.com/*",
                "debtbook.okta.com/*",
                "auth.nordlayer.com/*",
                "*.loom.com/*",
                "debtbook.awsapps.com/*"
            ],
            browser: WORK
        },
        {
            match: [
                "*.zoom.us/*",
            ],
            browser: Zoom
        },
        {
            match: [
                "meet.google.com/*",
            ],
            browser: GoogleMeet
        },
        {
            match: [
                "apple.com/*",
            ],
            browser: Safari
        },
        {
            match: [
                "google.com/*",
                "*.google.com/*",
            ],
            browser: Chrome
        },
    ],
    options: {
        hideIcon: true,
        checkForUpdate: true,
        logRequests: true
    },
};
