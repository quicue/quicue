package patterns

import "list"

// Graph - Reference-based infrastructure graph with computed properties
//
// This module provides patterns for treating infrastructure as a queryable graph.
// Key insight: CUE references ARE graph edges. When you use actual CUE refs
// instead of string names, the evaluator traverses the graph for you.
//
// Two approaches:
//   1. String-based (portable): depends_on: ["dns-server"] - works with JSON import
//   2. Ref-based (powerful): depends_on: [resources.dns] - automatic traversal
//
// This module supports both via a conversion layer.
//
// LIMITATIONS:
//   - Assumes DAG (no cycle detection - CUE will error on structural cycles)
//   - _path follows first parent only (for multi-parent DAGs, use _ancestors)
//
// SECURITY:
//   - Command strings use interpolation without escaping
//   - Do NOT pass untrusted input to command parameters
//   - For user input, validate/escape at the provider level

// #GraphResource - Schema for resources with computed graph properties
// Use this when you want automatic depth, ancestors, etc.
#GraphResource: {
	name: string
	"@type": [...string]

	// Optional fields
	ip?:       string
	node?:     string
	vmid?:     int
	lxcid?:    int
	fqdn?:     string
	ssh_user?: string | *"root"
	provides?: [...string]
	tags?: [...string]
	description?: string

	// Dependencies - can be strings (portable) or refs (powerful)
	depends_on?: [...string] | [...#GraphResource]

	// Computed: reference to parent resources (set by #InfraGraph)
	_parents?: [...#GraphResource]

	// Computed: depth in dependency graph (0 = root)
	_depth: int

	// Computed: all ancestors (transitive closure)
	_ancestors: {[string]: bool}

	// Computed: path to root (via first dependency)
	_path: [...string]

	// Allow extension
	...
}

// #InfraGraph - Convert string-based resources to ref-based graph
//
// Usage:
//   _raw: { "dns": {name: "dns", depends_on: ["pve"]} }
//   infra: #InfraGraph & {Input: _raw}
//   // Now: infra.resources.dns._depth, infra.resources.dns._ancestors, etc.
//
#InfraGraph: {
	// Input: string-based resources (portable, can come from JSON)
	Input: [string]: {
		name: string
		"@type": [...string]
		depends_on?: [...string]
		...
	}

	// Validation: all dependency references must exist in Input
	_inputNames: {for n, _ in Input {"\(n)": true}}
	_validate: {
		for rname, r in Input if r.depends_on != _|_ {
			for dep in r.depends_on {
				"dep_\(rname)_\(dep)": _inputNames[dep] & true
			}
		}
	}

	// Output: ref-based resources with computed graph properties
	resources: {
		for rname, r in Input {
			"\(rname)": r & {
				// Depth: 0 for roots, max(parent depths) + 1 otherwise
				_depth: *0 | int
				if r.depends_on != _|_ {
					_depth: list.Max([for d in r.depends_on {resources[d]._depth}]) + 1
				}

				// Ancestors: transitive closure of all dependencies
				_ancestors: *{} | {[string]: bool}
				if r.depends_on != _|_ {
					_ancestors: {
						for d in r.depends_on {
							"\(d)": true
							for a, _ in resources[d]._ancestors {"\(a)": true}
						}
					}
				}

				// Path: route to root via first parent
				_path: *[rname] | [...string]
				if r.depends_on != _|_ {
					_path: list.Concat([[rname], resources[r.depends_on[0]]._path])
				}
			}
		}
	}

	// Computed: topology layers
	topology: {
		for rname, r in resources {
			"layer_\(r._depth)": "\(rname)": true
		}
	}

	// Computed: root nodes (no dependencies)
	roots: [for rname, r in resources if r._depth == 0 {rname}]

	// Computed: leaf nodes (nothing depends on them)
	_hasDependents: {
		for _, r in resources if r.depends_on != _|_ {
			for d in r.depends_on {"\(d)": true}
		}
	}
	leaves: [for rname, _ in resources if _hasDependents[rname] == _|_ {rname}]
}

// #ImpactQuery - Find all resources affected if target goes down
//
// Usage:
//   impact: #ImpactQuery & {Graph: infra, Target: "dns-primary"}
//   // impact.affected = ["git-server", "web-app", ...]
//
#ImpactQuery: {
	Graph: #InfraGraph
	Target: string

	affected: [
		for rname, r in Graph.resources
		if r._ancestors[Target] != _|_ {rname}
	]

	affected_count: len(affected)
}

// #DependencyChain - Get full dependency chain for a resource
//
// Usage:
//   chain: #DependencyChain & {Graph: infra, Target: "frontend"}
//   // chain.path = ["frontend", "web-app", "db", "pve-node"]
//
#DependencyChain: {
	Graph: #InfraGraph
	Target: string

	path: Graph.resources[Target]._path
	depth: Graph.resources[Target]._depth
	ancestors: [for a, _ in Graph.resources[Target]._ancestors {a}]
}

// #GroupByType - Group resources by @type
//
// Usage:
//   byType: #GroupByType & {Graph: infra}
//   // byType.groups.DNSServer = ["dns-primary", "dns-secondary"]
//
#GroupByType: {
	Graph: #InfraGraph

	_allTypes: {
		for _, r in Graph.resources {
			for t in r["@type"] {"\(t)": true}
		}
	}

	groups: {
		for typeName, _ in _allTypes {
			"\(typeName)": [
				for rname, r in Graph.resources {
					for t in r["@type"] if t == typeName {rname}
				}
			]
		}
	}

	counts: {
		for typeName, members in groups {
			"\(typeName)": len(members)
		}
	}
}

// #CriticalityRank - Rank resources by how many things depend on them
//
// Usage:
//   crit: #CriticalityRank & {Graph: infra}
//   // crit.ranked = [{name: "pve-node", dependents: 8}, ...]
//
#CriticalityRank: {
	Graph: #InfraGraph

	ranked: [
		for rname, _ in Graph.resources {
			name: rname
			dependents: len([
				for _, r in Graph.resources
				if r._ancestors[rname] != _|_ {r.name}
			])
		}
	]
}

// #ImmediateDependents - Find resources that directly depend on target
//
// Usage:
//   deps: #ImmediateDependents & {Graph: infra, Target: "dns"}
//   // deps.dependents = ["proxy", "git"] (only direct, not transitive)
//
#ImmediateDependents: {
	Graph: #InfraGraph
	Target: string

	dependents: [
		for rname, r in Graph.resources
		if r.depends_on != _|_
		for d in r.depends_on
		if d == Target {rname}
	]

	count: len(dependents)
}

// #GraphMetrics - Summary statistics for the graph
//
// Usage:
//   metrics: #GraphMetrics & {Graph: infra}
//   // metrics.total_resources, metrics.max_depth, etc.
//
#GraphMetrics: {
	Graph: #InfraGraph

	total_resources: len(Graph.resources)
	root_count:      len(Graph.roots)
	leaf_count:      len(Graph.leaves)
	_depths: [for _, r in Graph.resources {r._depth}]
	max_depth: *list.Max(_depths) | 0
	total_edges: len([
		for _, r in Graph.resources
		if r.depends_on != _|_
		for _ in r.depends_on {1}
	])
}

// #ValidateGraph - Validate graph structure and return issues
//
// Usage:
//   validate: #ValidateGraph & {Input: myResources}
//   // validate.valid == true if no issues
//   // validate.issues contains any problems found
//
#ValidateGraph: {
	Input: [string]: {
		name: string
		"@type": [...string]
		depends_on?: [...string]
		...
	}

	_names: {for n, _ in Input {"\(n)": true}}

	// Check for missing dependency references
	_missingDeps: [
		for rname, r in Input
		if r.depends_on != _|_
		for dep in r.depends_on
		if _names[dep] == _|_ {
			resource: rname
			missing:  dep
		}
	]

	// Check for self-references
	_selfRefs: [
		for rname, r in Input
		if r.depends_on != _|_
		for dep in r.depends_on
		if dep == rname {
			resource: rname
		}
	]

	// Check for empty @type
	_emptyTypes: [
		for rname, r in Input
		if len(r["@type"]) == 0 {
			resource: rname
		}
	]

	issues: {
		missing_dependencies: _missingDeps
		self_references:      _selfRefs
		empty_types:          _emptyTypes
	}

	valid: len(_missingDeps) == 0 && len(_selfRefs) == 0 && len(_emptyTypes) == 0
}
