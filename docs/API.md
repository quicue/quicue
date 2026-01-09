# Quicue API Reference


## Graph Patterns (patterns/graph.cue)


### #GraphResource
Base schema for resources with computed graph properties.

```cue
#GraphResource: {
    name: string
    "@type": {[string]: true}
    depends_on?: {[string]: true}
    _depth: int           // computed
    _ancestors: {...}     // computed
    _path: [...string]    // computed
    ...
}
```


### #InfraGraph
Convert resources to traversable graph with computed topology.

```cue
import "quicue.ca/patterns@v0"

infra: patterns.#InfraGraph & {
    Input: {
        "dns": {"@type": {DNSServer: true}}
        "api": {"@type": {APIServer: true}, depends_on: {"dns": true}}
    }
}

infra.topology    // {layer_0: {dns: true}, layer_1: {api: true}}
infra.roots       // ["dns"]
infra.leaves      // ["api"]
infra.dependents  // {dns: ["api"], api: []}
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `Input` | `{[string]: #GraphResource}` | Resources to process |
| `resources` | computed | Resources with `_depth`, `_ancestors`, `_path` |
| `topology` | computed | Resources grouped by layer |
| `roots` | computed | Resources with no dependencies |
| `leaves` | computed | Resources nothing depends on |
| `dependents` | computed | Pre-computed inverse of ancestors |

---


### #ImpactQuery
Find all resources affected if target fails.

```cue
impact: patterns.#ImpactQuery & {
    Graph: infra
    Target: "dns"
}
impact.affected       // ["api", "web", ...]
impact.affected_count // 5
```

---


### #DependencyChain
Get full path from resource to root.

```cue
chain: patterns.#DependencyChain & {
    Graph: infra
    Target: "web"
}
chain.path  // ["api", "dns", "pve-node"]
chain.depth // 3
```

---


### #CriticalityRank
Rank resources by dependent count.

```cue
crit: patterns.#CriticalityRank & {
    Graph: infra
}
crit.ranked // [{name: "dns", dependents: 5}, {name: "api", dependents: 2}, ...]
```

---


### #GroupByType
Group resources by semantic type.

```cue
groups: patterns.#GroupByType & {
    Graph: infra
}
groups.groups // {DNSServer: ["dns"], APIServer: ["api"], ...}
```

---


### #ImmediateDependents
Get only direct dependents (not transitive).

```cue
deps: patterns.#ImmediateDependents & {
    Graph: infra
    Target: "dns"
}
deps.dependents // ["api", "cache"] (direct only)
```

---


### #GraphMetrics
Summary statistics for the graph.

```cue
metrics: patterns.#GraphMetrics & {
    Graph: infra
}
metrics.total_resources // 10
metrics.max_depth       // 4
metrics.total_edges     // 15
```

---


### #ValidateGraph
Validate graph structure.

```cue
validate: patterns.#ValidateGraph & {
    Input: _resources
}
validate.valid   // true/false
validate.issues  // {missing_dependencies: [...], self_references: [...], empty_types: [...]}
```

**Checks:**
- Missing dependencies
- Self-references
- Empty types

---


### #HealthStatus
Propagate health status through graph.

```cue
health: patterns.#HealthStatus & {
    Graph: infra
    Status: {"dns": "down"}
}
health.propagated // {dns: "down", api: "degraded", web: "degraded", ...}
```

**Status values:** `healthy`, `degraded`, `down`

---


### #BlastRadius
Analyze impact of changes.

```cue
blast: patterns.#BlastRadius & {
    Graph: infra
    Target: "dns"
}
blast.affected      // ["api", "web", ...]
blast.rollback_order // ["web", "api", ...]
blast.safe_peers    // ["monitoring"] (unaffected)
```

---


### #DeploymentPlan
Generate layer-by-layer deployment sequence.

```cue
deploy: patterns.#DeploymentPlan & {
    Graph: infra
}
deploy.layers            // [{layer: 0, resources: ["dns"]}, ...]
deploy.startup_sequence  // ["dns", "api", "web"]
deploy.shutdown_sequence // ["web", "api", "dns"]
```

---


### #RollbackPlan
Generate rollback sequence from failed layer.

```cue
rollback: patterns.#RollbackPlan & {
    Graph: infra
    FailedLayer: 2
}
rollback.sequence // ["web", "api"] (layers 2+ in reverse)
```

---


### #SinglePointsOfFailure
Find critical resources with no redundancy.

```cue
spof: patterns.#SinglePointsOfFailure & {
    Graph: infra
}
spof.risks // [{name: "dns", dependents: 5, reason: "single instance"}]
```

---


## Validation Patterns (patterns/validation.cue)


### #UniqueFieldValidation
Detect duplicate field values.

```cue
unique: patterns.#UniqueFieldValidation & {
    Resources: _resources
    Field: "ip"
}
unique.duplicates // {ip: [{value: "10.0.1.1", resources: ["a", "b"]}]}
```


### #ReferenceValidation
Validate references point to existing resources.

```cue
refs: patterns.#ReferenceValidation & {
    Resources: _resources
    Field: "hosted_on"
}
refs.missing // [{resource: "web", field: "hosted_on", value: "missing-host"}]
```


### #RequiredFieldsValidation
Ensure required fields present.

```cue
required: patterns.#RequiredFieldsValidation & {
    Resources: _resources
    Required: ["ip", "host"]
}
required.missing // [{resource: "dns", missing: ["host"]}]
```


### #TypeValidation
Validate @type values against registry.

```cue
types: patterns.#TypeValidation & {
    Resources: _resources
    AllowedTypes: ["DNSServer", "APIServer", ...]
}
types.invalid // [{resource: "x", invalid_types: ["FakeType"]}]
```

---


## Interface Patterns (patterns/interfaces.cue)

Provider-agnostic action contracts. All use `...` for extension.

| Interface | Required Actions |
|-----------|------------------|
| `#VMActions` | status, console, config |
| `#ContainerActions` | status, console, logs |
| `#ConnectivityActions` | ping, ssh |
| `#ServiceActions` | health, restart, logs |
| `#SnapshotActions` | list, create, revert |
| `#HypervisorActions` | list_vms, list_containers, cluster_status, storage_status |
| `#DatabaseActions` | status, connections |
| `#CostActions` | breakdown, forecast |

---


## Visualization Patterns (patterns/visualization.cue)


### #MermaidDiagram
Generate Mermaid flowchart.

```cue
mermaid: patterns.#MermaidDiagram & {
    Graph: infra
    Direction: "TB"  // TB, LR, BT, RL
}
mermaid.output // "flowchart TB\n  dns --> api\n  ..."
```


### #GraphvizDiagram
Generate Graphviz DOT.

```cue
dot: patterns.#GraphvizDiagram & {
    Resources: _resources
    Config: patterns.#GraphvizConfig
}
dot.output // "digraph G { ... }"
```


### #DependencyMatrix
Build dependency/dependent matrices.

```cue
matrix: patterns.#DependencyMatrix & {
    Resources: _resources
}
matrix.dependencies // {api: ["dns", "db"], ...}
matrix.dependents   // {dns: ["api", "web"], ...}
```
