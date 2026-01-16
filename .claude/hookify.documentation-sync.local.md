---
name: documentation-sync
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: (module\.cue|cue\.mod/module\.cue|\.cue$)
  - field: new_text
    operator: regex_match
    pattern: (@v[0-9]+\.[0-9]+|version:|module:)
---

<!-- RULE VERIFICATION: This rule is CUE-specific.
     For non-CUE projects, set enabled: false or delete this file.
     For other languages, adapt the file_path pattern (e.g., package.json, Cargo.toml). -->

**Documentation Sync Reminder**

You're modifying CUE module configuration or version information.

**Check if these need updates:**

1. **CLAUDE.md** - Registry section lists published modules
2. **MCP Memory Graph** - Version entities may need updating
3. **Serena Memories** - Project-specific version info

**After publishing to registry:**
```bash
CUE_REGISTRY=172.20.1.220:5000/quicue+insecure cue mod publish vX.Y.Z
```
Update CLAUDE.md's "Published modules" section.
