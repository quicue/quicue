#!/bin/bash
# Load quicue JSON-LD data into Neo4j
# Requires: neo4j database running, cypher-shell installed

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration - override with environment variables
NEO4J_URI="${NEO4J_URI:-bolt://localhost:7687}"
NEO4J_USER="${NEO4J_USER:-neo4j}"
NEO4J_PASSWORD="${NEO4J_PASSWORD:-password}"
NEO4J_DATABASE="${NEO4J_DATABASE:-neo4j}"

# Export JSON-LD from CUE
echo "Exporting JSON-LD from CUE..."
JSONLD_FILE="$ROOT_DIR/.dev/jsonld-export.json"
mkdir -p "$ROOT_DIR/.dev"
cue export "$ROOT_DIR/examples/jsonld-export/" -e output --out json > "$JSONLD_FILE"

echo "Exported to: $JSONLD_FILE"

# Generate Cypher script from JSON-LD
CYPHER_FILE="$ROOT_DIR/.dev/load-graph.cypher"

cat > "$CYPHER_FILE" << 'CYPHER_HEADER'
// Auto-generated Cypher script from quicue JSON-LD export
// Clear existing data (optional - comment out to preserve)
// MATCH (n) DETACH DELETE n;

// Create constraints for unique IDs
CREATE CONSTRAINT resource_id IF NOT EXISTS FOR (r:Resource) REQUIRE r.id IS UNIQUE;

CYPHER_HEADER

# Use Node.js to parse JSON-LD and generate Cypher
node - "$JSONLD_FILE" "$CYPHER_FILE" << 'NODEJS_SCRIPT'
const fs = require('fs');
const jsonldFile = process.argv[2];
const cypherFile = process.argv[3];

const data = JSON.parse(fs.readFileSync(jsonldFile, 'utf8'));
const graph = data['@graph'] || [];

let cypher = fs.readFileSync(cypherFile, 'utf8');

// Create nodes
cypher += '\n// Create resource nodes\n';
for (const resource of graph) {
  const id = resource['@id'];
  const shortId = id.split('/').pop();
  const types = resource['@type'] || [];
  const labels = ['Resource', ...types].join(':');

  // Build properties
  const props = {
    id: id,
    shortId: shortId,
    name: resource.name || shortId
  };

  // Add optional properties
  if (resource.ip) props.ip = resource.ip;
  if (resource.fqdn) props.fqdn = resource.fqdn;
  if (resource.host) props.host = resource.host;
  if (resource.container_id) props.container_id = resource.container_id;
  if (resource.vm_id) props.vm_id = resource.vm_id;
  if (resource.ssh_user) props.ssh_user = resource.ssh_user;
  if (resource.description) props.description = resource.description;
  if (resource.provides) props.provides = resource.provides;
  if (resource.tags) props.tags = resource.tags;

  const propsStr = JSON.stringify(props).replace(/"/g, "'").replace(/'/g, '"');
  cypher += `MERGE (n:${labels} ${propsStr});\n`;
}

// Create relationships
cypher += '\n// Create dependency relationships\n';
for (const resource of graph) {
  const id = resource['@id'];
  const dependsOn = resource.depends_on || [];

  for (const dep of dependsOn) {
    const depId = dep.startsWith('http') ? dep : `https://infra.example.com/resources/${dep}`;
    cypher += `MATCH (a:Resource {id: "${id}"}), (b:Resource) WHERE b.id = "${depId}" OR b.shortId = "${dep}" MERGE (a)-[:DEPENDS_ON]->(b);\n`;
  }

  // hosted_on relationship
  if (resource.hosted_on) {
    const hostId = resource.hosted_on.startsWith('http') ? resource.hosted_on : `https://infra.example.com/resources/${resource.hosted_on}`;
    cypher += `MATCH (a:Resource {id: "${id}"}), (b:Resource) WHERE b.id = "${hostId}" OR b.shortId = "${resource.hosted_on}" MERGE (a)-[:HOSTED_ON]->(b);\n`;
  }
}

// Add topology info
if (data.topology) {
  cypher += '\n// Add topology layer information\n';
  for (const [layer, nodes] of Object.entries(data.topology)) {
    const layerNum = parseInt(layer.replace('layer_', ''));
    for (const nodeId of Object.keys(nodes)) {
      cypher += `MATCH (n:Resource {shortId: "${nodeId}"}) SET n.topology_layer = ${layerNum};\n`;
    }
  }
}

// Mark roots and leaves
if (data.roots) {
  cypher += '\n// Mark root nodes\n';
  for (const root of data.roots) {
    cypher += `MATCH (n:Resource {shortId: "${root}"}) SET n.is_root = true;\n`;
  }
}

if (data.leaves) {
  cypher += '\n// Mark leaf nodes\n';
  for (const leaf of data.leaves) {
    cypher += `MATCH (n:Resource {shortId: "${leaf}"}) SET n.is_leaf = true;\n`;
  }
}

fs.writeFileSync(cypherFile, cypher);
console.log(`Generated Cypher script: ${cypherFile}`);
NODEJS_SCRIPT

echo ""
echo "Generated Cypher script: $CYPHER_FILE"
echo ""

# Load into Neo4j
echo "Loading into Neo4j..."
if command -v cypher-shell &> /dev/null; then
    cypher-shell -a "$NEO4J_URI" -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" -d "$NEO4J_DATABASE" < "$CYPHER_FILE"
    echo "Data loaded successfully!"

    echo ""
    echo "Verifying load..."
    cypher-shell -a "$NEO4J_URI" -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" -d "$NEO4J_DATABASE" \
        "MATCH (n:Resource) RETURN count(n) as nodes; MATCH ()-[r]->() RETURN count(r) as relationships;"
else
    echo ""
    echo "cypher-shell not found. To load the data manually:"
    echo "  1. Open Neo4j Browser at http://localhost:7474"
    echo "  2. Copy and paste contents of: $CYPHER_FILE"
    echo ""
    echo "Or install cypher-shell and run:"
    echo "  cypher-shell -a $NEO4J_URI -u $NEO4J_USER -p <password> < $CYPHER_FILE"
fi
