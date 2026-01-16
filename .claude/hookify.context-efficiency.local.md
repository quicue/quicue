---
name: context-efficiency
enabled: true
event: bash
conditions:
  - field: command
    operator: regex_match
    pattern: (cat|head|tail)\s+.*\.(cue|go|ts|js|py|rs|json|yaml|yml|md|toml)
---

<!-- RULE VERIFICATION: This rule is universally applicable.
     Adjust the file extension pattern if your project uses different languages. -->

**Context Efficiency Warning**

You're using shell commands to read files. Prefer specialized tools:

**Instead of cat/head/tail, use:**
- `Read` tool - Better output formatting, line numbers
- `mcp__plugin_serena_serena__read_file` - For code with symbol awareness
- `mcp__plugin_serena_serena__get_symbols_overview` - To understand file structure first

**Why this matters:**
- Shell output lacks line numbers and formatting
- Serena tools enable follow-up symbolic operations
- Read tool handles encoding and truncation gracefully

**For exploration, use:**
- `Task` with `subagent_type=Explore` for open-ended searches
- `mcp__plugin_serena_serena__search_for_pattern` for regex searches
- `Grep` for content searches with context

**Exception:** Shell piping for data transformation is fine.
