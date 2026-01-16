// Hybrid Python/CUE Graph Computation
//
// Problem: Both _depth and _ancestors use recursive field access, which is
// O(n^2) in CUE for linear chains (tested: 1000 nodes takes 1-5s).
//
// Solution: Pre-compute expensive values in Python, let CUE handle validation.
//
// Key points:
//   - Validation: resources[d]._ancestors fails if d doesn't exist in resources
//   - The unification pattern (rogpeppe/eloip) makes _ancestors code cleaner
//   - Python's graphlib.TopologicalSorter is O(n+e) for depth/ordering
//   - Graph shape matters: wide trees are 10x faster than linear chains
//
// Run: cue eval . -e output

package main

import "list"

// Sample infrastructure (6 nodes, diamond dependency)
Input: {
	hypervisor: {"@type": {Hypervisor: true}}
	dns:        {"@type": {DNSServer: true}, depends_on: {hypervisor: true}}
	database:   {"@type": {Database: true}, depends_on: {dns: true}}
	cache:      {"@type": {Cache: true}, depends_on: {dns: true}}
	api:        {"@type": {API: true}, depends_on: {database: true, cache: true}} // diamond
	web:        {"@type": {Frontend: true}, depends_on: {api: true}}
}

// Optional: pre-computed depth from Python (see precompute.py)
// When present, _depth uses O(1) lookup instead of O(n) recursion
Precomputed?: depth: [string]: int

// Core graph computation
resources: {
	for name, r in Input {
		let _deps = *r.depends_on | {}
		let _hasDeps = len(_deps) > 0

		(name): r & {
			// _depth: O(1) if pre-computed, O(n) if computed in CUE
			_depth: [
				if Precomputed != _|_ && Precomputed.depth[name] != _|_ {
					Precomputed.depth[name]
				},
				if _hasDeps {list.Max([for d, _ in _deps {resources[d]._depth}]) + 1},
				0,
			][0]

			// _ancestors: transitive closure via CUE unification
			// rogpeppe pattern: [_]: true declares shape, direct unification merges
			// Cleaner syntax than explicit iteration, same complexity
			// resources[d]._ancestors validates d exists - CUE fails if not
			_ancestors: {
				[_]: true
				if _hasDeps {
					for d, _ in _deps {
						(d): true
						resources[d]._ancestors
					}
				}
			}
		}
	}
}

// Output
output: {
	topology: {
		for name, r in resources {
			"layer_\(r._depth)": (name): true
		}
	}
	_byDepth: {for name, r in resources {(name): r._depth}}
	startup: list.Sort([for n, _ in Input {n}], {x: string, y: string, less: _byDepth[x] < _byDepth[y]})
	impact_dns: [for name, r in resources if r._ancestors.dns != _|_ {name}]
	ancestors: {
		web: [for a, _ in resources.web._ancestors {a}]
		api: [for a, _ in resources.api._ancestors {a}]
	}
}
