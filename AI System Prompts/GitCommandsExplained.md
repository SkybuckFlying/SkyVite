### Git Commands Explained as of 23 november 2025:

## Git porcelain commands

These are human-friendly, high-level commands. Their output can change over time, so they’re not ideal for scripts.

| Command        | Purpose                                                                 |
|----------------|-------------------------------------------------------------------------|
| add            | Stage changes in the working directory into the index.                  |
| am             | Apply patches from email/mailbox.                                       |
| archive        | Create archive files from repository content.                           |
| bisect         | Find commit that introduced a bug via binary search.                    |
| branch         | List, create, or delete branches.                                       |
| bundle         | Create or apply bundle files.                                           |
| checkout       | Switch branches or restore working tree files (older, partly replaced). |
| cherry-pick    | Apply changes from an existing commit onto the current branch.          |
| citool         | Graphical commit interface.                                             |
| clean          | Remove untracked files from the working tree.                           |
| clone          | Clone a repository into a new directory.                                |
| commit         | Record changes to the repository.                                       |
| describe       | Show human-readable name for a commit (based on tags).                  |
| diff           | Show differences between commits, index, and working tree.              |
| fetch          | Download objects and refs from another repository.                      |
| format-patch   | Prepare patches for email submission.                                   |
| grep           | Search for patterns in tracked files.                                   |
| init           | Create an empty Git repository.                                         |
| log            | Show commit history.                                                    |
| merge          | Join two or more development histories together.                        |
| mv             | Move or rename a file, directory, or symlink.                           |
| notes          | Add or inspect commit notes.                                            |
| pull           | Fetch and merge changes from another repository.                        |
| push           | Update remote refs with local commits.                                  |
| rebase         | Reapply commits on top of another base commit.                          |
| remote         | Manage set of tracked repositories.                                     |
| reset          | Reset HEAD, index, and/or working directory.                            |
| restore        | Restore working directory files from index or commit (new in 2.23).     |
| revert         | Create a new commit that undoes changes from a previous commit.         |
| rm             | Remove files from the working tree and index.                           |
| shortlog       | Summarize commit logs.                                                  |
| show           | Show various types of objects.                                          |
| stash          | Save local modifications aside for later re-application.                |
| status         | Show working tree status.                                               |
| submodule      | Manage submodules.                                                      |
| switch         | Switch branches (new in 2.23, clearer than checkout).                   |
| tag            | Create, list, delete, or verify tags.                                   |
| worktree       | Manage multiple working trees attached to a repository.                 |

---

## Git plumbing commands

Low-level, stable, and script-friendly building blocks used by porcelain and internal operations.

| Command          | Explanation                                            |
|------------------|--------------------------------------------------------|
| cat-file         | Inspect object content, type, or size.                 |
| check-ref-format | Validate ref names against rules.                      |
| commit-tree      | Create a commit object from a tree.                    |
| count-objects    | Count loose objects and their disk usage.              |
| diff-index       | Compare the index with a tree or working tree.         |
| diff-tree        | Show differences between two tree objects.             |
| for-each-ref     | Iterate and format information about refs.             |
| hash-object      | Compute an object ID and optionally write the object.  | 
| ls-files         | List files in the index and control caching details.   | 
| ls-tree          | List the contents of a tree object.                    |
| merge-base       | Find best common ancestor(s) of commits.               | 
| mktree           | Create a tree object from textual input.               | 
| pack-objects     | Write objects into a packfile.                         |
| read-tree        | Read a tree into the index.                            |
| rev-list         | List commits reachable from given revisions.           |
| rev-parse        | Normalize and resolve revision/reflog/params to IDs.   |
| show-ref         | List refs and their object IDs.                        |
| symbolic-ref     | Read or set a symbolic ref (e.g., HEAD).               |
| update-index     | Write file contents and mode to the index.             |
| update-ref       | Create, delete, or move refs atomically.               |
| verify-pack      | Verify integrity and index of packfiles.               |
| write-tree       | Create a tree object from the index.                   |

---

## Git maintenance commands

Operational/housekeeping commands that maintain repository health and storage. Alphabetical.

| Command      | Explanation                                                                               |
|--------------|-------------------------------------------------------------------------------------------|
| fsck         | Check object connectivity and integrity; report problems.                                 |
| gc           | Run garbage collection: prune unreachable objects, repack, optimize.                      |
| maintenance  | Run scheduled or on-demand maintenance tasks (prepack, incremental, commit-graph, etc.).  |
| prune        | Delete unreachable loose objects older than a threshold.                                  |
| prune-packed | Remove loose objects that are already in packfiles.                                       |
| reflog       | Show and manage reflog entries for refs (cleanup/expire entries).                         |
| repack       | Repack objects into packfiles to improve storage/performance.                             |

Note:
- prune focuses on loose, unreachable objects; gc may call prune and repack together.
- reflog isn’t purely “maintenance” in usage, but its expire/cleanup modes are maintenance-oriented.
- maintenance is newer and can orchestrate several tasks like commit-graph updates, prefetch, and incremental repacks.


# Git Reset Options

| Option   | Description                                                                                      | HEAD        | Index (Staging Area) | Working Directory                  |
|----------|--------------------------------------------------------------------------------------------------|-------------|----------------------|------------------------------------|
| --soft   | Move HEAD only; keep index and working directory unchanged.                                      | Updated     | Unchanged            | Unchanged.                         |
| --mixed  | **Default mode**. Move HEAD and reset index to match target commit; working dir unchanged.       | Updated     | Reset (to commit)    | Unchanged.                         |
| --hard   | Move HEAD, reset index, and reset working dir to match target commit. **All changes discarded.** | Updated     | Reset (to commit)    | Reset (to commit).                 |
| --merge  | Like --hard, but preserves local changes that don’t conflict with the target commit.             | Updated     | Reset (to commit)    | Preserves non-conflicting changes. |
| --keep   | Like --hard, but refuses to overwrite local changes; aborts if conflicts exist.                  | Updated     | Reset (to commit)    | Keeps changes unless conflicting.  |

# When to Use Git Reset Options

| Option   | Typical Use Case                                                                              | What You Achieve                                                                                                                                      |
|----------|-----------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| --soft   | Undo a commit but keep all changes staged.                                                    | Useful when you realize you committed too early and want to amend or re-commit.                                                                       |
| --mixed  | **Default mode.** Undo a commit and unstage changes, but keep them in your working directory. | HEAD moves, index is reset to match the target commit, working directory unchanged. Great for re-editing files after accidentally staging/committing. |
| --hard   | Completely discard commits and local changes, resetting everything to a commit.               | HEAD, index, and working directory all reset to the target commit. **All local changes are lost.**                                                    |
| --merge  | Reset to a commit while preserving local changes that don’t conflict.                         | Safer than `--hard`. Index reset to commit, working directory updated, but non-conflicting local edits are preserved.                                 |
| --keep   | Reset to a commit but refuse to overwrite local changes if conflicts exist.                   | HEAD and index reset to commit, working directory kept intact unless conflicts would occur — in that case, reset aborts.                              |

# Git Restore Cheatsheet

| Command                                 | Description                                         | Typical Use Case                             |
|-----------------------------------------|-----------------------------------------------------|----------------------------------------------|
| git restore <file>                      | Discard local changes, restore file from index.     | Undo edits in working directory.             |
| git restore --staged <file>             | Unstage a file, keep changes in working directory.  | Safely remove file from staging area.        |
| git restore --source=<commit> <file>    | Restore file from a specific commit.                | Revert file to an older version.             |
| git restore --worktree <file>           | Restore file in working directory only.             | Reset file contents without touching index.  |
| git restore --staged --worktree <file>  | Restore both index and working directory.           | Fully reset file to commit state.            |

# Git Stash Cheatsheet

| Command / Option                        | Description                                                                   | Typical Use Case                                                              |
|-----------------------------------------|-------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| git stash                               | Save current changes (tracked files) to a new stash entry, clear working dir. | Quick save of work-in-progress before switching branches or pulling updates.  |
| git stash push                          | Explicitly push changes into stash (same as `git stash`).                     | Preferred modern form; allows options like `-m` or `--include-untracked`.     |
| git stash push -m "msg"                 | Save changes with a custom message.                                           | Easier to identify stash entries later.                                       |
| git stash list                          | Show all stash entries with index and message.                                | Review what’s currently stashed.                                              |
| git stash show                          | Show summary of changes in the latest stash.                                  | Quick peek at what’s inside the most recent stash.                            |
| git stash show -p                       | Show full diff of the latest stash.                                           | Inspect exact changes saved.                                                  |
| git stash pop                           | Apply the latest stash and remove it from the stash list.                     | Restore work-in-progress and continue editing.                                |
| git stash apply                         | Apply a stash entry but keep it in the stash list.                            | Reuse the same stash multiple times.                                          |
| git stash drop                          | Delete a specific stash entry.                                                | Clean up stash list after applying or discarding.                             |
| git stash clear                         | Remove all stash entries.                                                     | Reset stash list completely.                                                  |
| git stash branch <name>                 | Create a new branch from a stash entry.                                       | Useful when stashed work diverges significantly; isolate it on a new branch.  |
| git stash pop stash@{n}                 | Apply and remove a specific stash entry by index.                             | Restore a particular stash when multiple exist.                               |
| git stash apply stash@{n}               | Apply a specific stash entry without removing it.                             | Selectively reapply stashed changes.                                          |
| git stash push -u / --include-untracked | Stash tracked **and untracked** files.                                        | Save edits plus new files not yet committed.                                  |
| git stash push -a / --all               | Stash tracked, untracked, **and ignored** files.                              | Save absolutely everything, including ignored files.                          |
| git stash push -p / --patch             | Interactively choose hunks of changes to stash.                               | Fine-grained control over what gets stashed.                                  |
| git stash push -k / --keep-index        | Stash changes but keep staged files in the index.                             | Useful when you want to stash only unstaged changes.                          |
| git stash push -S / --staged            | Stash only staged changes.                                                    | Save staged work without touching unstaged edits.                             |
