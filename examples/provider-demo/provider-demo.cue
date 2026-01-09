// Provider demo: type-driven action generation
//
// Shows how CUE unification generates commands from:
//   resource fields + provider templates → concrete actions
//
// This example uses ABSTRACT provider templates to demonstrate the pattern.
// Real provider implementations live in separate repos (quicue-proxmox, quicue-docker, etc.)
//
// Run:
//   cue eval ./examples/provider-demo/ -e output
//   cue export ./examples/provider-demo/ -e vizData --out json

package main

import (
	"list"
	"quicue.ca/patterns@v0"
	"quicue.ca/vocab@v0"
)

// ═══════════════════════════════════════════════════════════════════════════
// ABSTRACT PROVIDER TEMPLATES
// These demonstrate the provider pattern. Real implementations are in provider repos.
// ═══════════════════════════════════════════════════════════════════════════

// Container provider template (abstract - could be Docker, LXC, Podman, etc.)
#ContainerProvider: {
	CONTAINER_ID: string
	HOST:         string
	...

	status: vocab.#Action & {
		name:        "Container Status"
		description: "Check container status"
		command:     "<provider> status \(CONTAINER_ID) on \(HOST)"
		category:    "monitor"
	}
	console: vocab.#Action & {
		name:        "Console"
		description: "Attach to container console"
		command:     "<provider> console \(CONTAINER_ID)"
		category:    "connect"
	}
	logs: vocab.#Action & {
		name:        "Logs"
		description: "View container logs"
		command:     "<provider> logs \(CONTAINER_ID)"
		category:    "info"
	}
}

// SSH connectivity (generic)
#SSHProvider: {
	IP:   string
	USER: string
	...

	ping: vocab.#Action & {
		name:        "Ping"
		description: "Test network connectivity"
		command:     "ping -c 3 \(IP)"
		category:    "connect"
	}
	ssh: vocab.#Action & {
		name:        "SSH"
		description: "SSH to host"
		command:     "ssh \(USER)@\(IP)"
		category:    "connect"
	}
}

// Service health check (generic)
#ServiceProvider: {
	IP:      string
	SERVICE: string
	...

	health: vocab.#Action & {
		name:        "Health Check"
		description: "Check service health"
		command:     "curl -s http://\(IP)/health"
		category:    "monitor"
	}
}

// ═══════════════════════════════════════════════════════════════════════════
// RESOURCES
// Define your infrastructure - types and fields, no commands
// ═══════════════════════════════════════════════════════════════════════════

_resources: {
	"hypervisor": {
		name: "hypervisor"
		ip:   "10.0.0.1"
		"@type": {VirtualizationPlatform: true, Hypervisor: true}
		ssh_user:    "admin"
		description: "Hypervisor node"
	}

	"dns": {
		name:         "dns"
		ip:           "10.0.1.10"
		container_id: "dns-001"
		host:         "hypervisor"
		"@type": {DNSServer: true, Container: true, CriticalInfra: true}
		depends_on: {"hypervisor": true}
		ssh_user:    "root"
		description: "Primary DNS server"
	}

	"database": {
		name:         "database"
		ip:           "10.0.1.20"
		container_id: "db-001"
		host:         "hypervisor"
		"@type": {Database: true, Container: true, CriticalInfra: true}
		depends_on: {dns: true}
		ssh_user:    "dbadmin"
		description: "Primary database"
	}

	"api": {
		name:         "api"
		ip:           "10.0.1.30"
		container_id: "api-001"
		host:         "hypervisor"
		"@type": {APIServer: true, Container: true}
		depends_on: {database: true}
		ssh_user:    "app"
		description: "REST API server"
	}
}

// ═══════════════════════════════════════════════════════════════════════════
// BUILD GRAPH
// ═══════════════════════════════════════════════════════════════════════════

infra: patterns.#InfraGraph & {Input: _resources}

// ═══════════════════════════════════════════════════════════════════════════
// GENERATE ACTIONS
// Unification: resource fields + provider template → concrete commands
// ═══════════════════════════════════════════════════════════════════════════

infraGraph: {
	for rname, r in infra.resources {
		// Struct-as-set for O(1) type lookup
		let _types = {for t, _ in r["@type"] {(t): true}}

		(rname): r & {
			actions: {
				// SSH connectivity (if ip and ssh_user present)
				if r.ip != _|_ && r.ssh_user != _|_ {
					#SSHProvider & {IP: r.ip, USER: r.ssh_user}
				}

				// Container actions (if container_id and host present)
				if r.container_id != _|_ && r.host != _|_ {
					#ContainerProvider & {
						CONTAINER_ID: r.container_id
						HOST:         r.host
					}
				}

				// Type-driven: DNSServer gets dns_check
				if _types.DNSServer != _|_ && r.ip != _|_ {
					dns_check: vocab.#Action & {
						name:        "DNS Query"
						description: "Test DNS resolution"
						command:     "dig @\(r.ip) example.com"
						category:    "monitor"
					}
				}

				// Type-driven: Database gets db_check
				if _types.Database != _|_ && r.ip != _|_ {
					db_check: vocab.#Action & {
						name:        "DB Ready Check"
						description: "Check database accepting connections"
						command:     "nc -zv \(r.ip) 5432"
						category:    "monitor"
					}
				}

				// Type-driven: APIServer gets api_health
				if _types.APIServer != _|_ && r.ip != _|_ {
					#ServiceProvider & {IP: r.ip, SERVICE: "api"}
				}
			}
		}
	}
}

// ═══════════════════════════════════════════════════════════════════════════
// QUERIES
// ═══════════════════════════════════════════════════════════════════════════

impact_dns: patterns.#ImpactQuery & {Graph: infra, Target: "dns"}
criticality: patterns.#CriticalityRank & {Graph: infra}
metrics: patterns.#GraphMetrics & {Graph: infra}
deployment: patterns.#DeploymentPlan & {Graph: infra}

_critSorted: list.Sort(criticality.ranked, {x: {}, y: {}, less: x.dependents > y.dependents})

// ═══════════════════════════════════════════════════════════════════════════
// OUTPUT
// ═══════════════════════════════════════════════════════════════════════════

output: {
	summary: {
		resources: metrics.total_resources
		edges:     metrics.total_edges
		max_depth: metrics.max_depth
		roots:     infra.roots
		leaves:    infra.leaves
		actions_generated: len([
			for _, r in infraGraph
			for _, a in r.actions if a.command != _|_ {1},
		])
	}

	topology: infra.topology
	startup_order:  deployment.startup_sequence
	shutdown_order: deployment.shutdown_sequence

	if_dns_fails: {
		affected:       impact_dns.affected
		affected_count: impact_dns.affected_count
	}

	most_critical: [for i, c in _critSorted if i < 3 {c}]

	// All generated actions
	actions: {
		for rname, r in infraGraph {
			(rname): {
				for aname, a in r.actions if a.command != _|_ {
					(aname): a.command
				}
			}
		}
	}

	// Note about providers
	provider_note: "Commands use abstract <provider> placeholders. Import a real provider (quicue-proxmox, quicue-docker) for platform-specific commands."
}

// Visualization data for quicue.ca graph explorer
_viz: patterns.#VizData & {Graph: infra, Resources: _resources}

// Action data per resource (for explorer sidebar)
_actionData: {
	for rname, r in infraGraph {
		(rname): {
			names: [for aname, action in r.actions if action.command != _|_ {aname}]
			commands: {for aname, action in r.actions if action.command != _|_ {(aname): action.command}}
		}
	}
}

vizData: _viz.data & {
	nodes: [
		for n in _viz.data.nodes {
			n & {
				if _actionData[n.id] != _|_ {
					actions:  _actionData[n.id].names
					commands: _actionData[n.id].commands
				}
			}
		},
	]
	provider_info: {
		note: "Abstract provider templates. Import quicue-proxmox or quicue-docker for real commands."
	}
}
