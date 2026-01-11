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
	// ===================================================================
	// Layer 0: Regions (roots)
	// ===================================================================
	"region-us": {
		name:   "region-us"
		region: "us-east-1"
		"@type": {Region: true}
	}
	"region-eu": {
		name:   "region-eu"
		region: "eu-west-1"
		"@type": {Region: true}
	}

	// ===================================================================
	// Layer 1: Core infrastructure (per-region)
	// ===================================================================
	"dns-us": {
		name: "dns-us"
		ip:   "10.1.0.10"
		"@type": {DNSServer: true, CriticalInfra: true}
		depends_on: {"region-us": true}
	}
	"dns-eu": {
		name: "dns-eu"
		ip:   "10.2.0.10"
		"@type": {DNSServer: true, CriticalInfra: true}
		depends_on: {"region-eu": true}
	}
	"auth": {
		name: "auth"
		url:  "https://auth.example.com"
		"@type": {AuthServer: true, CriticalInfra: true}
		depends_on: {"region-us": true} // Primary in US, replicated
	}

	// ===================================================================
	// Layer 2: Platform services
	// ===================================================================
	"lb-us": {
		name: "lb-us"
		ip:   "10.1.0.20"
		"@type": {LoadBalancer: true}
		depends_on: {"dns-us": true, auth: true}
	}
	"lb-eu": {
		name: "lb-eu"
		ip:   "10.2.0.20"
		"@type": {LoadBalancer: true}
		depends_on: {"dns-eu": true, auth: true}
	}
	"mq": {
		name: "mq"
		url:  "amqp://mq.example.com"
		"@type": {MessageQueue: true}
		depends_on: {"dns-us": true, auth: true}
	}
	"cache": {
		name: "cache"
		url:  "redis://cache.example.com"
		"@type": {CacheCluster: true}
		depends_on: {"dns-us": true}
	}

	// ===================================================================
	// Layer 3: Data tier
	// ===================================================================
	"db-primary": {
		name: "db-primary"
		url:  "postgresql://db-primary.example.com"
		"@type": {Database: true, CriticalInfra: true}
		depends_on: {"dns-us": true, auth: true}
	}
	"db-replica": {
		name: "db-replica"
		url:  "postgresql://db-replica.eu.example.com"
		"@type": {Database: true}
		depends_on: {"dns-eu": true, "db-primary": true} // Cross-region replication
	}
	"search": {
		name: "search"
		url:  "https://search.example.com"
		"@type": {SearchIndex: true}
		depends_on: {"dns-us": true, mq: true}
	}

	// ===================================================================
	// Layer 4: Application tier
	// Diamond: api depends on cache AND db, both depend on dns
	// ===================================================================
	"api-us": {
		name: "api-us"
		url:  "https://api-us.example.com"
		"@type": {APIServer: true}
		depends_on: {"lb-us": true, "db-primary": true, cache: true, mq: true}
	}
	"api-eu": {
		name: "api-eu"
		url:  "https://api-eu.example.com"
		"@type": {APIServer: true}
		depends_on: {"lb-eu": true, "db-replica": true, cache: true}
	}
	"web-us": {
		name: "web-us"
		url:  "https://www.example.com"
		"@type": {WebFrontend: true}
		depends_on: {"lb-us": true, "api-us": true}
	}
	"web-eu": {
		name: "web-eu"
		url:  "https://eu.example.com"
		"@type": {WebFrontend: true}
		depends_on: {"lb-eu": true, "api-eu": true}
	}

	// ===================================================================
	// Layer 5: Workers and jobs
	// ===================================================================
	"worker-ingest": {
		name: "worker-ingest"
		host: "worker-pool-us"
		"@type": {Worker: true}
		depends_on: {mq: true, "db-primary": true, search: true}
	}
	"worker-notify": {
		name: "worker-notify"
		host: "worker-pool-us"
		"@type": {Worker: true}
		depends_on: {mq: true, "api-us": true}
	}

	// ===================================================================
	// Layer 6: Scheduled jobs (deepest)
	// ===================================================================
	"job-cleanup": {
		name: "job-cleanup"
		host: "cron-server-us"
		"@type": {ScheduledJob: true}
		depends_on: {"worker-ingest": true, "db-primary": true}
	}
	"job-report": {
		name: "job-report"
		host: "cron-server-us"
		"@type": {ScheduledJob: true}
		depends_on: {"worker-notify": true, search: true}
	}

	// ===================================================================
	// Cross-cutting: Observability (depends on many, nothing depends on it)
	// ===================================================================
	"monitoring": {
		name: "monitoring"
		url:  "https://monitoring.example.com"
		"@type": {MonitoringServer: true}
		depends_on: {"dns-us": true, auth: true}
	}
	"logging": {
		name: "logging"
		url:  "https://logs.example.com"
		"@type": {LogAggregator: true}
		depends_on: {"dns-us": true, mq: true}
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
	// -------------------------------------------------------------------
	// Graph Structure
	// -------------------------------------------------------------------
	validation: {
		valid:  validate.valid
		issues: validate.issues
	}

	topology: infra.topology
	roots:    infra.roots
	leaves:   infra.leaves

	// -------------------------------------------------------------------
	// Impact Analysis: "What breaks if X fails?"
	// -------------------------------------------------------------------
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

	// -------------------------------------------------------------------
	// Dependency Chains: Path to root
	// -------------------------------------------------------------------
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

	// -------------------------------------------------------------------
	// Immediate vs Transitive
	// -------------------------------------------------------------------
	immediate_dependents: {
		"dns-us": immediate_dns.dependents
		"auth":   immediate_auth.dependents
	}

	// -------------------------------------------------------------------
	// Criticality: Ranked by impact
	// -------------------------------------------------------------------
	criticality_top5: [for i, c in _critSorted if i < 5 {c}]

	// -------------------------------------------------------------------
	// Grouping
	// -------------------------------------------------------------------
	resources_by_type: by_type.groups

	// -------------------------------------------------------------------
	// Summary
	// -------------------------------------------------------------------
	summary: {
		total_resources: metrics.total_resources
		max_depth:       metrics.max_depth
		total_edges:     metrics.total_edges
		root_count:      metrics.root_count
		leaf_count:      metrics.leaf_count
	}
}

// Visualization data for quicue.ca graph explorer
// Export: cue export ./examples/multi-region/ -e vizData --out json
_viz: patterns.#VizData & {Graph: infra, Resources: _resources}
vizData: _viz.data
