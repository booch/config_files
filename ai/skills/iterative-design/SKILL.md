---
name: iterative-design
description: This skill should be used when iterating across multiple feedback rounds on a visual or creative artifact (SVG, image, diagram, HTML mockup, slide, logo) — especially when the user compares a design against earlier versions, says the design "regressed" or "was better before", asks to "keep track of versions", "go back to the old one", or "you lost the changes", or the session is long enough that early instructions could be forgotten.
---

# Iterative Design

## Overview

Multi-round visual iteration fails in two ways: regressions that can't be
rolled back (the working file was overwritten), and forgotten constraints
(an instruction from round 3 silently violated in round 15, after context
compaction). Both are fixed with files, not memory.

## The Workflow

Each feedback round produces two file updates:

1. **Version — never overwrite.** Before editing, copy the current artifact
   to `<name>-v<N>.<ext>` (v1, v2, …). Edit the working file only after the
   snapshot exists. Every version the user has seen must remain on disk.
2. **Constraints file — append on arrival.** Keep `<name>-constraints.md`
   beside the artifact. The moment the user gives an instruction ("never
   change the hair", "bottom of the head stays at y=75"), append it as a
   checklist item. Mark approved baselines there too ("v12 approved").
3. **Before each edit:** re-read the constraints file — not your memory of it.
4. **After each edit:** verify every constraint against the new file
   numerically or structurally (coordinates, colors, element diffs — not by
   eye), and say so in your reply.
5. **On "this is worse" / "that regressed":** diff the working file against
   the last-approved version (`git diff --no-index vN vM` works on any two
   files). Revert from the snapshot; never reconstruct a prior state from
   memory.

## Common Mistakes

| Mistake | Consequence |
|---|---|
| Editing the artifact in place | "v19 is worse than v18" becomes unrecoverable |
| Constraints held in conversation memory | Violated after compaction or ~10 rounds; user must repeat themselves |
| Verifying by eyeballing a render | Small drifts (1-2px, shade changes) slip through repeatedly |
| Reverting by re-editing from memory | Reintroduces earlier mistakes; snapshots are exact |
