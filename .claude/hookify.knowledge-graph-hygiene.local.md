---
name: knowledge-graph-hygiene
enabled: true
event: stop
pattern: .*
---

<!-- RULE VERIFICATION: This rule applies if the project uses MCP memory or Serena.
     If neither is available, set enabled: false -->

**Knowledge Graph Hygiene Check**

Before stopping, consider updating the knowledge graph:

**MCP Memory Graph** (`mcp__memory__*`):
- [ ] Did you learn something reusable about this project? Create an entity
- [ ] Did you discover relationships between systems/concepts? Create relations
- [ ] Are there stale observations that should be updated or deleted?

**Serena Memories** (`mcp__plugin_serena_serena__*_memory`):
- [ ] Did you discover project-specific patterns worth remembering?
- [ ] Should any architectural decisions be documented?
- [ ] Are there command sequences that should be saved?

**Entity naming conventions:**
- Systems/services: Use actual hostname (e.g., "technitium", "caddy")
- Concepts: Use PascalCase (e.g., "ProjectName")
- Patterns: Use descriptive names (e.g., "ThreeLayerPattern")

**Skip if:** This was a trivial task with no learnings worth persisting.
