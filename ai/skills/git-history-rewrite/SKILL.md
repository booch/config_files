---
name: git-history-rewrite
description: Safe git history rewrite workflows. Use this skill when splitting commits, rewriting recent commits, moving changes between commits, preserving dirty worktrees during history edits, or using temporary indexes with commit-tree/update-ref.
---

# Git History Rewrite

Use this skill for focused history edits such as splitting `HEAD`, separating mixed work across commits, replaying commits above a rewritten range, or fixing commit boundaries without disturbing an existing dirty worktree.

## Safety Rules

- Inspect `git status --short`, recent `git log --oneline`, and the target commit contents before rewriting history.
- Preserve unrelated staged and unstaged work. Do not use `git reset` when the worktree or index is dirty unless the user explicitly approves it.
- Save original commit SHAs before moving refs.
- If using `commit-tree`/`update-ref`, keep using temporary-index commits for follow-up focused commits unless the normal index has been checked or safely refreshed.
- Prefer a temporary `GIT_INDEX_FILE` with `git read-tree`, `git update-index`, `git write-tree`, `git commit-tree`, and `git update-ref` for dirty-worktree rewrites.
- Use exact tree entries for binary files and symlinks; avoid patch-apply workflows for split boundaries that include binary files.
- Use `bash -c`, not `bash -lc`, for git-plumbing scripts unless a login shell is explicitly required.
- Never rewrite or discard user changes outside the requested history edit.

## Split Commit Workflow

1. Identify the range:
   - Save `old_head=$(git rev-parse HEAD)` or the target commit SHA.
   - Save any commits above the target that must be restored.
   - Save `base=$(git rev-parse <target>^)`.

2. Define exact boundaries:
   - List files or paths for each new commit.
   - State the intended grouping before rewriting when boundaries are ambiguous.
   - For mixed files, inspect patches and decide whether a line-level split is required.

3. Build each new tree from a temporary index:
   - Start from the intended parent with `GIT_INDEX_FILE="$tmp_index" git read-tree <parent>`.
   - Add whole-file content from an existing commit with `git ls-tree -rz --format="%(objectmode) %(objectname) 0%x09%(path)" <commit> -- <paths> | GIT_INDEX_FILE="$tmp_index" git update-index -z --index-info`.
   - Add current working-tree content only when the user wants uncommitted changes folded into the rewritten commit. Hash the file with `git hash-object -w -- <path>`, then add it with `git update-index --add --cacheinfo <mode> <blob> <path>`.
   - Write the tree with `GIT_INDEX_FILE="$tmp_index" git write-tree`.

4. Create replacement commits:
   - Use `git commit-tree <tree> -p <parent>`.
   - Preserve original author metadata when rewriting an existing commit.
   - Write new messages that accurately describe the corrected boundaries.

5. Reapply commits above the rewritten range:
   - If the worktree/index is clean enough and conflicts are acceptable, use `git cherry-pick <saved-sha>`.
   - If the worktree/index is dirty, recreate the top commits with `commit-tree` using exact tree entries from the saved commits.

6. Move the branch:
   - Use `git update-ref -m "<reason>" <branch-ref> <new-head> <old-head>` so the ref update is guarded by the expected old SHA.

## Verification

- Run `git diff --cached --name-status` before any normal commit after plumbing-based ref updates.
- Check each new commit with `git show --name-status --oneline <commit>`.
- Compare the original and new final trees with `git diff --name-status <old-final> <new-final>`.
- If intentional folded-in working-tree changes exist, confirm the diff shows only those paths.
- Check `git status --short` and verify unrelated dirty work remains untouched.
- For symlinks, confirm mode `120000` and target content are correct with `git ls-files --stage -- <path>` and `git show <commit>:<path>`.

## Common Pitfalls

- `git diff --binary | git apply --cached` can still produce incorrect split boundaries for binary assets; use exact tree object IDs instead.
- `git reset --mixed` or `git reset --soft` can mix unrelated staged work into the rewrite when the index is dirty.
- Replaying a saved top commit with `cherry-pick` may fail or disturb local changes; use `commit-tree` recreation when preservation matters more than command simplicity.
- Login shells may source profile files and emit unrelated warnings or alter environment variables.
