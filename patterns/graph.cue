// Graph patterns for infrastructure dependency analysis.
//
// Supports string-based depends_on (portable, JSON-compatible) or
// reference-based depends_on (CUE refs for free traversal).
//
// Computes: _depth, _ancestors, _path, topology, roots, leaves.
// Assumes DAG. _path follows first parent only.

package patterns

import "list"

// #GraphResource - Schema for resources with computed graph properties
// Use this when you want automatic depth, ancestors, etc.
#GraphResource: {
	name: string
	"@type": [...string]

	// Optional fields - use generic names (providers map to platform-specific)
	ip?:           string
	host?:         string // Hypervisor/node (Proxmox node, Docker host, K8s node)
	container_id?: int | string // Container identifier
	vm_id?:        int | string // VM identifier
	fqdn?:         string
	ssh_user?:     string
	provides?: [...string]
	tags?: [...string]
	description?: string

	// Dependencies - strings (portable) or refs (free traversal)
	depends_on?: [...string] | [...#GraphResource]

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
	_inputNames: {for n, _ in Input {(n): true}}
	_missingDepsNested: [
		for rname, r in Input if r.depends_on != _|_ {
			[for dep in r.depends_on if _inputNames[dep] == _|_ {
				{resource: rname, missing: dep}
			}]
		},
	]
	_missingDeps: list.FlattenN(_missingDepsNested, 1)
	// Expose validation status (check this before using graph)
	valid: len(_missingDeps) == 0

	// Output: ref-based resources with computed graph properties
	resources: {
		for rname, r in Input {
			(rname): r & {
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
							(d): true
							for a, _ in resources[d]._ancestors {(a): true}
						}
					}
				}

				// Path: route to root via FIRST parent only
				// NOTE: For multi-parent DAGs, use _ancestors for complete closure
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
			"layer_\(r._depth)": (rname): true
		}
	}

	// Computed: root nodes (no dependencies)
	roots: [for rname, r in resources if r._depth == 0 {rname}]

	// Computed: leaf nodes (nothing depends on them)
	_hasDependents: {
		for _, r in resources if r.depends_on != _|_ {
			for d in r.depends_on {(d): true}
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
	Graph:  #InfraGraph
	Target: string

	affected: [
		for rname, r in Graph.resources
		if r._ancestors[Target] != _|_ {rname},
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
	Graph:  #InfraGraph
	Target: string

	path:  Graph.resources[Target]._path
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

	// Build groups using struct accumulation (avoids empty entries from nested for)
	_byType: {
		for rname, r in Graph.resources {
			for t in r["@type"] {
				(t): (rname): true
			}
		}
	}

	groups: {
		for typeName, members in _byType {
			(typeName): [for m, _ in members {m}]
		}
	}

	counts: {
		for typeName, members in groups {
			(typeName): len(members)
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
				if r._ancestors[rname] != _|_ {r.name},
			])
		},
	]
}

// #ImmediateDependents - Find resources that directly depend on target
//
// Usage:
//   deps: #ImmediateDependents & {Graph: infra, Target: "dns"}
//   // deps.dependents = ["proxy", "git"] (only direct, not transitive)
//
#ImmediateDependents: {
	Graph:  #InfraGraph
	Target: string

	dependents: [
		for rname, r in Graph.resources
		if r.depends_on != _|_
		for d in r.depends_on
		if d == Target {rname},
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
		for _ in r.depends_on {1},
	])
}

// #ExportGraph - Export graph with clean IDs for external consumption
//
// Usage:
//   export: #ExportGraph & {Graph: infra}
//   // export.resources = [{name: "dns", depends_on: ["pve"], ...}, ...]
//
#ExportGraph: {
	Graph: #InfraGraph

	// Export resources as flat list with string references (no CUE refs)
	resources: [
		for rname, r in Graph.resources {
			name:    rname
			"@type": r["@type"]
			if r.ip != _|_ {ip: r.ip}
			if r.host != _|_ {host: r.host}
			if r.depends_on != _|_ {depends_on: r.depends_on}
			depth: r._depth
			ancestors: [for a, _ in r._ancestors {a}]
		},
	]

	// Compute max_depth from exported resources (avoids hidden field access issues)
	_depths: [for r in resources {r.depth}]

	// Summary metrics
	summary: {
		total:     len(resources)
		roots:     Graph.roots
		leaves:    Graph.leaves
		max_depth: *list.Max(_depths) | 0
	}
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

	_names: {for n, _ in Input {(n): true}}

	// Check for missing dependency references
	_missingDeps: [
		for rname, r in Input
		if r.depends_on != _|_
		for dep in r.depends_on
		if _names[dep] == _|_ {
			resource: rname
			missing:  dep
		},
	]

	// Check for self-references
	_selfRefs: [
		for rname, r in Input
		if r.depends_on != _|_
		for dep in r.depends_on
		if dep == rname {
			resource: rname
		},
	]

	// Check for empty @type
	_emptyTypes: [
		for rname, r in Input
		if len(r["@type"]) == 0 {
			resource: rname
		},
	]

	issues: {
		missing_dependencies: _missingDeps
		self_references:      _selfRefs
		empty_types:          _emptyTypes
	}

	valid: len(_missingDeps) == 0 && len(_selfRefs) == 0 && len(_emptyTypes) == 0
}
