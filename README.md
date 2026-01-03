# quicue

CUE vocabulary for infrastructure-as-graph.

[Graph Explorer](https://quicue.ca/) | [GitHub](https://github.com/quicue/quicue)

## The Problem

You have servers, containers, and services that depend on each other. You need to answer:

- "If dns-primary fails, what breaks?"
- "What's the startup order for this cluster?"
- "Show me the dependency graph"

These questions require understanding your infrastructure as a **graph**. But that graph lives in your head, scattered across Terraform, Ansible, wikis, and tribal knowledge.

## The Solution

quicue makes the graph explicit. Define it once in CUE, query it:

```cue
import "quicue.ca/patterns@v0"

_resources: {
    "pve-node":    {name: "pve-node", "@type": ["VirtualizationPlatform"]}
    "dns-primary": {name: "dns-primary", "@type": ["DNSServer"], depends_on: ["pve-node"]}
    "git-server":  {name: "git-server", "@type": ["SourceControlManagement"], depends_on: ["dns-primary"]}
}

infra: patterns.#InfraGraph & {Input: _resources}
// infra.topology, infra.roots, infra.leaves

impact: patterns.#ImpactQuery & {Graph: infra, Target: "dns-primary"}
// impact.affected = ["git-server"]
```

## Quick Start

```bash
git clone https://github.com/quicue/quicue.git && cd quicue
./quicue eval
```

Output:

```cue
topology: {
    layer_0: {"pve-node": true}
    layer_1: {"dns-primary": true}
    layer_2: {"reverse-proxy": true, monitoring: true}
    layer_3: {"git-server": true}
}
roots:  ["pve-node"]
leaves: ["git-server", "monitoring"]
impact_if_dns_fails: {
    affected: ["reverse-proxy", "git-server", "monitoring"]
}
```

## Structure

| Directory | Contains |
|-----------|----------|
| [vocab/](vocab/) | `#Resource`, `#Action`, `#TypeRegistry`, JSON-LD `@context` |
| [patterns/](patterns/) | `#InfraGraph`, `#ImpactQuery`, `#CriticalityRank`, `#ValidateGraph`, ... |
| [examples/](examples/) | Working demos |

## Examples

| Example | What it shows | Command |
|---------|---------------|---------|
| [graph-patterns](examples/graph-patterns/) | Topology, impact, criticality, validation | `./quicue eval` |
| [multi-region](examples/multi-region/) | 22-node multi-root, diamond deps, 6 layers | `./quicue eval multi-region` |
| [3-layer](examples/3-layer/) | Interface → Provider → Instance pattern | `./quicue eval 3-layer` |
| [type-composition](examples/type-composition/) | Actions derived from `@type` arrays | `./quicue eval type-composition` |
| [jsonld-export](examples/jsonld-export/) | JSON-LD for semantic web / RDF tools | `./quicue export jsonld-export` |

## Graph Patterns

See [examples/graph-patterns/README.md](examples/graph-patterns/README.md) for full reference.

| Pattern | Purpose |
|---------|---------|
| `#InfraGraph` | Build graph, compute topology/roots/leaves |
| `#ImpactQuery` | What breaks if X fails? |
| `#DependencyChain` | Path from resource to root |
| `#CriticalityRank` | Rank by dependent count |
| `#ValidateGraph` | Check for missing deps, cycles, empty types |

## Prerequisites

[CUE](https://cuelang.org/docs/introduction/installation/) v0.15+

## License

MIT
