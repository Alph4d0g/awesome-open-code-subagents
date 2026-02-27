# OpenCode Compatibility

This repository can be used in OpenCode via **plugin** (dynamic tool-based access) or **skill installer** (static file-based installation).

## OpenCode Plugin (Recommended)

OpenCode loads plugins from:
- **Project scope:** `.opencode/plugins/`
- **Global scope:** `~/.config/opencode/plugins/`

### Plugin File

This repository provides `.opencode/plugins/voltagent-catalog.js` which exposes custom tools for browsing and installing agents dynamically.

Plugin dependency manifest: `.opencode/package.json` (`@opencode-ai/plugin`).

### Available Tools

| Tool | Description | Example |
|------|-------------|---------|
| `voltagent_list_categories` | List all agent categories | `Use voltagent_list_categories` |
| `voltagent_list_agents` | List agents in a category | `Use voltagent_list_agents for category 02-language-specialists` |
| `voltagent_fetch_agent` | Fetch full agent definition | `Use voltagent_fetch_agent with category 02-language-specialists and agent python-pro.md` |
| `voltagent_install_skill` | Install an agent as a skill | `Use voltagent_install_skill with category 02-language-specialists, agent python-pro.md, scope project` |

### Plugin Installation

**Project install:**
```bash
mkdir -p /your/project/.opencode/plugins
cp /path/to/repo/.opencode/plugins/voltagent-catalog.js /your/project/.opencode/plugins/
cp /path/to/repo/.opencode/package.json /your/project/.opencode/package.json
```

**Global install:**
```bash
mkdir -p ~/.config/opencode/plugins
cp /path/to/repo/.opencode/plugins/voltagent-catalog.js ~/.config/opencode/plugins/
```

Restart OpenCode or start a new session to load the plugin.

If copied to another project, OpenCode installs `.opencode/package.json` dependencies
via Bun at startup.

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
