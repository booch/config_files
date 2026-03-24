#!/usr/bin/env bun

// md2html — Convert Markdown to HTML with extensions.
//
// Usage:
//   md2html input.md              # Output HTML to stdout
//   md2html input.md -o out.html  # Write to file
//   md2html input.md --open       # Pipe to browser via `open -f -a Safari`
//   cat input.md | md2html        # Read from stdin
//
// Supports: CommonMark, GFM tables/task lists/autolinks/strikethrough,
//           ==highlight==, footnotes, heading anchors.

import markdownit from "markdown-it";
import markdownitMark from "markdown-it-mark";
import markdownitFootnote from "markdown-it-footnote";
import markdownitTaskLists from "markdown-it-task-lists";
import markdownitAnchor from "markdown-it-anchor";
import { readFileSync, writeFileSync, existsSync } from "fs";
import { execSync } from "child_process";

const md = markdownit({ html: true, linkify: true, typographer: true })
    .use(markdownitMark)
    .use(markdownitFootnote)
    .use(markdownitTaskLists, { enabled: true })
    .use(markdownitAnchor);

// Parse arguments.
const args = process.argv.slice(2);
let inputFile: string | null = null;
let outputFile: string | null = null;
let openInBrowser = false;
let cssFile: string | null = null;

for (let i = 0; i < args.length; i++) {
    if (args[i] === "-o" || args[i] === "--output") {
        outputFile = args[++i];
    } else if (args[i] === "--open") {
        openInBrowser = true;
    } else if (args[i] === "--css") {
        cssFile = args[++i];
    } else if (args[i] === "-h" || args[i] === "--help") {
        console.log(`Usage: md2html [input.md] [-o output.html] [--open] [--css style.css]
  input.md       Markdown file to convert (or read from stdin)
  -o, --output   Write HTML to file instead of stdout
  --open         Open result in Safari (no file saved)
  --css          Include a CSS file (inline <style> block)
  -h, --help     Show this help`);
        process.exit(0);
    } else {
        inputFile = args[i];
    }
}

// Read input.
let markdown: string;
if (inputFile) {
    markdown = readFileSync(inputFile, "utf-8");
} else {
    markdown = readFileSync("/dev/stdin", "utf-8");
}

// Convert.
const body = md.render(markdown);

// Default CSS — clean, minimal, print-friendly.
const defaultCss = `
body { max-width: 900px; margin: 2rem auto; padding: 0 1rem; font-family: -apple-system, system-ui, sans-serif; line-height: 1.6; color: #1a1a1a; }
h1 { border-bottom: 2px solid #ddd; padding-bottom: 0.3rem; }
h2 { border-bottom: 1px solid #eee; padding-bottom: 0.2rem; margin-top: 2rem; }
a { color: #0066cc; }
a[target="_blank"]::after { content: " ↗"; font-size: 0.7em; }
mark { background: #fff3b0; padding: 0.1em 0.2em; border-radius: 2px; }
img { max-width: 100%; height: auto; }
table { border-collapse: collapse; width: 100%; margin: 1rem 0; }
th, td { border: 1px solid #ddd; padding: 0.5rem; text-align: left; }
th { background: #f5f5f5; }
code { background: #f5f5f5; padding: 0.15em 0.3em; border-radius: 3px; font-size: 0.9em; }
pre code { display: block; padding: 1rem; overflow-x: auto; background: #f5f5f5; }
blockquote { border-left: 3px solid #ddd; margin-left: 0; padding-left: 1rem; color: #555; }
.task-list-item { list-style: none; }
.task-list-item input { margin-left: -1.5em; margin-right: 0.5em; }
@media print { body { max-width: none; } }
`;

const css = (cssFile && existsSync(cssFile))
    ? readFileSync(cssFile, "utf-8")
    : defaultCss;

// Wrap in a full HTML document.
const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>${css}</style>
</head>
<body>
${body}
</body>
</html>`;

// Output.
if (openInBrowser) {
    execSync("open -f -a Safari", { input: html });
} else if (outputFile) {
    writeFileSync(outputFile, html);
} else {
    process.stdout.write(html);
}
