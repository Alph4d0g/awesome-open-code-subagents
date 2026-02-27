# OpenCode Compatibility

This repository can be used in OpenCode by converting agent definitions in `categories/*/*.md`
into OpenCode skills.

## Install

Run the interactive installer from repository root:

```bash
./install-opencode-skills.sh
```

It supports:
- local/remote source (from cloned files or GitHub)
- category browsing
- multi-select install/uninstall
- global or project-scoped skill installation

## Install Locations

- Global: `~/.config/opencode/skills/`
- Project: `.opencode/skills/`

Each installed skill is created as:

```text
<skills-dir>/<agent-name>/SKILL.md
```

## Frontmatter Mapping

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
- This repo keeps Claude files intact for backward compatibility while providing an OpenCode installer.
