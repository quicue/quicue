---
name: sensitive-infra-data
enabled: true
event: file
conditions:
  - field: file_path
    operator: not_contains
    pattern: .local.md
  - field: new_text
    operator: regex_match
    pattern: (172\.20\.\d+\.\d+|192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+|tulip|poppy|clover|devqg|beeton|technitium|caddy|gitlab|zot|jaeger)
---

<!-- RULE VERIFICATION: This rule prevents leaking internal infrastructure details.
     Customize the IP ranges and hostnames for your environment. -->

**Sensitive Infrastructure Data Detected**

You're adding what looks like internal IP addresses or hostnames to a file that may be committed.

**Detected patterns:**
- Private IP ranges: 172.20.x.x, 192.168.x.x, 10.x.x.x
- Internal hostnames: tulip, poppy, clover, devqg, beeton, technitium, caddy, gitlab, zot, jaeger

**This data should go in:**
- `.local.md` files (gitignored)
- Serena memories (`mcp__plugin_serena_serena__write_memory`)
- MCP memory graph (`mcp__memory__create_entities`)
- Environment variables or secrets management

**If this is intentional** (e.g., example data with fake IPs), proceed carefully.
