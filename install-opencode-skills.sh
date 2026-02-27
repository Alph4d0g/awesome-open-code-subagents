#!/bin/bash

# OpenCode Skills Installer
# Interactive script to install/uninstall skills from this repository.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CATEGORIES_DIR="$SCRIPT_DIR/categories"
GLOBAL_SKILLS_DIR="$HOME/.config/opencode/skills"
LOCAL_SKILLS_DIR=".opencode/skills"
OPENCODE_SKILLS_DIR=""
INSTALL_MODE=""
SOURCE_MODE=""

GITHUB_API_BASE="https://api.github.com/repos/VoltAgent/awesome-claude-code-subagents/contents"
GITHUB_RAW_BASE="https://raw.githubusercontent.com/VoltAgent/awesome-claude-code-subagents/main"

REMOTE_CATEGORIES=()
REMOTE_AGENTS=()

has_local_opencode_dir() {
    [[ -d ".opencode" ]]
}

has_local_categories() {
    [[ -d "$CATEGORIES_DIR" ]]
}

check_curl() {
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}Error: curl is required for remote mode but not installed.${NC}"
        exit 1
    fi
}

fetch_categories_remote() {
    local response
    response=$(curl -s "$GITHUB_API_BASE/categories")

    if echo "$response" | grep -q "API rate limit exceeded"; then
        echo -e "${RED}GitHub API rate limit exceeded. Try again later or use local mode.${NC}"
        sleep 2
        return 1
    fi

    if echo "$response" | grep -q '"message"'; then
        echo -e "${RED}Error fetching categories from GitHub API.${NC}"
        sleep 2
        return 1
    fi

    REMOTE_CATEGORIES=()
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            REMOTE_CATEGORIES+=("$line")
        fi
    done < <(echo "$response" | grep -o '"name": "[0-9][^"]*"' | sed 's/"name": "//;s/"$//' | sort)

    return 0
}

fetch_agents_remote() {
    local category="$1"
    local response
    response=$(curl -s "$GITHUB_API_BASE/categories/$category")

    if echo "$response" | grep -q '"message"'; then
        return 1
    fi

    REMOTE_AGENTS=()
    while IFS= read -r line; do
        if [[ -n "$line" && "$line" != "README.md" ]]; then
            REMOTE_AGENTS+=("$line")
        fi
    done < <(echo "$response" | grep -o '"name": "[^"]*\.md"' | sed 's/"name": "//;s/"$//' | sort)

    return 0
}

download_agent_to_temp() {
    local category="$1"
    local agent_file="$2"
    local temp_path="$3"
    local url="$GITHUB_RAW_BASE/categories/$category/$agent_file"

    if curl -sS "$url" -o "$temp_path" 2>/dev/null; then
        return 0
    fi
    return 1
}

show_header() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║             OpenCode Skills Installer                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    if [[ -n "$INSTALL_MODE" ]]; then
        local mode_str=""
        if [[ "$INSTALL_MODE" == "global" ]]; then
            mode_str="Global (~/.config/opencode/skills/)"
        else
            mode_str="Local (.opencode/skills/)"
        fi

        local source_str=""
        if [[ "$SOURCE_MODE" == "remote" ]]; then
            source_str=" | Source: GitHub"
        else
            source_str=" | Source: Local"
        fi

        echo -e "${BLUE}Mode: ${mode_str}${source_str}${NC}\n"
    fi
}

select_install_mode() {
    show_header
    echo -e "${BOLD}Select installation mode:${NC}\n"
    echo -e "  ${YELLOW}1)${NC} Global installation ${CYAN}(~/.config/opencode/skills/)${NC}"
    echo -e "     Available in all projects"
    echo ""

    if has_local_opencode_dir; then
        echo -e "  ${YELLOW}2)${NC} Local installation ${CYAN}(.opencode/skills/)${NC}"
        echo -e "     Only for current project"
    else
        echo -e "  ${BLUE}2)${NC} Local installation ${CYAN}(not available)${NC}"
        echo -e "     ${YELLOW}No .opencode/ directory found in current directory${NC}"
    fi
    echo ""
    echo -e "  ${YELLOW}q)${NC} Quit"
    echo ""

    read -p "Enter your choice: " choice
    case "$choice" in
        1)
            OPENCODE_SKILLS_DIR="$GLOBAL_SKILLS_DIR"
            INSTALL_MODE="global"
            mkdir -p "$OPENCODE_SKILLS_DIR"
            ;;
        2)
            if has_local_opencode_dir; then
                OPENCODE_SKILLS_DIR="$LOCAL_SKILLS_DIR"
                INSTALL_MODE="local"
                mkdir -p "$OPENCODE_SKILLS_DIR"
            else
                echo -e "\n${RED}Local installation unavailable. Create .opencode/ first.${NC}"
                sleep 2
                select_install_mode
                return
            fi
            ;;
        q|Q)
            echo -e "\n${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please try again.${NC}"
            sleep 1
            select_install_mode
            ;;
    esac
}

select_source_mode() {
    if ! has_local_categories; then
        SOURCE_MODE="remote"
        check_curl
        echo -e "${YELLOW}No local repository found. Using remote mode (GitHub).${NC}"
        sleep 1
        return
    fi

    show_header
    echo -e "${BOLD}Select source:${NC}\n"
    echo -e "  ${YELLOW}1)${NC} Local files ${CYAN}(from cloned repository)${NC}"
    echo -e "     Faster, works offline"
    echo ""
    echo -e "  ${YELLOW}2)${NC} Remote ${CYAN}(download from GitHub)${NC}"
    echo -e "     Always up-to-date"
    echo ""
    echo -e "  ${YELLOW}q)${NC} Quit"
    echo ""

    read -p "Enter your choice: " choice
    case "$choice" in
        1)
            SOURCE_MODE="local"
            ;;
        2)
            SOURCE_MODE="remote"
            check_curl
            ;;
        q|Q)
            echo -e "\n${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please try again.${NC}"
            sleep 1
            select_source_mode
            ;;
    esac
}

get_category_name() {
    local dir="$1"
    echo "$dir" | sed 's/^[0-9]*-//' | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1'
}

skill_dir_for_agent() {
    local agent_file="$1"
    local agent_name="${agent_file%.md}"
    echo "$OPENCODE_SKILLS_DIR/$agent_name"
}

is_agent_installed() {
    local agent_file="$1"
    local skill_dir
    skill_dir=$(skill_dir_for_agent "$agent_file")
    [[ -f "$skill_dir/SKILL.md" ]]
}

extract_frontmatter_value() {
    local key="$1"
    local input_file="$2"
    awk -v k="$key" '
        BEGIN { in_fm=0 }
        /^---[[:space:]]*$/ {
            if (in_fm==0) { in_fm=1; next }
            else { exit }
        }
        in_fm==1 {
            if ($0 ~ "^" k ":[[:space:]]*") {
                val=$0
                sub("^" k ":[[:space:]]*", "", val)
                gsub(/^"|"$/, "", val)
                print val
                exit
            }
        }
    ' "$input_file"
}

extract_body() {
    local input_file="$1"
    awk '
        BEGIN { count=0; started=0 }
        /^---[[:space:]]*$/ {
            count++
            if (count==2) { started=1; next }
        }
        started==1 { print }
    ' "$input_file"
}

escape_yaml_double() {
    local input="$1"
    printf '%s' "$input" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

convert_agent_to_skill() {
    local source_file="$1"
    local category="$2"
    local agent_file="$3"
    local destination_file="$4"

    local name
    local description
    local tools
    local model
    name=$(extract_frontmatter_value "name" "$source_file")
    description=$(extract_frontmatter_value "description" "$source_file")
    tools=$(extract_frontmatter_value "tools" "$source_file")
    model=$(extract_frontmatter_value "model" "$source_file")

    if [[ -z "$name" ]]; then
        name="${agent_file%.md}"
    fi
    if [[ -z "$description" ]]; then
        description="Converted skill from ${agent_file%.md}"
    fi
    if [[ -z "$tools" ]]; then
        tools="inherit"
    fi
    if [[ -z "$model" ]]; then
        model="inherit"
    fi

    local escaped_description
    local escaped_tools
    local escaped_model
    escaped_description=$(escape_yaml_double "$description")
    escaped_tools=$(escape_yaml_double "$tools")
    escaped_model=$(escape_yaml_double "$model")

    {
        echo "---"
        echo "name: $name"
        echo "description: \"$escaped_description\""
        echo "metadata:"
        echo "  source: \"categories/$category/$agent_file\""
        echo "  category: \"$category\""
        echo "  tools: \"$escaped_tools\""
        echo "  model: \"$escaped_model\""
        echo "---"
        echo ""
        extract_body "$source_file"
    } > "$destination_file"
}

install_agent_skill() {
    local category="$1"
    local agent_file="$2"
    local tmp_source=""
    local source_file=""

    if [[ "$SOURCE_MODE" == "remote" ]]; then
        tmp_source=$(mktemp)
        if ! download_agent_to_temp "$category" "$agent_file" "$tmp_source"; then
            echo -e "${RED}✗${NC} Failed to download: $agent_file"
            rm -f "$tmp_source"
            return 1
        fi
        source_file="$tmp_source"
    else
        source_file="$CATEGORIES_DIR/$category/$agent_file"
        if [[ ! -f "$source_file" ]]; then
            echo -e "${RED}✗${NC} Missing source file: $source_file"
            return 1
        fi
    fi

    local skill_dir
    skill_dir=$(skill_dir_for_agent "$agent_file")
    mkdir -p "$skill_dir"

    if convert_agent_to_skill "$source_file" "$category" "$agent_file" "$skill_dir/SKILL.md"; then
        echo -e "${GREEN}✓${NC} Installed: ${agent_file%.md}"
    else
        echo -e "${RED}✗${NC} Failed to convert: $agent_file"
    fi

    if [[ -n "$tmp_source" ]]; then
        rm -f "$tmp_source"
    fi
}

uninstall_agent_skill() {
    local agent_file="$1"
    local skill_dir
    skill_dir=$(skill_dir_for_agent "$agent_file")
    if [[ -d "$skill_dir" ]]; then
        rm -rf "$skill_dir"
        echo -e "${RED}✓${NC} Uninstalled: ${agent_file%.md}"
    fi
}

select_category() {
    show_header
    echo -e "${BOLD}Select a category:${NC}\n"

    local categories=()
    local i=1

    if [[ "$SOURCE_MODE" == "remote" ]]; then
        echo -e "${CYAN}Fetching categories from GitHub...${NC}\n"
        if ! fetch_categories_remote; then
            echo -e "${RED}Failed to fetch categories. Press Enter to retry.${NC}"
            read -r
            select_category
            return
        fi

        for dirname in "${REMOTE_CATEGORIES[@]}"; do
            categories+=("$dirname")
            echo -e "  ${YELLOW}$i)${NC} $(get_category_name "$dirname")"
            ((i++))
        done
    else
        for dir in "$CATEGORIES_DIR"/*/; do
            if [[ -d "$dir" ]]; then
                local dirname
                dirname=$(basename "$dir")
                if [[ "$dirname" =~ ^[0-9]+ ]]; then
                    categories+=("$dirname")
                    local count
                    count=$(ls "$dir"/*.md 2>/dev/null | grep -v README.md | wc -l | tr -d ' ')
                    echo -e "  ${YELLOW}$i)${NC} $(get_category_name "$dirname") ${CYAN}($count agents)${NC}"
                    ((i++))
                fi
            fi
        done
    fi

    echo ""
    echo -e "  ${YELLOW}q)${NC} Quit"
    echo ""

    read -p "Enter your choice: " choice
    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        echo -e "\n${GREEN}Goodbye!${NC}"
        exit 0
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#categories[@]} )); then
        SELECTED_CATEGORY="${categories[$((choice-1))]}"
        return 0
    fi

    echo -e "${RED}Invalid choice. Please try again.${NC}"
    sleep 1
    select_category
}

select_agents() {
    local category="$1"
    local category_name
    category_name=$(get_category_name "$category")

    local agents=()
    local states=()

    if [[ "$SOURCE_MODE" == "remote" ]]; then
        show_header
        echo -e "${BOLD}Category: ${CYAN}$category_name${NC}\n"
        echo -e "${CYAN}Fetching agents from GitHub...${NC}\n"
        if ! fetch_agents_remote "$category"; then
            echo -e "${RED}Failed to fetch agents. Press Enter to go back.${NC}"
            read -r
            return 1
        fi

        for agent_file in "${REMOTE_AGENTS[@]}"; do
            agents+=("$agent_file")
            if is_agent_installed "$agent_file"; then
                states+=(1)
            else
                states+=(0)
            fi
        done
    else
        local category_path="$CATEGORIES_DIR/$category"
        for file in "$category_path"/*.md; do
            local base
            base=$(basename "$file")
            if [[ "$base" != "README.md" ]]; then
                agents+=("$base")
                if is_agent_installed "$base"; then
                    states+=(1)
                else
                    states+=(0)
                fi
            fi
        done
    fi

    while true; do
        show_header
        echo -e "${BOLD}Category: ${CYAN}$category_name${NC}\n"
        echo -e "Use number keys to toggle. ${GREEN}[✓]${NC} = install, ${RED}[ ]${NC} = uninstall\n"

        local i=1
        for agent_file in "${agents[@]}"; do
            local installed=""
            local status_icon="[ ]"
            local status_color="$RED"

            if is_agent_installed "$agent_file"; then
                installed=" ${BLUE}(installed)${NC}"
            fi

            if [[ ${states[$((i-1))]} -eq 1 ]]; then
                status_icon="[✓]"
                status_color="$GREEN"
            fi

            echo -e "  ${YELLOW}$i)${NC} ${status_color}${status_icon}${NC} ${agent_file%.md}${installed}"
            ((i++))
        done

        echo ""
        echo -e "  ${YELLOW}a)${NC} Select all"
        echo -e "  ${YELLOW}n)${NC} Deselect all"
        echo -e "  ${YELLOW}c)${NC} Confirm selection"
        echo -e "  ${YELLOW}b)${NC} Back to categories"
        echo -e "  ${YELLOW}q)${NC} Quit"
        echo ""

        read -p "Enter your choice: " choice
        case "$choice" in
            [0-9]*)
                if (( choice >= 1 && choice <= ${#agents[@]} )); then
                    local idx=$((choice-1))
                    if [[ ${states[$idx]} -eq 1 ]]; then
                        states[$idx]=0
                    else
                        states[$idx]=1
                    fi
                fi
                ;;
            a|A)
                for i in "${!states[@]}"; do states[$i]=1; done
                ;;
            n|N)
                for i in "${!states[@]}"; do states[$i]=0; done
                ;;
            c|C)
                confirm_and_apply "$category" "${agents[*]}" "${states[*]}"
                return
                ;;
            b|B)
                return 1
                ;;
            q|Q)
                echo -e "\n${GREEN}Goodbye!${NC}"
                exit 0
                ;;
        esac
    done
}

confirm_and_apply() {
    local category="$1"
    local agents_list="$2"
    local states_list="$3"

    IFS=' ' read -ra agents <<< "$agents_list"
    IFS=' ' read -ra states <<< "$states_list"

    local to_install=()
    local to_uninstall=()

    for i in "${!agents[@]}"; do
        local agent_file="${agents[$i]}"
        local selected="${states[$i]}"
        local installed=0
        if is_agent_installed "$agent_file"; then
            installed=1
        fi

        if [[ $installed -eq 0 && $selected -eq 1 ]]; then
            to_install+=("$agent_file")
        elif [[ $installed -eq 1 && $selected -eq 0 ]]; then
            to_uninstall+=("$agent_file")
        fi
    done

    show_header
    echo -e "${BOLD}Confirmation${NC}\n"

    if [[ ${#to_install[@]} -eq 0 && ${#to_uninstall[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No changes to apply.${NC}\n"
        read -p "Press Enter to continue..."
        return
    fi

    if [[ ${#to_install[@]} -gt 0 ]]; then
        echo -e "${GREEN}Skills to install (${#to_install[@]}):${NC}"
        for item in "${to_install[@]}"; do
            echo -e "  ${GREEN}+${NC} ${item%.md}"
        done
        echo ""
    fi

    if [[ ${#to_uninstall[@]} -gt 0 ]]; then
        echo -e "${RED}Skills to uninstall (${#to_uninstall[@]}):${NC}"
        for item in "${to_uninstall[@]}"; do
            echo -e "  ${RED}-${NC} ${item%.md}"
        done
        echo ""
    fi

    read -p "Apply these changes? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}Changes cancelled.${NC}"
        echo ""
        read -p "Press Enter to continue..."
        return
    fi

    echo ""
    for agent_file in "${to_install[@]}"; do
        install_agent_skill "$category" "$agent_file"
    done

    for agent_file in "${to_uninstall[@]}"; do
        uninstall_agent_skill "$agent_file"
    done

    echo ""
    echo -e "${GREEN}${BOLD}Changes applied successfully!${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

main() {
    select_install_mode
    select_source_mode
    while true; do
        select_category
        while select_agents "$SELECTED_CATEGORY"; do
            :
        done
    done
}

main
