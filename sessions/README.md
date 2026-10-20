# Session logs

Short records of working sessions (human or AI), so context from one person's machine is
available to everyone. Claude and other agents keep chat history locally; this folder is the
shared substitute. It is **not** a transcript.

## When to read

Don't read this folder by default. Read it only when:
- someone asks about earlier work, a past discussion or why something was done;
- the code, the phase READMEs and `git log` don't explain a change or a decision;
- you need to know who to ask about something.

How to find an entry:

```bash
ls sessions/                                  # file names sort by date and carry author + topic
grep -ril "<keyword or ID>" sessions/         # e.g. "D-009", "phase2-rtl-v1", "00_inputs"
grep -l "phase 3" sessions/*.md
```

Then read only the matching files. Use each entry's "Git" section to check the actual changes
(`git show <hash>`, `git log <from>..<to>`), because the repo is the source of truth and the log
is only a summary.

## When to write

At the end of every session that changed the repo, made or changed a decision, or found a
problem worth remembering. Skip sessions that only read files. If an agent did the work, the
agent writes the entry and the person checks it before committing.

## Rules

- **One file per session:** `YYYY-MM-DD_HHMM_<author>_<topic>.md`, for example
  `2026-10-20_1405_adam_agents-md-and-phase2-fixes.md`. Use the local start time, a lowercase
  author name and a topic of 2 to 5 words in kebab case. Separate files mean no merge conflicts.
- **Append-only:** don't edit someone else's entry. To correct one, write a new entry that
  names the old file.
- **Short:** aim for 15 to 40 lines. Record outcomes, decisions with the reason, and loose ends.
  Leave out the conversation, code, command output and anything already in a commit message.
- **Citable:** use commit hashes, tags, file paths and spec IDs (`FR-`, `D-`, `TC-`, `GV-`…)
  so the entry can be checked against git.
- **No secrets:** no tokens, passwords, emails or private data.
- **Commit it** with the session's last commit, or as its own commit right after.

## Template

Copy this into a new file:

```markdown
# <Topic>

| Field | Value |
|---|---|
| When | YYYY-MM-DD HH:MM–HH:MM <UTC offset> |
| Who | <name>, with <tool, e.g. Claude Code in VS Code / none> |
| Branch | <branch> |
| Git | `<HEAD at start>`..`<HEAD at end>`; commits: `<hash>` <subject>, …; tags: <tag or none> |
| Phases | <1–8> |
| Keywords | <words someone would grep for> |

## Asked
What the session set out to do, in one to three lines.

## Done
- Outcome, with the commit or file that holds it.

## Decisions
- Decision, and why. Mark it "provisional" if someone still has to approve it.

## Not done / follow-ups
- Item, who it is waiting on, or "none".

## Notes for later
Anything non-obvious that the repo doesn't show: a dead end tried, an assumption, a tool quirk.
```
