import { tool } from "@opencode-ai/plugin";
import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";

const CATEGORIES_DIR = "categories";
const CATEGORY_PATTERN = /^[0-9]+-[a-z0-9-]+$/;
const AGENT_PATTERN = /^[a-z0-9-]+\.md$/;
const SKILL_NAME_PATTERN = /^[a-z0-9-]+$/;

function yamlEscape(value) {
  if (!value) {
    return "";
  }
  return String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function displayCategoryName(category) {
  return category
    .replace(/^[0-9]+-/, "")
    .split("-")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
    .join(" ");
}

function validateCategory(category) {
  if (!CATEGORY_PATTERN.test(category || "")) {
    throw new Error(
      "Invalid category. Expected format like '01-core-development'.",
    );
  }
}

function validateAgent(agent) {
  if (!AGENT_PATTERN.test(agent || "")) {
    throw new Error(
      "Invalid agent filename. Expected format like 'backend-developer.md'.",
    );
  }
}

function resolveInside(baseDir, ...segments) {
  const root = path.resolve(baseDir);
  const target = path.resolve(root, ...segments);
  const withSep = `${root}${path.sep}`;
  if (target !== root && !target.startsWith(withSep)) {
    throw new Error(`Path escape detected for '${target}'.`);
  }
  return target;
}

function parseFrontmatter(content) {
  const parsed = {
    name: "",
    description: "",
    tools: "inherit",
    model: "inherit",
  };

  const match = content.match(/^---\s*\n([\s\S]*?)\n---\s*\n?/);
  if (!match) {
    return parsed;
  }

  const lines = match[1].split("\n");
  for (const line of lines) {
    const separator = line.indexOf(":");
    if (separator <= 0) {
      continue;
    }
    const key = line.slice(0, separator).trim();
    let value = line.slice(separator + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    if (key === "name") {
      parsed.name = value;
    } else if (key === "description") {
      parsed.description = value;
    } else if (key === "tools") {
      parsed.tools = value || "inherit";
    } else if (key === "model") {
      parsed.model = value || "inherit";
    }
  }

  return parsed;
}

function extractBody(content) {
  const match = content.match(/^---\s*\n([\s\S]*?)\n---\s*\n?/);
  if (!match) {
    return content;
  }
  return content.slice(match[0].length);
}

function convertAgentToSkill(content, category, agent) {
  const frontmatter = parseFrontmatter(content);
  const body = extractBody(content);
  const fallbackName = agent.replace(/\.md$/, "");
  const name = frontmatter.name || fallbackName;
  const description = frontmatter.description || `Converted skill from ${fallbackName}`;
  const source = path.posix.join("categories", category, agent);

  return [
    "---",
    `name: ${name}`,
    `description: \"${yamlEscape(description)}\"`,
    "metadata:",
    `  source: \"${yamlEscape(source)}\"`,
    `  category: \"${yamlEscape(category)}\"`,
    `  tools: \"${yamlEscape(frontmatter.tools || "inherit")}\"`,
    `  model: \"${yamlEscape(frontmatter.model || "inherit")}\"`,
    "---",
    "",
    body,
  ].join("\n");
}

function parseAgentArg(agent) {
  const normalized = (agent || "").trim();
  if (normalized.endsWith(".md")) {
    return normalized;
  }
  return `${normalized}.md`;
}

function normalizeSkillName(frontmatterName, fallbackName) {
  const raw = String(frontmatterName || "").trim();
  if (SKILL_NAME_PATTERN.test(raw)) {
    return raw;
  }
  return fallbackName;
}

async function listCategories(repoRoot) {
  const categoriesRoot = resolveInside(repoRoot, CATEGORIES_DIR);
  const entries = await fs.readdir(categoriesRoot, { withFileTypes: true });

  return entries
    .filter((entry) => entry.isDirectory() && CATEGORY_PATTERN.test(entry.name))
    .map((entry) => ({
      id: entry.name,
      name: displayCategoryName(entry.name),
      path: path.posix.join(CATEGORIES_DIR, entry.name),
    }))
    .sort((a, b) => a.id.localeCompare(b.id));
}

async function listAgents(repoRoot, category) {
  validateCategory(category);
  const categoryRoot = resolveInside(repoRoot, CATEGORIES_DIR, category);
  const entries = await fs.readdir(categoryRoot, { withFileTypes: true });

  return entries
    .filter(
      (entry) =>
        entry.isFile() && entry.name.endsWith(".md") && entry.name !== "README.md",
    )
    .map((entry) => ({
      name: entry.name.replace(/\.md$/, ""),
      filename: entry.name,
      path: path.posix.join(CATEGORIES_DIR, category, entry.name),
    }))
    .sort((a, b) => a.name.localeCompare(b.name));
}

async function readAgent(repoRoot, category, agent) {
  validateCategory(category);
  validateAgent(agent);
  const agentFilePath = resolveInside(repoRoot, CATEGORIES_DIR, category, agent);
  const content = await fs.readFile(agentFilePath, "utf-8");
  const frontmatter = parseFrontmatter(content);
  const body = extractBody(content);

  return {
    content,
    frontmatter,
    body,
    source: path.posix.join(CATEGORIES_DIR, category, agent),
    agentName: normalizeSkillName(
      frontmatter.name,
      agent.replace(/\.md$/, ""),
    ),
  };
}

export const VoltAgentCatalog = async ({ directory, client }) => {
  const repoRoot = directory;

  if (client?.app?.log) {
    try {
      await client.app.log({
        body: {
          service: "voltagent-catalog",
          level: "info",
          message: "OpenCode catalog plugin loaded",
        },
      });
    } catch {
      // Ignore logging failures to avoid blocking plugin load.
    }
  }

  return {
    tool: {
      voltagent_list_categories: tool({
        description: "List all available VoltAgent categories in this repository",
        args: {},
        async execute() {
          const categories = await listCategories(repoRoot);
          return {
            count: categories.length,
            categories,
          };
        },
      }),

      voltagent_list_agents: tool({
        description: "List all agents in a specific category",
        args: {
          category: tool.schema.string(),
        },
        async execute(args) {
          const category = String(args.category || "").trim();
          const agents = await listAgents(repoRoot, category);
          return {
            category,
            count: agents.length,
            agents,
          };
        },
      }),

      voltagent_fetch_agent: tool({
        description: "Fetch agent metadata and body from this repository",
        args: {
          category: tool.schema.string(),
          agent: tool.schema.string(),
        },
        async execute(args) {
          const category = String(args.category || "").trim();
          const agent = parseAgentArg(String(args.agent || "").trim());
          const data = await readAgent(repoRoot, category, agent);

          return {
            category,
            agent,
            source: data.source,
            metadata: {
              name: data.agentName,
              description: data.frontmatter.description || "",
              tools: data.frontmatter.tools || "inherit",
              model: data.frontmatter.model || "inherit",
            },
            body: data.body,
          };
        },
      }),

      voltagent_install_skill: tool({
        description:
          "Convert and install one catalog agent as OpenCode SKILL.md (scope: project|global)",
        args: {
          category: tool.schema.string(),
          agent: tool.schema.string(),
          scope: tool.schema.string(),
        },
        async execute(args) {
          const category = String(args.category || "").trim();
          const agent = parseAgentArg(String(args.agent || "").trim());
          const scope = String(args.scope || "project").trim().toLowerCase();

          if (scope !== "project" && scope !== "global") {
            throw new Error("Invalid scope. Use 'project' or 'global'.");
          }

          const data = await readAgent(repoRoot, category, agent);
          const skillMarkdown = convertAgentToSkill(data.content, category, agent);

          const skillRoot =
            scope === "global"
              ? path.join(os.homedir(), ".config", "opencode", "skills")
              : path.join(repoRoot, ".opencode", "skills");

          const skillDir = resolveInside(skillRoot, data.agentName);
          await fs.mkdir(skillDir, { recursive: true });

          const skillPath = path.join(skillDir, "SKILL.md");
          await fs.writeFile(skillPath, skillMarkdown, "utf-8");

          return {
            success: true,
            name: data.agentName,
            category,
            source: data.source,
            scope,
            installedTo: skillPath,
          };
        },
      }),
    },
  };
};
