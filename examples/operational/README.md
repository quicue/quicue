# Operational Patterns

Demonstrates patterns for operational workflows beyond queries.

## Patterns

| Pattern | Purpose | Output |
|---------|---------|--------|
| `#DeploymentPlan` | Layer-by-layer startup sequence | Gates between layers |
| `#BlastRadius` | Change impact analysis | Affected resources, rollback order |
| `#HealthStatus` | Status propagation | Degraded state flows upward |
| `#RollbackPlan` | Safe rollback sequence | Reverse dependency order |
| `#SinglePointsOfFailure` | Redundancy analysis | Critical resources without peers |

## Run

```bash
cue eval ./examples/operational/ -e output
```

## Example Output

### Deployment Plan

```
layers: [
  {layer: 0, resources: ["pve-node"], gate: "Layer 0 complete..."},
  {layer: 1, resources: ["dns", "auth"], gate: "Layer 1 complete..."},
  ...
]
```

### Blast Radius (dns)

```
affected: ["db", "cache", "api", "web", "worker"]
rollback_order: ["web", "api", "worker", "db", "cache", "dns"]
safe_peers: ["auth"]
```

### Health Propagation (dns down)

```
pve-node: "healthy"
dns:      "down"
auth:     "healthy"
db:       "degraded"   # depends on dns
api:      "degraded"   # depends on db
```

### Rollback Plan (failed at layer 2)

```
rollback_order: ["web", "api", "worker", "db", "cache"]
safe: ["pve-node", "dns", "auth"]
```

### Single Points of Failure

```
risks: [
  {name: "pve-node", dependents: 7},
  {name: "dns", dependents: 5},
  ...
]
```

## Use Cases

- **Deployment orchestration**: Use gates between layers for approval/health checks
- **Change management**: Check blast radius before maintenance
- **Incident response**: Understand cascading health impact
- **Disaster recovery**: Generate safe rollback sequences
- **Architecture review**: Identify SPOFs needing redundancy
