# Dependents Pattern

Efficient computation of "who depends on X?" for all nodes.

## The Problem

Computing blast radius via N pattern instantiations is slow:

```cue
// SLOW: ~3s for 100 nodes, ~60s for 300 nodes
allBlastRadius: {
    for name, _ in graph.nodes {
        (name): #BlastRadius & {Graph: graph, Target: name}
    }
}
```

The bottleneck is **pattern instantiation overhead**, not the O(n^2) algorithm:
- `Graph: #Graph` constraint re-verified N times
- Each `#Pattern & {...}` creates new evaluation context

## The Fix

Pre-compute dependents inside the graph definition:

```cue
#Graph: {
    nodes: { /* ... _ancestors ... */ }

    // Pre-compute ALL dependents in one pass (memoized)
    dependents: {
        for t, _ in nodes {
            (t): [for n, r in nodes if r._ancestors[t] != _|_ {n}]
        }
    }
}

// Then: O(1) lookup
db_impact: graph.dependents["db"]
```

## Results

| Nodes | Before | After | Speedup |
|-------|--------|-------|---------|
| 100   | 3s     | 0.03s | 100x    |
| 200   | 12s    | 0.07s | 170x    |

## Run

```bash
cue eval -e output .
```

## Output

```
db_impact: ["api", "web", "mobile", "worker"]
api_impact: ["web", "mobile"]
```

## TL;DR

> Don't instantiate N patterns with `#Graph` constraints. Pre-compute derived properties inside the graph definition.
