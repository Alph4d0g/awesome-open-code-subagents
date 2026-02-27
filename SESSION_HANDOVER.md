# Session Handover: OpenCode Conversion

## Objective

Adapt `awesome-claude-code-subagents` so it can be loaded and used in OpenCode while preserving existing Claude functionality.

## What Was Done

### 1) Discovery and research

- Mapped repo/plugin surface (Claude manifests, installer, docs, category structure).
- Confirmed no prior OpenCode support in repo.
- Delegated OpenCode docs lookup to `@librarian` and used official OpenCode docs to guide compatibility approach.

Authoritative references used:
- Plugins (local files, npm, load order): `https://opencode.ai/docs/plugins/`
- Skills placement/discovery/frontmatter constraints: `https://opencode.ai/docs/skills/`
- CLI capabilities: `https://opencode.ai/docs/cli/`

Key findings from docs:
- OpenCode skill loading is file-based from skills directories; Claude marketplace manifests are not OpenCode-native.
- Skills are discovered from `.opencode/skills/<name>/SKILL.md` (project) and `~/.config/opencode/skills/<name>/SKILL.md` (global).
- OpenCode supports compatibility paths including `.claude/skills` and `.agents/skills`, but native path is `.opencode/skills`.
- `SKILL.md` frontmatter supports `name`, `description`, optional metadata-style fields; unknown Claude-specific keys should not be relied on.

### 2) Implementation

#### Added: `install-opencode-skills.sh`

New interactive installer that preserves the existing installer experience, but outputs OpenCode skills.

Capabilities:
- Local source mode (from cloned repo) and remote source mode (GitHub API/raw files).
- Category browsing from `categories/NN-*` directories.
- Multi-select install/uninstall per category.
- Global install target: `~/.config/opencode/skills/`.
- Local install target: `.opencode/skills/` (if `.opencode` exists).
- Install converts each selected `categories/<category>/<agent>.md` into:
  - `<skills-dir>/<agent-name>/SKILL.md`
- Uninstall removes `<skills-dir>/<agent-name>/`.

Conversion behavior:
- Reads Claude frontmatter keys from source agent: `name`, `description`, `tools`, `model`.
- Writes OpenCode-friendly frontmatter:
  - `name`
  - `description`
  - `metadata.source`
  - `metadata.category`
  - `metadata.tools`
  - `metadata.model`
- Preserves original markdown body content after frontmatter.

#### Added: `OPENCODE.md`

New compatibility guide documenting:
- How to install/use the OpenCode installer.
- Install locations.
- Frontmatter mapping from Claude agent format to generated OpenCode `SKILL.md`.
- Compatibility note: keep Claude files intact while supporting OpenCode.

#### Updated: `README.md`

Added OpenCode support documentation while retaining existing Claude instructions:
- New OpenCode installation section (clone + standalone curl flow).
- New storage paths for OpenCode skills.
- Generalized language in "Understanding" section to subagents/skills.
- Added a short OpenCode getting-started flow.
- Added OpenCode skill format explanation (generated `SKILL.md`, preserved body, metadata retention).

## Current Repository State (at handover)

From `git status --short`:
- Modified: `README.md`
- Untracked: `OPENCODE.md`
- Untracked: `install-opencode-skills.sh`
- Untracked: `AGENTS.md` (pre-existing and unrelated to this conversion; do not include unless intentionally tracked)

From `git diff --stat`:
- `README.md`: 52 insertions, 8 deletions

## Validation Performed

- Shell syntax check passed for new installer:
  - `bash -n install-opencode-skills.sh`

Not performed in this session:
- End-to-end interactive installer run.
- Any CI checks (none repo-standard for code, but CI has plugin version rules tied to `categories/**` markdown changes).

## Compatibility/Design Decisions

1. **Do not mutate category agent files**
- Preserves existing Claude ecosystem behavior.
- OpenCode compatibility is implemented through conversion at install time.

2. **Additive strategy over breaking migration**
- Keep Claude installer/docs intact.
- Add OpenCode installer/docs in parallel.

3. **Same functionality target**
- Existing interactive installer UX (category select, multi-select, install/uninstall, local/remote source) mirrored for OpenCode.

## Known Gaps / Risks

- OpenCode does not use Claude marketplace manifests (`.claude-plugin/marketplace.json`) directly.
- No OpenCode-specific package manifest was added (intentional); current approach uses skill files/directories.
- Need manual runtime verification in OpenCode session to confirm discovery behavior in your environment.

## Recommended Next Steps

1. Run an end-to-end local install test:
   - `mkdir -p .opencode`
   - `./install-opencode-skills.sh`
   - Install a small sample set, then verify generated folders/files under `.opencode/skills/`.
2. Run a global install test:
   - Install to `~/.config/opencode/skills/` and verify OpenCode loads skills in a fresh session.
3. If behavior is confirmed, stage and commit only intended files:
   - `README.md`
   - `OPENCODE.md`
   - `install-opencode-skills.sh`
4. Keep `AGENTS.md` excluded unless explicitly intended for this PR.

## Quick Command Checklist

```bash
chmod +x install-opencode-skills.sh
bash -n install-opencode-skills.sh
git status --short
git diff -- README.md
```

## Files Touched for This Work

- `README.md`
- `OPENCODE.md` (new)
- `install-opencode-skills.sh` (new)
