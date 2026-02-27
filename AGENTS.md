# AGENTS.md
This guide is for coding agents operating in `awesome-open-code-subagents`.
It captures the practical command surface and repository conventions.

## 1) Repository Snapshot
- Primary content: Markdown subagent definitions in `categories/`.
- Categories are numbered and grouped by domain (`01` through `10`).
- This repo is documentation/config heavy, not an app/library runtime.
- There is no `package.json`, `pyproject.toml`, `Makefile`, or `tsconfig.json`.
- There are no built-in unit/integration test suites for repo code.

## 2) Build / Lint / Test Commands
The repository does **not** define canonical build/lint/test commands.
Use the commands below as the operational baseline.

### Install / operational commands
- Run interactive installer from repo root:
  - `./install-agents.sh`
- Standalone installer (no clone):
  - `curl -sO https://raw.githubusercontent.com/VoltAgent/awesome-claude-code-subagents/main/install-agents.sh`
  - `chmod +x install-agents.sh`
  - `./install-agents.sh`
- Claude plugin marketplace install flow:
  - `claude plugin marketplace add VoltAgent/awesome-claude-code-subagents`
  - `claude plugin install voltagent-core-dev`

### Build status
- Build command: **none defined**.
- Treat this repo as content/config docs (Markdown + YAML frontmatter + shell).

### Lint status
- Lint command: **none defined**.
- No repo-level ESLint/Prettier/Ruff/Black/markdownlint config is committed.

### Test status
- Test command: **none defined**.
- No framework config exists for Jest/Vitest/Pytest/Go test in this repo.

### Single-test command (important)
- Single-test command: **not available in current repository state**.
- Reason: no test runner config or test suite exists to target.
- If you add tests in a future PR, add explicit single-test docs here.

### CI validation command surface
- CI workflow file: `.github/workflows/enforce-plugin-version-bump.yml`
- This workflow validates version bump rules and marketplace version sync.
- Trigger scope: PR changes touching `categories/**` or marketplace json.

## 3) Required Change Discipline
When editing agent files or docs, follow these required repository rules.

- If any `*.md` changes under `categories/<category>/`, then bump:
  - `categories/<category>/.claude-plugin/plugin.json` -> `version`
- Keep marketplace version in sync for the plugin entry in:
  - `.claude-plugin/marketplace.json`
- Failing either rule will fail CI.
- Keep README lists alphabetical where instructed.
- Update top-level and category READMEs when adding new agents.

## 4) Style Guidelines (Repository-Specific)
These are the conventions agents should apply when creating/updating files.

### 4.1 Markdown and documentation style
- Use clear, scannable headings and concise bullet points.
- Prefer actionable wording over narrative filler.
- Keep examples executable and copy/paste safe.
- Use relative paths in docs (repo-local), not machine-specific paths.
- Keep list entries alphabetized when file conventions require it.
- Keep line wrapping readable (roughly 80-100 chars preferred).

### 4.2 Subagent file format (`*.md` in categories)
- Start with YAML frontmatter bounded by `---`.
- Include at minimum:
  - `name`: kebab-case identifier
  - `description`: explicit trigger/use cases
  - `tools`: comma-separated allowed tools
- `model` may be specified when needed (`opus`, `sonnet`, `haiku`, `inherit`).
- Follow frontmatter with role, workflow, and communication guidance.
- Keep behavior guidance concrete and testable.

### 4.3 Imports / dependencies guidance
- There is no application code import graph to maintain.
- For shell scripts, avoid non-portable external dependencies when possible.
- If external tools are required (example: `curl`), check and fail clearly.

### 4.4 Formatting guidance
- Preserve existing style in touched files.
- Use ASCII unless file already requires non-ASCII.
- Avoid trailing whitespace and accidental tab/space churn.
- Keep YAML and JSON formatting stable/minimal-diff.
- Do not reformat unrelated sections in large markdown files.

### 4.5 Types / schema discipline
- Treat YAML frontmatter keys as stable API for consumers.
- Do not rename/remove frontmatter keys without repo-wide intent.
- Keep value types consistent (`tools` as string list format used by repo).
- In plugin manifests, keep `name` and `version` values consistent with docs.

### 4.6 Naming conventions
- Agent filenames: kebab-case, descriptive, `.md` suffix.
- Frontmatter `name`: match file intent and remain kebab-case.
- Category placement: choose the correct numbered domain directory.
- Keep plugin names unchanged unless doing coordinated migration.

### 4.7 Error handling conventions
- In shell scripts, use explicit checks before operations.
- Prefer early exits with clear error messages.
- Quote variables in shell to avoid word splitting.
- For destructive actions (remove/uninstall), show intent before execution.
- In CI scripts, emit actionable failures (what changed and what to update).

### 4.8 Git and change-scope hygiene
- Make focused changes tied to the user request.
- Do not modify unrelated categories or plugin versions.
- Do not revert unrelated dirty-worktree changes.
- If category markdown changes, include required version bumps in same PR.

## 5) Cursor / Copilot Rules Check
As of current repository state:
- `.cursor/rules/`: not present
- `.cursorrules`: not present
- `.github/copilot-instructions.md`: not present

Agent instruction implication:
- No additional Cursor/Copilot policy files need to be merged.
- Use repository docs (`README.md`, `CONTRIBUTING.md`, CI workflow) as source of truth.

## 6) Safe Execution Checklist for Agents
Before submitting changes, quickly verify:
- Correct category placement for every new/edited agent file.
- Alphabetical ordering in affected README lists.
- Required docs updated (top-level and category README when needed).
- Category plugin `version` bumped for category markdown changes.
- Matching plugin version updated in `.claude-plugin/marketplace.json`.
- No accidental edits outside intended scope.

## 7) If You Introduce Tooling Later
If a future PR adds true build/lint/test tooling:
- Add canonical commands to this file immediately.
- Include both full-suite and single-test examples.
- Include expected runtime prerequisites and versions.
- Keep commands copy/paste-ready from repository root.

---
Maintainers should keep this file aligned with CI and CONTRIBUTING rules.
