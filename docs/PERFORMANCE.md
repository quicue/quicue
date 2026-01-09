# CUE Graph Performance

Performance characteristics for quicue patterns at scale.

## Quick Reference

| Operation | Needs Closure | Time @ 1000 nodes |
|-----------|---------------|-------------------|
| `cue vet` | No | <0.5s |
| `./quicue validate` | No | <0.5s |
| Deployment order | No | <1s |
| Group by type | No | <0.5s |
| Impact query | Yes | 1-5s |
| Criticality ranking | Yes | 1-5s |

## The Bottleneck

Computing `_ancestors` (transitive closure) is O(n²). Graph shape matters:

| Shape | 1000 nodes | Why |
|-------|------------|-----|
| Linear chain | 25s | Worst case |
| Wide tree | 1-2s | Shallow depth |
| Diamond | 3-5s | Realistic |

**Real infrastructure is wide.** Expect 1-5s, not 25s.

## Optimization Patterns

### 1. Struct over List for Membership

```cue
// Slow: O(n) scan per check
if list.Contains(r["@type"], "DNSServer") { ... }

// Fast: O(1) lookup - build set once, check many
let _types = {for t in r["@type"] {(t): true}}
if _types.DNSServer != _|_ { ... }
```

### 2. Pre-compute Dependents Once

```cue
// Slow: O(n³) - recomputes for each node
dependents: len([for other in resources if list.Contains(other.ancestors, name) {1}])

// Fast: O(n²) total - computed once, O(1) lookup
_dependentsMap: {
    for name, _ in resources {
        (name): [for other, r in resources if r._ancestors[name] != _|_ {other}]
    }
}
dependents: len(_dependentsMap[name])
```

### 3. Avoid Transitive Closure When Possible

Many operations only need direct edges or depth:
- Deployment order → `_depth`
- Validation → check `depends_on` references exist
- Grouping → iterate `@type`

Only use `_ancestors` when you actually need transitive relationships.

## CI Recommendations

```
Every commit:     cue vet + ./quicue validate     → <1s
Pre-merge:        ./quicue criticality -n 10      → 1-5s
On-demand:        ./quicue impact <node>          → 1-5s
```

## External Precomputation

For 5000+ nodes or sub-second requirements:

```bash
# Python computes closure in O(n+e), import as JSON
python3 precompute.py < graph.json | cue import json: -
```

See [cue-perf-exploration](https://github.com/quicue/cue-perf-exploration) for benchmarks.
