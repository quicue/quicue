# Quicue Architecture

## Overview

Quicue models infrastructure as a graph where resources are nodes and dependencies are edges. CUE's constraint system validates the graph at compile time.

## Component Diagram

```mermaid
graph TB
    subgraph "quicue (Core)"
        vocab[vocab/]
        patterns[patterns/]
        examples[examples/]
    end

    subgraph "Providers"
        proxmox[quicue-proxmox]
        docker[quicue-docker]
    end

    subgraph "Tooling"
        ci[quicue-ci]
        demo[quicue-demo]
    end

    vocab --> patterns
    patterns --> examples
    vocab --> proxmox
    vocab --> docker
    patterns --> demo
    ci --> proxmox
    ci --> docker
```

## Data Flow

```mermaid
flowchart LR
    A[Define Resources] --> B[#InfraGraph]
    B --> C{Computed Properties}
    C --> D[topology]
    C --> E[roots/leaves]
    C --> F[_ancestors]
    C --> G[dependents]

    F --> H[#ImpactQuery]
    G --> I[O(1) lookups]
    D --> J[#DeploymentPlan]
```

## Core Modules

### vocab/
Base schemas and type registry.

| File | Purpose |
|------|---------|
| `resource.cue` | `#Resource` - base schema for all resources |
| `actions.cue` | `#Action` - schema for executable actions |
| `types.cue` | `#TypeRegistry` - semantic type catalog |
| `context.cue` | JSON-LD `@context` for semantic export |

### patterns/
Graph algorithms and query patterns.

| Pattern | Purpose |
|---------|---------|
| `#InfraGraph` | Convert resources to traversable graph |
| `#ImpactQuery` | What breaks if X fails |
| `#CriticalityRank` | Rank by dependent count |
| `#DeploymentPlan` | Layer-by-layer startup/shutdown |
| `#BlastRadius` | Change impact analysis |
| `#HealthStatus` | Status propagation |
| `#ValidateGraph` | Structural validation |

## Type System

```mermaid
graph TD
    Resource["#Resource"]

    subgraph "Semantic Types"
        DNS[DNSServer]
        Proxy[ReverseProxy]
        DB[Database]
        API[APIServer]
    end

    subgraph "Implementation Types"
        LXC[LXCContainer]
        Docker[DockerContainer]
        VM[VirtualMachine]
    end

    Resource --> DNS
    Resource --> Proxy
    Resource --> DB
    Resource --> API
    Resource --> LXC
    Resource --> Docker
    Resource --> VM
```

Resources can have multiple types via `@type`:
```cue
"dns-server": {
    "@type": {DNSServer: true, LXCContainer: true}
}
```

## Provider Architecture

Providers implement platform-specific actions for interfaces defined in vocab.

```mermaid
flowchart TB
    subgraph "vocab (interfaces)"
        VMActions["#VMActions"]
        ContainerActions["#ContainerActions"]
    end

    subgraph "quicue-proxmox"
        PVE_VM["#VMActions (qm)"]
        PVE_LXC["#ContainerActions (pct)"]
    end

    subgraph "quicue-docker"
        Docker_Container["#ContainerActions (docker)"]
    end

    VMActions -.->|implements| PVE_VM
    ContainerActions -.->|implements| PVE_LXC
    ContainerActions -.->|implements| Docker_Container
```

## Graph Computation

#InfraGraph computes these properties for each resource:

| Property | Description | Complexity |
|----------|-------------|------------|
| `_depth` | Distance from root | O(n) |
| `_ancestors` | Transitive dependencies | O(n) per resource |
| `_path` | Path to root | O(depth) |
| `dependents` | What depends on this | O(n^2) total, O(1) lookup |

## Performance Characteristics

| Operation | Time | Notes |
|-----------|------|-------|
| Validation | <0.5s | No transitive closure |
| Topology | <0.5s | Single pass |
| Impact query | O(1) | Pre-computed dependents |
| Full graph (1000 nodes) | 1-5s | Shape dependent |
