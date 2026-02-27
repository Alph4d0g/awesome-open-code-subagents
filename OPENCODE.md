# OpenCode Compatibility

This repository can be used in OpenCode via **npm plugin** (recommended) or **skill installer** (static file-based installation).

## OpenCode Plugin (Recommended)

The plugin package is located at `npm/opencode-subagents-plugin`.

### Configuration

Add to your `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["@voltagent/opencode-subagents-plugin"]
}
```

### Available Tools

| Tool | Description | Example |
|------|-------------|---------|
| `voltagent_list_categories` | List all agent categories | `Use voltagent_list_categories` |
| `voltagent_list_agents` | List agents in a category | `Use voltagent_list_agents for category 02-language-specialists` |
| `voltagent_fetch_agent` | Fetch full agent definition | `Use voltagent_fetch_agent with category 02-language-specialists and agent python-pro.md` |
| `voltagent_install_skill` | Install an agent as a skill | `Use voltagent_install_skill with category 02-language-specialists, agent python-pro.md, scope project` |

For pre-publish local testing, pack `npm/opencode-subagents-plugin` and use a
file spec plugin entry (for example
`"@voltagent/opencode-subagents-plugin@file:/tmp/voltagent-opencode-subagents-plugin-<version>.tgz"`).

Restart OpenCode to load the plugin.

## Skill Installer (Optional/Legacy)

For static skill installation without the plugin, use the interactive installer.

### Install

Run from repository root:

```bash
./install-opencode-skills.sh
```

Supports:
- local/remote source (from cloned files or GitHub)
- category browsing
- multi-select install/uninstall
- global or project-scoped skill installation

### Install Locations

- Global: `~/.config/opencode/skills/`
- Project: `.opencode/skills/`

Each installed skill is created as:

```text
<skills-dir>/<agent-name>/SKILL.md
```

### Frontmatter Mapping

Claude source frontmatter:

- `name`
- `description`
- `tools`
- `model`

OpenCode `SKILL.md` output frontmatter:

- `name`
- `description`
- `metadata.source`
- `metadata.category`
- `metadata.tools`
- `metadata.model`

The original agent body content is preserved.

## Notes

- OpenCode reads skills from the paths above; Claude marketplace manifests are not used by OpenCode.
- The plugin approach is recommended for dynamic browsing; the installer is suitable for static workflows.
- This repo keeps Claude files intact for backward compatibility while providing OpenCode support.
