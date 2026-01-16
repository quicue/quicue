#!/usr/bin/env python3
"""Pre-compute graph depth for CUE.

Usage:
    cue export . -e Input --out json | python precompute.py

Output format matches CUE's Precomputed schema:
    {"depth": {"hypervisor": 0, "dns": 1, "database": 2, ...}}
"""
import json
import sys
from graphlib import TopologicalSorter

def compute_depths(resources: dict) -> dict:
    # Build dependency graph
    graph = {name: set(r.get("depends_on", {}).keys()) for name, r in resources.items()}

    # Topological sort gives us depth in O(n+e)
    depths = {}
    for name in TopologicalSorter(graph).static_order():
        deps = graph[name]
        depths[name] = 0 if not deps else max(depths[d] for d in deps) + 1

    return {"depth": depths}

if __name__ == "__main__":
    print(json.dumps(compute_depths(json.load(sys.stdin))))
