# quicue

**Your infrastructure as a CUE value. Dependencies become traversable edges.**

[Interactive Explorer](https://quicue.ca) · [Examples](examples/) · [Patterns](#patterns)

## The Idea

```cue
resources: {
    "region":  {"@type": {Region: true}}
    "dns":     {"@type": {DNSServer: true},    depends_on: {"region": true}}
    "auth":    {"@type": {AuthServer: true},   depends_on: {"region": true}}
    "db":      {"@type": {Database: true},     depends_on: {"dns": true, "auth": true}}
    "cache":   {"@type": {CacheCluster: true}, depends_on: {"dns": true}}
    "api":     {"@type": {APIServer: true},    depends_on: {"db": true, "cache": true}}
    "web":     {"@type": {WebFrontend: true},  depends_on: {"api": true}}
}
```

That's a graph with diamond dependencies. CUE makes `depends_on` traversable:

```cue
import "quicue.ca/patterns@v0"

infra: patterns.#InfraGraph & {Input: resources}

infra.topology
// layer_0: ["region"]
// layer_1: ["dns", "auth"]
// layer_2: ["db", "cache"]
// layer_3: ["api"]
// layer_4: ["web"]
```

## What Falls Out

Now ask questions that would be tedious to answer by inspection:

```cue
// "What breaks if dns fails?"
impact: patterns.#ImpactQuery & {Graph: infra, Target: "dns"}
impact.affected  // ["db", "cache", "api", "web"] - 4 resources, not obvious!

// "What should we protect most?"
crit: patterns.#CriticalityRank & {Graph: infra}
crit.ranked  // [{name: "region", dependents: 6}, {name: "dns", dependents: 4},
             //  {name: "auth", dependents: 3}, ...]

// "dns is down - what's the status of everything?"
health: patterns.#HealthStatus & {Graph: infra, Status: {"dns": "down"}}
health.propagated
// region: "healthy", dns: "down", auth: "healthy",
// db: "degraded", cache: "degraded", api: "degraded", web: "degraded"

// "Safe startup order?"
deploy: patterns.#DeploymentPlan & {Graph: infra}
deploy.startup_sequence   // ["region", "dns", "auth", "db", "cache", "api", "web"]
deploy.shutdown_sequence  // ["web", "api", "cache", "db", "auth", "dns", "region"]
```

If it evals, the graph is valid. All dependencies exist. All constraints satisfied.

## One Application: Type-Driven Actions

Resources have semantic types. Types can grant actions:

```cue
"dns-server": {
    "@type": {DNSServer: true, LXCContainer: true}
    ip:           "10.0.1.10"
    container_id: 100
    host:         "pve-node"
}
// DNSServer + ip field        → check_dns action
// LXCContainer + container_id → console, logs actions
```

The pattern: define what actions each type grants, let CUE unify them with resource fields. See [type-composition](examples/type-composition/) and [3-layer](examples/3-layer/).

## Getting Started

### 1. Install CUE

```bash
# macOS
brew install cue-lang/tap/cue

# Linux (or download from https://cuelang.org/docs/introduction/installation/)
curl -sSL https://cuelang.org/go/cmd/cue@latest | go install
```

### 2. Create a New Project

```bash
mkdir my-infra && cd my-infra
cue mod init mycompany.com/infra
```

### 3. Add quicue as a Dependency

```cue
// cue.mod/module.cue
module: "mycompany.com/infra"
language: version: "v0.15.3"
```

### 4. Define Your Infrastructure

```cue
// infra.cue
package infra

import "quicue.ca/patterns@v0"

resources: {
    "dns":   {"@type": {DNSServer: true}, ip: "10.0.1.10"}
    "db":    {"@type": {Database: true}, depends_on: {"dns": true}, url: "postgres://10.0.1.20"}
    "api":   {"@type": {APIServer: true}, depends_on: {"db": true}, url: "http://10.0.1.30"}
}

infra: patterns.#InfraGraph & {Input: resources}

// Now query it:
// cue eval . -e infra.topology
// cue eval . -e '(patterns.#ImpactQuery & {Graph: infra, Target: "dns"}).affected'
```

## Quick Start (Examples)

```bash
git clone https://github.com/quicue/quicue.git && cd quicue
./bin/quicue eval              # graph-patterns example
./bin/quicue eval multi-region # 22-node complex graph
./bin/quicue list              # all examples
```

## Terminal Visualization

```bash
# Pretty statistics
./bin/quicue-gum stats ./examples/graph-patterns

# Fuzzy finder with preview
./bin/quicue-fzf ./examples/graph-patterns
```

## Structure

```
patterns/  #InfraGraph, #ImpactQuery, #CriticalityRank, #ValidateGraph
vocab/     #Resource, #Action, #TypeRegistry, JSON-LD @context
examples/  Working demos (all visualized at quicue.ca)
bin/       CLI tool
docs/      API reference, architecture docs
site/      GitHub Pages + visualization data
scripts/   Development tooling
```

## Examples

| Example | Shows |
|---------|-------|
| [graph-patterns](examples/graph-patterns/) | Topology, impact, criticality |
| [multi-region](examples/multi-region/) | 22 nodes, diamond deps, 6 layers |
| [type-composition](examples/type-composition/) | Actions derived from `@type` arrays |
| [provider-demo](examples/provider-demo/) | Swappable providers (Proxmox/Docker) |
| [3-layer](examples/3-layer/) | Interface → Provider → Instance |
| [jsonld-export](examples/jsonld-export/) | Semantic web / RDF export |
| [operational](examples/operational/) | Deployment gates, blast radius, health propagation |
| [dependents-pattern](examples/dependents-pattern/) | O(n²) vs O(n³) dependent computation |

## Patterns

From `quicue.ca/patterns@v0`:

**Graph Analysis:**
| Pattern | Returns |
|---------|---------|
| `#InfraGraph` | `topology`, `roots`, `leaves`, per-resource `_depth`/`_ancestors` |
| `#ImpactQuery` | `affected` list when target fails |
| `#CriticalityRank` | Resources ranked by dependent count |
| `#DependencyChain` | Full path from resource to root |
| `#GroupByType` | Resources grouped by `@type` |
| `#ValidateGraph` | Missing deps, self-refs, empty types |

**Operations:**
| Pattern | Returns |
|---------|---------|
| `#DeploymentPlan` | `layers` with gates, `startup_sequence`, `shutdown_sequence` |
| `#BlastRadius` | `affected`, `rollback_order`, `startup_order`, `safe_peers` |
| `#HealthStatus` | `propagated` status (healthy/degraded/down) |
| `#RollbackPlan` | `sequence` to rollback from failed layer |
| `#SinglePointsOfFailure` | `risks` - critical resources with no redundancy |

## CLI

```bash
./bin/quicue eval [example]   # Evaluate (default: graph-patterns)
./bin/quicue export [example] # Export as JSON
./bin/quicue vet [path]       # Validate CUE files
./bin/quicue list             # List examples
./bin/quicue context          # JSON-LD @context
./bin/quicue mermaid          # Mermaid diagram
```

## Use in Your Project

```cue
import "quicue.ca/patterns@v0"

_resources: {
    "db":    {"@type": {Database: true}}
    "cache": {"@type": {CacheCluster: true}}
    "api":   {"@type": {APIServer: true}, depends_on: {"db": true, "cache": true}}
    "web":   {"@type": {WebFrontend: true}, depends_on: {"api": true}}
}

infra: patterns.#InfraGraph & {Input: _resources}
// topology, roots, leaves, per-resource _depth/_ancestors

impact: patterns.#ImpactQuery & {Graph: infra, Target: "db"}
// impact.affected = ["api", "web"]
```

## Providers

Platform-specific action generators:

| Provider | Platform |
|----------|----------|
| [quicue-proxmox](https://github.com/quicue/quicue-proxmox) | Proxmox VE (LXC, VMs) |
| [quicue-docker](https://github.com/quicue/quicue-docker) | Docker (containers, compose) |

## Prerequisites

[CUE](https://cuelang.org/docs/introduction/installation/) v0.15+

## License

MIT
