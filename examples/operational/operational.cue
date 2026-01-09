// Operational patterns: deployment, blast radius, health, rollback
//
// Demonstrates patterns for operational workflows beyond queries:
// - Deployment planning with layer gates
// - Change impact analysis (blast radius)
// - Health status propagation
// - Rollback sequencing
// - Single points of failure detection
//
// Run: cue eval ./examples/operational/ -e output

package main

import (
	"quicue.ca/patterns@v0"
)

// Sample infrastructure with dependencies
_resources: {
	"pve-node": {
		name: "pve-node"
		"@type": {VirtualizationPlatform: true}
	}
	"dns": {
		name: "dns"
		"@type": {DNSServer: true, CriticalInfra: true}
		depends_on: {"pve-node": true}
	}
	"auth": {
		name: "auth"
		"@type": {AuthServer: true}
		depends_on: {"pve-node": true}
	}
	"db": {
		name: "db"
		"@type": {Database: true}
		depends_on: {dns: true}
	}
	"cache": {
		name: "cache"
		"@type": {CacheCluster: true}
		depends_on: {dns: true}
	}
	"api": {
		name: "api"
		"@type": {APIServer: true}
		depends_on: {db: true, cache: true, auth: true}
	}
	"web": {
		name: "web"
		"@type": {WebServer: true}
		depends_on: {api: true}
	}
	"worker": {
		name: "worker"
		"@type": {Worker: true}
		depends_on: {db: true, cache: true}
	}
}

// Build the graph
infra: patterns.#InfraGraph & {Input: _resources}

// ═══════════════════════════════════════════════════════════════════════════
// OPERATIONAL PATTERNS
// ═══════════════════════════════════════════════════════════════════════════

// 1. Deployment Plan - layer-by-layer with gates
deployment: patterns.#DeploymentPlan & {Graph: infra}

// 2. Blast Radius - what happens if dns goes down?
blast_dns: patterns.#BlastRadius & {Graph: infra, Target: "dns"}

// 3. Health Status - simulate dns being down
health: patterns.#HealthStatus & {
	Graph: infra
	Status: {
		"dns": "down"
	}
}

// 4. Rollback Plan - if layer 2 fails, what do we rollback?
rollback: patterns.#RollbackPlan & {Graph: infra, FailedAt: 2}

// 5. Single Points of Failure - what has no redundancy?
spof: patterns.#SinglePointsOfFailure & {Graph: infra}

// ═══════════════════════════════════════════════════════════════════════════
// OUTPUT
// ═══════════════════════════════════════════════════════════════════════════

output: {
	// Deployment: layer-by-layer startup with explicit gates
	deployment_plan: {
		layers: [
			for l in deployment.layers {
				layer:     l.layer
				resources: l.resources
				gate:      l.gate
			},
		]
		summary: deployment.summary
	}

	// Blast radius: what breaks if dns fails?
	blast_radius_dns: {
		target:         "dns"
		affected:       blast_dns.affected
		rollback_order: blast_dns.rollback_order
		startup_order:  blast_dns.startup_order
		safe_peers:     blast_dns.safe_peers
		summary:        blast_dns.summary
	}

	// Health propagation: dns down → dependents degraded
	health_status: {
		scenario:   "dns is down"
		propagated: health.propagated
		summary:    health.summary
	}

	// Rollback: if layer 2 fails, rollback in reverse order
	rollback_plan: {
		scenario:       "deployment failed at layer 2"
		failed_at:      rollback.FailedAt
		rollback_order: rollback.sequence
		safe:           rollback.safe
		summary:        rollback.summary
	}

	// SPOF: resources with dependents but no redundancy
	single_points_of_failure: {
		risks:   spof.risks
		summary: spof.summary
	}
}

// Visualization data
_viz: patterns.#VizData & {Graph: infra, Resources: _resources}
vizData: _viz.data
