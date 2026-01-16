---
name: session-context-load
enabled: true
event: prompt
conditions:
  - field: user_prompt
    operator: regex_match
    pattern: ^.{1,500}$
---

<!-- RULE VERIFICATION: This rule applies if the project uses MCP memory or Serena.
     If neither is available, set enabled: false -->

**Session Context Reminder**

Before diving into the task, ensure relevant context is loaded:

1. **Check MCP Memory Graph**: Use `mcp__memory__read_graph` or `mcp__memory__search_nodes` to find relevant entities
2. **Check Serena Memories**: Use `mcp__plugin_serena_serena__list_memories` to see project-specific memories
3. **Review CLAUDE.md**: Project instructions contain critical context

**Quick context commands:**
- `mcp__memory__search_nodes` with query related to the task
- `mcp__plugin_serena_serena__read_memory` for project-specific knowledge

Only skip if continuing an existing task with context already loaded.
