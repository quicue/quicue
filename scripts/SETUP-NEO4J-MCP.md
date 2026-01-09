# Neo4j MCP Server Setup for Claude Code

This guide explains how to set up the Neo4j MCP server for use with Claude Code to explore quicue JSON-LD infrastructure data as a graph database.

## Prerequisites

### 1. Install Neo4j

Neo4j is not currently installed. Choose one of these installation methods:

#### Option A: Docker (Recommended for testing)

```bash
docker run -d \
  --name neo4j \
  -p 7474:7474 -p 7687:7687 \
  -e NEO4J_AUTH=neo4j/password \
  -e NEO4J_PLUGINS='["apoc"]' \
  -v neo4j-data:/data \
  neo4j:latest
```

#### Option B: Neo4j Desktop

Download from: https://neo4j.com/download/

#### Option C: Debian/Ubuntu Package

```bash
# Add Neo4j repository
wget -O - https://debian.neo4j.com/neotechnology.gpg.key | sudo apt-key add -
echo 'deb https://debian.neo4j.com stable latest' | sudo tee /etc/apt/sources.list.d/neo4j.list
sudo apt update
sudo apt install neo4j

# Start Neo4j
sudo systemctl enable neo4j
sudo systemctl start neo4j
```

#### Option D: Neo4j Aura (Cloud)

Sign up at: https://neo4j.com/cloud/aura/

### 2. Install Neo4j MCP Server

The official Neo4j MCP server is a standalone binary (not npm):

```bash
# Download latest release from GitHub
# Visit: https://github.com/neo4j/mcp/releases

# For Linux x64:
wget https://github.com/neo4j/mcp/releases/latest/download/neo4j-mcp-linux-amd64.tar.gz
tar -xzf neo4j-mcp-linux-amd64.tar.gz
sudo mv neo4j-mcp /usr/local/bin/
chmod +x /usr/local/bin/neo4j-mcp

# Verify installation
neo4j-mcp -v
```

## Configuration

### Claude Code MCP Settings

Add the Neo4j MCP server to your Claude Code configuration. The config file location depends on your setup:

- Global: `~/.claude.json` or `~/.config/claude-code/mcp.json`
- Project: `.claude/mcp.json` in your project root

Add or merge this configuration:

```json
{
  "mcpServers": {
    "neo4j": {
      "type": "stdio",
      "command": "neo4j-mcp",
      "args": [],
      "env": {
        "NEO4J_URI": "bolt://localhost:7687",
        "NEO4J_USERNAME": "neo4j",
        "NEO4J_PASSWORD": "YOUR_PASSWORD_HERE",
        "NEO4J_DATABASE": "neo4j",
        "NEO4J_READ_ONLY": "false",
        "NEO4J_TELEMETRY": "false",
        "NEO4J_LOG_LEVEL": "info"
      }
    }
  }
}
```

A sample configuration is provided at: `scripts/neo4j-mcp-config.json`

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NEO4J_URI` | Bolt connection URI | `bolt://localhost:7687` |
| `NEO4J_USERNAME` | Database username | `neo4j` |
| `NEO4J_PASSWORD` | Database password | (required) |
| `NEO4J_DATABASE` | Database name | `neo4j` |
| `NEO4J_READ_ONLY` | Restrict to read operations | `false` |

## Loading Quicue Data

Two scripts are provided for loading JSON-LD data into Neo4j:

### Bash Script

```bash
# Set password
export NEO4J_PASSWORD=your_password

# Run the loader
./scripts/load-jsonld-to-neo4j.sh
```

### Node.js Script

```bash
# Install neo4j-driver (optional, for direct loading)
npm install neo4j-driver

# Set password
export NEO4J_PASSWORD=your_password

# Run the loader
node scripts/load-jsonld-to-neo4j.js

# Or dry-run to see generated Cypher
node scripts/load-jsonld-to-neo4j.js --dry-run
```

Both scripts will:
1. Export JSON-LD from `examples/jsonld-export/` using CUE
2. Generate Cypher statements
3. Load data into Neo4j (or output for manual loading)

## Graph Schema

After loading, your Neo4j database will contain:

### Node Labels
- `Resource` - Base label for all infrastructure resources
- Type-specific labels: `LXCContainer`, `VirtualMachine`, `DNSServer`, `ReverseProxy`, etc.

### Node Properties
- `id` - Full URI (@id from JSON-LD)
- `shortId` - Short identifier (last part of URI)
- `name` - Human-readable name
- `ip` - IP address
- `host` - Host node name
- `container_id` / `vm_id` - Container or VM identifier
- `provides` - Array of capabilities
- `topology_layer` - Dependency layer (0 = no dependencies)
- `is_root` / `is_leaf` - Topology markers

### Relationships
- `DEPENDS_ON` - Dependency between resources
- `HOSTED_ON` - Hosting relationship

## Example Cypher Queries

Once loaded, try these queries in Claude Code or Neo4j Browser:

```cypher
// All resources
MATCH (n:Resource) RETURN n

// Dependency graph
MATCH (a)-[r:DEPENDS_ON]->(b) RETURN a, r, b

// Find critical infrastructure
MATCH (n:CriticalInfra) RETURN n

// What depends on DNS?
MATCH (a)-[:DEPENDS_ON*]->(dns:DNSServer)
RETURN a.name, dns.name

// Resources by topology layer
MATCH (n:Resource)
RETURN n.topology_layer, collect(n.name) as resources
ORDER BY n.topology_layer
```

## Troubleshooting

### Connection Failed
- Ensure Neo4j is running: `systemctl status neo4j` or check Docker
- Verify the Bolt port (7687) is accessible
- Check credentials

### MCP Server Not Found
- Ensure `neo4j-mcp` is in your PATH
- Check: `which neo4j-mcp`

### APOC Plugin Required
The official Neo4j MCP server requires the APOC plugin. For Docker:
```bash
-e NEO4J_PLUGINS='["apoc"]'
```

For other installations, see: https://neo4j.com/labs/apoc/

## Resources

- Neo4j MCP Server: https://github.com/neo4j/mcp
- Neo4j Documentation: https://neo4j.com/docs/
- Cypher Query Language: https://neo4j.com/docs/cypher-manual/current/
- JSON-LD Specification: https://json-ld.org/
