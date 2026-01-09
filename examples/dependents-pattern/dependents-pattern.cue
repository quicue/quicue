// Efficient Dependents Query Pattern
//
// Demonstrates how to compute "who depends on X?" for all nodes efficiently.
// Key insight: pre-compute dependents inside the graph definition, not via
// N pattern instantiations.
//
// Run: cue eval -e output .
//
// Performance: 100x faster than N × #Pattern & {Graph: #Graph}
// - 100 nodes: 3s -> 0.03s
// - 200 nodes: 12s -> 0.07s
package main

import "list"

// Schema
#Node: {
	name:        string
	depends_on?: {[string]: true}
}

#Graph: {
	Input: [string]: #Node

	nodes: {
		for n, v in Input {
			let deps = *v.depends_on | {}
			(n): v & {
				_depth: [if len(deps) > 0 {list.Max([for d, _ in deps {nodes[d]._depth}]) + 1}, 0][0]
				_ancestors: {
					if len(deps) > 0 {
						for d, _ in deps {
							(d): true
							for a, _ in nodes[d]._ancestors {(a): true}
						}
					}
				}
			}
		}
	}

	// THE KEY: pre-compute dependents once (memoized)
	// Reuses _ancestors already computed above - no extra traversal
	dependents: {
		for target, _ in nodes {
			(target): [for name, node in nodes if node._ancestors[target] != _|_ {name}]
		}
	}

	roots: [for n, r in nodes if r._depth == 0 {n}]
}

// Sample infrastructure
_input: {
	db:     {name: "db"}
	cache:  {name: "cache"}
	api:    {name: "api", depends_on: {db: true, cache: true}}
	web:    {name: "web", depends_on: {api: true}}
	mobile: {name: "mobile", depends_on: {api: true}}
	worker: {name: "worker", depends_on: {db: true}}
}

graph: #Graph & {Input: _input}

// Output: O(1) lookup from pre-computed dependents
output: {
	// What breaks if db fails?
	db_impact: graph.dependents["db"]

	// What breaks if api fails?
	api_impact: graph.dependents["api"]

	// All dependents (blast radius for every node)
	all_dependents: graph.dependents

	// Stats
	node_count: len(graph.nodes)
	root_count: len(graph.roots)
}
