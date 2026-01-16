# Hybrid Python/CUE Graph Computation

Exploration of performance characteristics and hybrid approaches for graph traversal in CUE.

## Problem

CUE's recursive field access for computing `_depth` and `_ancestors` is O(n^2) for graphs with deep dependency chains. This becomes prohibitive at modest scales.

## Performance Results

### Synthetic Linear Chain (worst case)

| Nodes | CUE-only | Python+CUE | Speedup |
|-------|----------|------------|---------|
| 10    | 0.02s    | 0.006s     | 3x      |
| 14    | 2.0s     | 0.006s     | 333x    |
| 15    | 8.1s     | 0.005s     | 1620x   |
| 16    | 47.3s    | 0.005s     | 9460x   |
| 18    | >60s     | 0.005s     | -       |

### Python+CUE at Scale

| Nodes  | Time   |
|--------|--------|
| 1,000  | 0.02s  |
| 5,000  | 0.11s  |
| 10,000 | 0.31s  |

### Real Infrastructure (multi-region, 22 nodes with diamond deps)

| Mode       | Time    |
|------------|---------|
| CUE-only   | >120s   |
| Python+CUE | 5.8s    |

The 5.8s is `_ancestors` computation in CUE (kept for validation). `_depth` precompute was 0.013s.

Diamond dependencies are worse than linear chains - more transitive closure paths.

## Key Insights

### 1. The Unification Pattern is Syntax, Not Performance

The rogpeppe/eloip pattern from CUE Slack:
```cue
_ancestors: {
    [_]: true
    if _hasDeps {
        for d, _ in _deps {
            (d): true
            resources[d]._ancestors
        }
    }
}
```

This is cleaner than explicit iteration but has the same O(n^2) complexity. The recursive `resources[d]._ancestors` access is the bottleneck.

### 2. Validation is Lazy

```cue
resources[d]._depth      // Doesn't validate bad deps
resources[d]._ancestors  // Validates (forces evaluation)
```

Even in CUE-only mode, bad dependency references aren't caught unless you access `_ancestors`. This isn't a Python trade-off.

### 3. Python Gives Better Cycle Detection

- CUE: hangs forever on cycles
- Python: explicit `graphlib.CycleError` with cycle path

### 4. The Trade-off Matrix

| Need                  | Approach                    | Validation |
|-----------------------|-----------------------------|------------|
| Topology/ordering     | Precompute `_depth`         | Preserved  |
| Impact analysis       | Keep `_ancestors` in CUE    | Preserved  |
| Maximum speed         | Precompute both             | Lost       |

### 5. Struct-as-Set Pattern

```cue
depends_on: {foo: true}  // O(1) lookup
depends_on: ["foo"]      // O(n) with list.Contains
```

### 6. Graph Shape Matters

Wide trees (depth ~10) are 10x faster than linear chains. Diamond dependencies create more transitive paths than node count suggests.

## Solution: Conditional Precompute

```cue
Precomputed?: depth: [string]: int

_depth: [
    if Precomputed != _|_ && Precomputed.depth[name] != _|_ {
        Precomputed.depth[name]
    },
    if _hasDeps {list.Max([for d, _ in _deps {resources[d]._depth}]) + 1},
    0,
][0]
```

- Works CUE-only for small graphs
- Accepts Python-precomputed values for large graphs
- Falls back gracefully

## Files

- `examples/hybrid-demo/hybrid.cue` - Complete working example (80 lines)
- `examples/hybrid-demo/precompute.py` - Python depth computation
- `bin/precompute.py` - Standalone precompute script
- `bin/quicue` - CLI with `--precompute` and `--compare` flags

## Usage

```bash
# CUE-only (small graphs)
cue eval ./examples/hybrid-demo/ -e output

# With precompute (large graphs)
./bin/quicue eval hybrid-demo --precompute

# Compare both modes
./bin/quicue eval hybrid-demo --compare
```

## Practical Recommendations

- **<15 nodes (linear) or <100 nodes (wide tree):** CUE-only is fine
- **Larger, topology/ordering only:** Precompute `_depth`
- **Larger, need impact analysis:** Precompute `_depth`, accept slower `_ancestors` for validation
- **Maximum performance, no validation needed:** Precompute both in Python

## References

- CUE Slack discussion with rogpeppe and eloip on unification patterns
- `patterns/graph.cue` header for performance notes
