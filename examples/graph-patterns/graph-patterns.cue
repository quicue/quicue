// Graph patterns: topology, impact, criticality, grouping
// Run: cue eval ./examples/graph-patterns/ -e output

package main

import (
	"list"
	"strings"
	"quicue.ca/patterns@v0"
)

// Sample infrastructure with dependencies
_resources: {
	"pve-node": {
		name: "pve-node"
		"@type": ["VirtualizationPlatform"]
	}
	"dns-primary": {
		name: "dns-primary"
		"@type": ["DNSServer", "CriticalInfra"]
		depends_on: ["pve-node"]
	}
	"reverse-proxy": {
		name: "reverse-proxy"
		"@type": ["ReverseProxy"]
		depends_on: ["dns-primary"]
	}
	"git-server": {
		name: "git-server"
		"@type": ["SourceControlManagement"]
		depends_on: ["dns-primary", "reverse-proxy"]
	}
	"monitoring": {
		name: "monitoring"
		"@type": ["MonitoringServer"]
		depends_on: ["dns-primary"]
	}
}

// Build the graph
infra: patterns.#InfraGraph & {Input: _resources}

// Queries
dns_impact: patterns.#ImpactQuery & {Graph: infra, Target: "dns-primary"}
criticality: patterns.#CriticalityRank & {Graph: infra}
by_type: patterns.#GroupByType & {Graph: infra}
metrics: patterns.#GraphMetrics & {Graph: infra}

// Output
output: {
	topology: infra.topology
	roots:    infra.roots
	leaves:   infra.leaves

	"impact_if_dns_fails": {
		affected: dns_impact.affected
		count:    dns_impact.affected_count
	}

	criticality_ranking: criticality.ranked
	resources_by_type:   by_type.groups

	summary: {
		total_resources: metrics.total_resources
		max_depth:       metrics.max_depth
		total_edges:     metrics.total_edges
	}
}

// Mermaid diagram
_mermaidNodes: [
	for rname, r in _resources {
		let types = strings.Join(r["@type"], ", ")
		"    \(rname)[\"\(rname)<br/><small>\(types)</small>\"]"
	},
]
_edgesNested: [
	for rname, r in _resources if r.depends_on != _|_ {
		[for dep in r.depends_on {"    \(dep) --> \(rname)"}]
	},
]
_edges: list.FlattenN(_edgesNested, 1)

mermaid: "graph TD\n" + strings.Join(_mermaidNodes, "\n") + "\n\n" + strings.Join(_edges, "\n")

// Visualization data for quicue.ca graph explorer
// Export: cue export ./examples/graph-patterns/ -e vizData --out json
_export: patterns.#ExportGraph & {Graph: infra}

// Pre-compute values for vizData
_vizEdges: list.FlattenN([
	for rname, r in _resources if r.depends_on != _|_ {
		[for dep in r.depends_on {{source: dep, target: rname}}]
	},
], 1)

_vizNodes: [
	for r in _export.resources {
		id:        r.name
		types:     r["@type"]
		depth:     r.depth
		ancestors: r.ancestors
		dependents: len([
			for other in _export.resources
			if list.Contains(other.ancestors, r.name) {1},
		])
	},
]

_vizTopology: {
	for layerName, members in infra.topology {
		(layerName): [for m, _ in members {m}]
	}
}

vizData: {
	nodes:       _vizNodes
	edges:       _vizEdges
	topology:    _vizTopology
	roots:       infra.roots
	leaves:      infra.leaves
	criticality: criticality.ranked
	byType:      by_type.groups
	metrics: {
		total:    len(_vizNodes)
		maxDepth: _export.summary.max_depth
		edges:    len(_vizEdges)
		roots:    len(infra.roots)
		leaves:   len(infra.leaves)
	}
	validation: {
		valid: infra.valid
		issues: []
	}
}
