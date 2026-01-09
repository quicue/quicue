#!/usr/bin/env node
/**
 * Load quicue JSON-LD data into Neo4j using the official Neo4j JavaScript driver
 *
 * Usage:
 *   node load-jsonld-to-neo4j.js [options]
 *
 * Environment variables:
 *   NEO4J_URI       - Neo4j connection URI (default: bolt://localhost:7687)
 *   NEO4J_USER      - Neo4j username (default: neo4j)
 *   NEO4J_PASSWORD  - Neo4j password (required)
 *   NEO4J_DATABASE  - Neo4j database name (default: neo4j)
 *
 * Options:
 *   --dry-run       - Generate Cypher but don't execute
 *   --clear         - Clear existing data before loading
 *   --json-file     - Path to JSON-LD file (default: auto-export from CUE)
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

// Configuration
const config = {
  neo4jUri: process.env.NEO4J_URI || 'bolt://localhost:7687',
  neo4jUser: process.env.NEO4J_USER || 'neo4j',
  neo4jPassword: process.env.NEO4J_PASSWORD || 'password',
  neo4jDatabase: process.env.NEO4J_DATABASE || 'neo4j',
  dryRun: process.argv.includes('--dry-run'),
  clearData: process.argv.includes('--clear'),
};

const rootDir = path.resolve(__dirname, '..');
const devDir = path.join(rootDir, '.dev');

async function main() {
  // Ensure .dev directory exists
  if (!fs.existsSync(devDir)) {
    fs.mkdirSync(devDir, { recursive: true });
  }

  // Export JSON-LD from CUE
  console.log('Exporting JSON-LD from CUE...');
  const jsonldPath = path.join(devDir, 'jsonld-export.json');

  try {
    const jsonld = execSync(
      `cue export "${rootDir}/examples/jsonld-export/" -e output --out json`,
      { encoding: 'utf8' }
    );
    fs.writeFileSync(jsonldPath, jsonld);
    console.log(`Exported to: ${jsonldPath}`);
  } catch (err) {
    console.error('Failed to export JSON-LD from CUE:', err.message);
    process.exit(1);
  }

  // Parse JSON-LD
  const data = JSON.parse(fs.readFileSync(jsonldPath, 'utf8'));
  const graph = data['@graph'] || [];

  console.log(`Found ${graph.length} resources in graph`);

  // Generate Cypher statements
  const cypherStatements = [];

  if (config.clearData) {
    cypherStatements.push('MATCH (n) DETACH DELETE n');
  }

  // Create constraint
  cypherStatements.push(
    'CREATE CONSTRAINT resource_id IF NOT EXISTS FOR (r:Resource) REQUIRE r.id IS UNIQUE'
  );

  // Create nodes
  for (const resource of graph) {
    const id = resource['@id'];
    const shortId = id.split('/').pop();
    const types = resource['@type'] || [];
    const labels = ['Resource', ...types];

    const props = {
      id: id,
      shortId: shortId,
      name: resource.name || shortId,
    };

    // Add optional properties
    if (resource.ip) props.ip = resource.ip;
    if (resource.fqdn) props.fqdn = resource.fqdn;
    if (resource.host) props.host = resource.host;
    if (resource.container_id !== undefined) props.container_id = resource.container_id;
    if (resource.vm_id !== undefined) props.vm_id = resource.vm_id;
    if (resource.ssh_user) props.ssh_user = resource.ssh_user;
    if (resource.description) props.description = resource.description;
    if (resource.provides) props.provides = resource.provides;
    if (resource.tags) props.tags = resource.tags;

    const labelStr = labels.map(l => `\`${l}\``).join(':');
    const propsStr = Object.entries(props)
      .map(([k, v]) => `${k}: ${JSON.stringify(v)}`)
      .join(', ');

    cypherStatements.push(`MERGE (n:${labelStr} {${propsStr}})`);
  }

  // Create relationships
  for (const resource of graph) {
    const id = resource['@id'];
    const dependsOn = resource.depends_on || [];

    for (const dep of dependsOn) {
      const depId = dep.startsWith('http')
        ? dep
        : `https://infra.example.com/resources/${dep}`;
      cypherStatements.push(
        `MATCH (a:Resource {id: "${id}"}), (b:Resource) WHERE b.id = "${depId}" OR b.shortId = "${dep}" MERGE (a)-[:DEPENDS_ON]->(b)`
      );
    }

    if (resource.hosted_on) {
      const hostId = resource.hosted_on.startsWith('http')
        ? resource.hosted_on
        : `https://infra.example.com/resources/${resource.hosted_on}`;
      cypherStatements.push(
        `MATCH (a:Resource {id: "${id}"}), (b:Resource) WHERE b.id = "${hostId}" OR b.shortId = "${resource.hosted_on}" MERGE (a)-[:HOSTED_ON]->(b)`
      );
    }
  }

  // Add topology layer info
  if (data.topology) {
    for (const [layer, nodes] of Object.entries(data.topology)) {
      const layerNum = parseInt(layer.replace('layer_', ''));
      for (const nodeId of Object.keys(nodes)) {
        cypherStatements.push(
          `MATCH (n:Resource {shortId: "${nodeId}"}) SET n.topology_layer = ${layerNum}`
        );
      }
    }
  }

  // Mark roots and leaves
  if (data.roots) {
    for (const root of data.roots) {
      cypherStatements.push(
        `MATCH (n:Resource {shortId: "${root}"}) SET n.is_root = true`
      );
    }
  }

  if (data.leaves) {
    for (const leaf of data.leaves) {
      cypherStatements.push(
        `MATCH (n:Resource {shortId: "${leaf}"}) SET n.is_leaf = true`
      );
    }
  }

  // Write Cypher file
  const cypherPath = path.join(devDir, 'load-graph.cypher');
  fs.writeFileSync(cypherPath, cypherStatements.join(';\n') + ';\n');
  console.log(`Generated Cypher script: ${cypherPath}`);

  if (config.dryRun) {
    console.log('\n--- Dry run mode: Cypher statements ---');
    console.log(cypherStatements.join(';\n'));
    console.log('\n--- End of dry run ---');
    return;
  }

  // Try to load using neo4j-driver if available
  try {
    const neo4j = require('neo4j-driver');
    const driver = neo4j.driver(
      config.neo4jUri,
      neo4j.auth.basic(config.neo4jUser, config.neo4jPassword)
    );

    const session = driver.session({ database: config.neo4jDatabase });

    console.log(`\nConnecting to Neo4j at ${config.neo4jUri}...`);

    for (const stmt of cypherStatements) {
      try {
        await session.run(stmt);
        process.stdout.write('.');
      } catch (err) {
        console.error(`\nError executing: ${stmt}`);
        console.error(err.message);
      }
    }

    console.log('\n\nData loaded successfully!');

    // Verify
    const nodeCount = await session.run('MATCH (n:Resource) RETURN count(n) as count');
    const relCount = await session.run('MATCH ()-[r]->() RETURN count(r) as count');
    console.log(`Nodes: ${nodeCount.records[0].get('count')}`);
    console.log(`Relationships: ${relCount.records[0].get('count')}`);

    await session.close();
    await driver.close();
  } catch (err) {
    if (err.code === 'MODULE_NOT_FOUND') {
      console.log('\nneo4j-driver not installed. To load data:');
      console.log('  npm install neo4j-driver');
      console.log('  node scripts/load-jsonld-to-neo4j.js');
      console.log('\nOr use cypher-shell:');
      console.log(`  cypher-shell -a ${config.neo4jUri} -u ${config.neo4jUser} -p <password> < ${cypherPath}`);
    } else {
      console.error('Failed to connect to Neo4j:', err.message);
    }
  }
}

main().catch(console.error);
