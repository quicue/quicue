#!/usr/bin/env python3
"""Pre-compute graph depth values for large infrastructures.

Uses Python's graphlib.TopologicalSorter for O(n+e) computation vs CUE's O(n^2).
Output is JSON that CUE can consume via the Precomputed field.

Usage:
    cue export . -e Input --out json | python precompute.py
    # Outputs: {"depth": {"pve": 0, "dns": 1, "web": 2}}
"""
import json
import sys
from graphlib import TopologicalSorter, CycleError


def compute_depths(resources: dict) -> dict:
    """Compute _depth for each resource using topological sort.

    Args:
        resources: Dict of resource name -> resource data with optional depends_on

    Returns:
        Dict with "depth" mapping resource names to their depth (0 = root)
    """
    # Build dependency graph: resource -> set of dependencies
    graph = {}
    for name, r in resources.items():
        deps = r.get("depends_on", {})
        # Handle both {dep: true} struct and ["dep"] array formats
        if isinstance(deps, dict):
            graph[name] = set(deps.keys())
        elif isinstance(deps, list):
            graph[name] = set(deps)
        else:
            graph[name] = set()

    # Topological sort gives us order from roots to leaves
    try:
        ts = TopologicalSorter(graph)
        depths = {}
        for name in ts.static_order():
            deps = graph.get(name, set())
            if not deps:
                depths[name] = 0
            else:
                depths[name] = max(depths[d] for d in deps) + 1
        return {"depth": depths}
    except CycleError as e:
        # Report cycle for debugging
        print(f"Error: Cycle detected in dependency graph: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    """Read resources from stdin, output computed depths as JSON."""
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
        sys.exit(1)

    # Handle both raw resources and wrapped {Input: resources} format
    if "Input" in data:
        resources = data["Input"]
    else:
        resources = data

    result = compute_depths(resources)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
