// Multi-region infrastructure with complex dependencies
// Tests: multi-root, diamond deps, deep chains, cross-cutting infra
//
// Run: cue eval ./examples/multi-region/ -e output

package main

import (
	"list"
	"quicue.ca/patterns@v0"
)

// Infrastructure definition
// Two regions, shared services, diamond dependencies
_resources: {
	// ═══════════════════════════════════════════════════════════════
	// Layer 0: Regions (roots)
	// ═══════════════════════════════════════════════════════════════
	"region-us": {
		name: "region-us"
		"@type": ["Region", "AvailabilityZone"]
	}
	"region-eu": {
		name: "region-eu"
		"@type": ["Region", "AvailabilityZone"]
	}

	// ═══════════════════════════════════════════════════════════════
	// Layer 1: Core infrastructure (per-region)
	// ═══════════════════════════════════════════════════════════════
	"dns-us": {
		name: "dns-us"
		"@type": ["DNSServer", "CriticalInfra"]
		depends_on: ["region-us"]
	}
	"dns-eu": {
		name: "dns-eu"
		"@type": ["DNSServer", "CriticalInfra"]
		depends_on: ["region-eu"]
	}
	"auth": {
		name: "auth"
		"@type": ["AuthServer", "CriticalInfra"]
		depends_on: ["region-us"] // Primary in US, replicated
	}

	// ═══════════════════════════════════════════════════════════════
	// Layer 2: Platform services
	// ═══════════════════════════════════════════════════════════════
	"lb-us": {
		name: "lb-us"
		"@type": ["LoadBalancer"]
		depends_on: ["dns-us", "auth"]
	}
	"lb-eu": {
		name: "lb-eu"
		"@type": ["LoadBalancer"]
		depends_on: ["dns-eu", "auth"]
	}
	"mq": {
		name: "mq"
		"@type": ["MessageQueue"]
		depends_on: ["dns-us", "auth"]
	}
	"cache": {
		name: "cache"
		"@type": ["CacheCluster"]
		depends_on: ["dns-us"]
	}

	// ═══════════════════════════════════════════════════════════════
	// Layer 3: Data tier
	// ═══════════════════════════════════════════════════════════════
	"db-primary": {
		name: "db-primary"
		"@type": ["Database", "CriticalInfra"]
		depends_on: ["dns-us", "auth"]
	}
	"db-replica": {
		name: "db-replica"
		"@type": ["Database"]
		depends_on: ["dns-eu", "db-primary"] // Cross-region replication
	}
	"search": {
		name: "search"
		"@type": ["SearchIndex"]
		depends_on: ["dns-us", "mq"]
	}

	// ═══════════════════════════════════════════════════════════════
	// Layer 4: Application tier
	// Diamond: api depends on cache AND db, both depend on dns
	// ═══════════════════════════════════════════════════════════════
	"api-us": {
		name: "api-us"
		"@type": ["APIServer"]
		depends_on: ["lb-us", "db-primary", "cache", "mq"]
	}
	"api-eu": {
		name: "api-eu"
		"@type": ["APIServer"]
		depends_on: ["lb-eu", "db-replica", "cache"]
	}
	"web-us": {
		name: "web-us"
		"@type": ["WebFrontend"]
		depends_on: ["lb-us", "api-us"]
	}
	"web-eu": {
		name: "web-eu"
		"@type": ["WebFrontend"]
		depends_on: ["lb-eu", "api-eu"]
	}

	// ═══════════════════════════════════════════════════════════════
	// Layer 5: Workers and jobs
	// ═══════════════════════════════════════════════════════════════
	"worker-ingest": {
		name: "worker-ingest"
		"@type": ["Worker"]
		depends_on: ["mq", "db-primary", "search"]
	}
	"worker-notify": {
		name: "worker-notify"
		"@type": ["Worker"]
		depends_on: ["mq", "api-us"]
	}

	// ═══════════════════════════════════════════════════════════════
	// Layer 6: Scheduled jobs (deepest)
	// ═══════════════════════════════════════════════════════════════
	"job-cleanup": {
		name: "job-cleanup"
		"@type": ["ScheduledJob"]
		depends_on: ["worker-ingest", "db-primary"]
	}
	"job-report": {
		name: "job-report"
		"@type": ["ScheduledJob"]
		depends_on: ["worker-notify", "search"]
	}

	// ═══════════════════════════════════════════════════════════════
	// Cross-cutting: Observability (depends on many, nothing depends on it)
	// ═══════════════════════════════════════════════════════════════
	"monitoring": {
		name: "monitoring"
		"@type": ["MonitoringServer"]
		depends_on: ["dns-us", "auth"]
	}
	"logging": {
		name: "logging"
		"@type": ["LogAggregator"]
		depends_on: ["dns-us", "mq"]
	}
}

// Build graph
infra: patterns.#InfraGraph & {Input: _resources}

// Validation
validate: patterns.#ValidateGraph & {Input: _resources}

// Queries
impact_dns_us: patterns.#ImpactQuery & {Graph: infra, Target: "dns-us"}
impact_auth: patterns.#ImpactQuery & {Graph: infra, Target: "auth"}
impact_db: patterns.#ImpactQuery & {Graph: infra, Target: "db-primary"}
impact_mq: patterns.#ImpactQuery & {Graph: infra, Target: "mq"}

chain_job: patterns.#DependencyChain & {Graph: infra, Target: "job-cleanup"}
chain_web: patterns.#DependencyChain & {Graph: infra, Target: "web-eu"}

immediate_dns: patterns.#ImmediateDependents & {Graph: infra, Target: "dns-us"}
immediate_auth: patterns.#ImmediateDependents & {Graph: infra, Target: "auth"}

criticality: patterns.#CriticalityRank & {Graph: infra}
by_type: patterns.#GroupByType & {Graph: infra}
metrics: patterns.#GraphMetrics & {Graph: infra}
export: patterns.#ExportGraph & {Graph: infra}

// Sort criticality by dependents (descending)
_critSorted: list.Sort(criticality.ranked, {x: {}, y: {}, less: x.dependents > y.dependents})

// Output
output: {
	// ─────────────────────────────────────────────────────────────
	// Graph Structure
	// ─────────────────────────────────────────────────────────────
	validation: {
		valid:  validate.valid
		issues: validate.issues
	}

	topology: infra.topology
	roots:    infra.roots
	leaves:   infra.leaves

	// ─────────────────────────────────────────────────────────────
	// Impact Analysis: "What breaks if X fails?"
	// ─────────────────────────────────────────────────────────────
	impact: {
		"dns-us": {
			affected: impact_dns_us.affected
			count:    impact_dns_us.affected_count
		}
		"auth": {
			affected: impact_auth.affected
			count:    impact_auth.affected_count
		}
		"db-primary": {
			affected: impact_db.affected
			count:    impact_db.affected_count
		}
		"mq": {
			affected: impact_mq.affected
			count:    impact_mq.affected_count
		}
	}

	// ─────────────────────────────────────────────────────────────
	// Dependency Chains: Path to root
	// ─────────────────────────────────────────────────────────────
	chains: {
		"job-cleanup": {
			path:      chain_job.path
			depth:     chain_job.depth
			ancestors: chain_job.ancestors
		}
		"web-eu": {
			path:      chain_web.path
			depth:     chain_web.depth
			ancestors: chain_web.ancestors
		}
	}

	// ─────────────────────────────────────────────────────────────
	// Immediate vs Transitive
	// ─────────────────────────────────────────────────────────────
	immediate_dependents: {
		"dns-us": immediate_dns.dependents
		"auth":   immediate_auth.dependents
	}

	// ─────────────────────────────────────────────────────────────
	// Criticality: Ranked by impact
	// ─────────────────────────────────────────────────────────────
	criticality_top5: [for i, c in _critSorted if i < 5 {c}]

	// ─────────────────────────────────────────────────────────────
	// Grouping
	// ─────────────────────────────────────────────────────────────
	resources_by_type: by_type.groups

	// ─────────────────────────────────────────────────────────────
	// Summary
	// ─────────────────────────────────────────────────────────────
	summary: {
		total_resources: metrics.total_resources
		max_depth:       metrics.max_depth
		total_edges:     metrics.total_edges
		root_count:      metrics.root_count
		leaf_count:      metrics.leaf_count
	}
}

// ═══════════════════════════════════════════════════════════════════════════
// Visualization data for quicue.ca graph explorer
// Export: cue export ./examples/multi-region/ -e vizData --out json
// ═══════════════════════════════════════════════════════════════════════════

_vizEdges: list.FlattenN([
	for rname, r in _resources if r.depends_on != _|_ {
		[for dep in r.depends_on {{source: dep, target: rname}}]
	},
], 1)

_vizNodes: [
	for r in export.resources {
		id:        r.name
		types:     r["@type"]
		depth:     r.depth
		ancestors: r.ancestors
		dependents: len([
			for other in export.resources
			if list.Contains(other.ancestors, r.name) {1},
		])
	},
]

_vizTopology: {
	for layerName, members in infra.topology {
		(layerName): [for m, _ in members {m}]
	}
}

_vizCriticality: [
	for c in criticality.ranked {
		name:       c.name
		dependents: c.dependents
	},
]

_vizByType: {
	for typeName, members in by_type.groups {
		(typeName): members
	}
}

vizData: {
	nodes:       _vizNodes
	edges:       _vizEdges
	topology:    _vizTopology
	roots:       infra.roots
	leaves:      infra.leaves
	criticality: _vizCriticality
	byType:      _vizByType
	metrics: {
		total:    len(_vizNodes)
		maxDepth: export.summary.max_depth
		edges:    len(_vizEdges)
		roots:    len(infra.roots)
		leaves:   len(infra.leaves)
	}
	validation: {
		valid: infra.valid
		issues: []
	}
}
