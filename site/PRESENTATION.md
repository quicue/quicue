# quicue: Infrastructure Dependency Graphs

## The Problem

**Infrastructure changes break things.**

- "We updated the cache... and auth stopped working"
- "DNS maintenance took down 16 services"
- "Nobody knew the API depended on that queue"

**Current state:**
- Dependency knowledge lives in people's heads
- Runbooks are outdated within weeks
- Impact analysis is manual and error-prone
- CAB reviews lack systematic tooling

---

## What quicue Does

**Typed dependency graphs with computable patterns.**

```
resource "dns-primary" {
  @type: [DNSServer, CriticalInfra]
  depends_on: [pve-node]
}

resource "api" {
  @type: [APIServer]
  depends_on: [dns-primary, db, cache, auth]
}
```

From this, quicue computes:
- Transitive dependencies (ancestors)
- Blast radius (who breaks if this fails)
- Topology layers (startup/shutdown order)
- Single points of failure
- Coupling hotspots

---

## Architecture

```
+------------------+     +------------------+     +------------------+
|   LAYER 1        |     |   LAYER 2        |     |   LAYER 3        |
|   Interface      |     |   Provider       |     |   Instance       |
+------------------+     +------------------+     +------------------+
|                  |     |                  |     |                  |
|  #Resource       |     |  #ProxmoxLXC     |     |  dns-server:     |
|  #Action         | --> |  #Docker         | --> |    host: pve-1   |
|  #InfraGraph     |     |  #Kubernetes     |     |    container: 100|
|                  |     |                  |     |                  |
+------------------+     +------------------+     +------------------+
     Schema                  Templates              Concrete Values
```

**CUE unification**: Schema + Template + Values = Executable Commands

---

## Key Features (Demo)

### 1. Impact Analysis
"What breaks if dns-primary goes down?"

```
Target: dns-primary
Affected: [reverse-proxy, git-server, monitoring]
Blast radius: 3 services (60% of graph)
```

### 2. SPOF Detection
Automatically identifies single points of failure:

```
SPOF: dns-primary
  - 3 dependents
  - No redundant peer at layer 1
  - Types: [DNSServer, CriticalInfra]
```

### 3. Coupling Analysis
Finds shared dependency hotspots:

```
Coupling Point: pve-node
  - 87.5% of graph depends on this
  - Consider: multi-node cluster
```

---

## What-If Simulation

**Before making changes, simulate them.**

### Simulate Failure
```
DOWN: [dns-primary]
DEGRADED: [reverse-proxy, git-server, monitoring]
HEALTHY: [pve-node]
```

### Simulate Adding Resource
```
New: cache-replica
Types: [CacheCluster]
Dependencies: [dns-primary]

Validation:
  + Will be at layer 2
  + 1 transitive dependency
  ~ No peer at layer 2 - will be SPOF
```

---

## Web Explorer

**Interactive visualization at quicue/site/**

| Feature | Description |
|---------|-------------|
| Graph View | Cytoscape.js visualization with criticality coloring |
| Search | `/` to fuzzy search nodes by name or type |
| Layouts | Hierarchical, force-directed, circular, grid |
| Path Finder | Find dependency path between any two nodes |
| What-If | Click to simulate failures, see cascade |
| Add Resource | Click nodes to define dependencies, validate before adding |
| Export | PNG export, shareable URLs |

**Click-to-add workflow:**
1. Click `+ Add`
2. Click nodes in graph (green = selected dependency)
3. Validate (warns about SPOFs, bottlenecks)
4. Add to graph for testing

---

## Integration Points

### Input Formats
- Native CUE definitions
- JSON-LD (standard RDF format)
- CMDB exports via adapters (TopDesk, ServiceNow)

### Output Formats
- JSON with computed patterns
- Executable shell commands
- PNG/SVG diagrams
- Shareable URLs

### CLI (quicue-nu)
```bash
# Show topology
qcnu topology ./infra

# Impact analysis
qcnu impact dns-primary

# What-if simulation
qcnu diagram ./infra --down dns-primary,cache

# ASCII diagram with SPOF/coupling
qcnu diagram ./infra
```

---

## Technical Stack

| Component | Technology |
|-----------|------------|
| Schema Language | CUE (cuelang.org) |
| Visualization | Cytoscape.js |
| CLI | Nushell (quicue-nu) |
| Data Format | JSON-LD compatible |
| Computation | Client-side (no server needed) |

**Why CUE?**
- Types + values + constraints in one language
- Unification (merge partial definitions)
- Hermetic evaluation (deterministic)
- JSON superset (easy integration)

---

## Value Proposition

### For Engineers
- See what depends on what before touching it
- Validate changes before CAB
- Generate commands from single source of truth

### For Ops
- Startup/shutdown ordering is computed
- SPOF detection is automatic
- Impact radius is one click away

### For Management
- Reduced outages from dependency blindness
- Faster change approval with systematic analysis
- Documentation that stays accurate (it's the source)

---

## Current State

### Working
- Core graph patterns (#InfraGraph, #ImpactQuery, etc.)
- Web explorer with full analysis suite
- CLI diagram tool with SPOF/coupling
- JSON-LD import with client-side computation
- Multi-provider support (Proxmox, Docker)

### Roadmap
- Kubernetes provider
- Live status overlay (integrate with monitoring)
- Cost annotations
- Terraform/Pulumi import
- Git-based change tracking

---

## Demo

**Live: quicue/site/index.html**

1. Load `multi-region` example (22 nodes)
2. Press `/` to search for `auth`
3. Enable Impact Mode, click `auth` (16 services affected)
4. Go to Analysis tab, see SPOFs and coupling
5. Click `+ Add`, add `auth-replica` depending on `region-eu`
6. Validate: no longer a SPOF

---

## Questions?

**Repo:** github.com/quicue/quicue

**Key files:**
- `patterns/graph.cue` - Core patterns
- `site/index.html` - Web explorer
- `quicue-nu/bin/qcnu-diagram` - CLI tool

