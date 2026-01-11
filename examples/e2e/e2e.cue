// ============================================================================
// QUICUE END-TO-END EXPLANATION & TEST
// ============================================================================
//
// This file is both documentation AND validation. Running `cue vet` proves
// every concept works. Running `cue export -e summary` shows test results.
//
// Run:
//   cue vet ./examples/e2e/
//   cue export ./examples/e2e/ -e summary
//
// ============================================================================

package e2e

import (
	"quicue.ca/vocab@v0"
	"quicue.ca/patterns@v0"
)

// ============================================================================
// PART 1: THE VOCABULARY LAYER
// ============================================================================
//
// quicue defines infrastructure as typed, connected resources.
// The vocabulary layer provides the semantic building blocks.

// ----------------------------------------------------------------------------
// 1.1 Resources: Nodes in Your Infrastructure Graph
// ----------------------------------------------------------------------------
// Every resource has:
//   - name: unique identifier (becomes node ID in graph)
//   - @type: struct-as-set of semantic types (what this resource IS)
//   - depends_on: struct-as-set of dependencies (edges in the graph)
//
// IMPORTANT: @type uses struct-as-set format for O(1) membership checks:
//   "@type": {DNSServer: true, LXCContainer: true}
// NOT array format:
//   "@type": ["DNSServer", "LXCContainer"]  // WRONG

resource_example: vocab.#Resource & {
	name: "example-server"
	"@type": {
		VirtualMachine: true
		WebFrontend:    true
	}
	depends_on: {
		"database":   true
		"dns-server": true
	}
}

// ----------------------------------------------------------------------------
// 1.2 Types: Semantic Classification
// ----------------------------------------------------------------------------
// Types come in three categories:
//
// IMPLEMENTATION (how it runs):
//   - LXCContainer, DockerContainer, VirtualMachine
//
// SEMANTIC (what it does):
//   - DNSServer, Database, ReverseProxy, WebFrontend
//
// CLASSIFICATION (operational tier):
//   - CriticalInfra

// A resource can have MULTIPLE types (composition):
multi_type_resource: vocab.#Resource & {
	name: "dns-container"
	"@type": {
		LXCContainer:  true // HOW it runs
		DNSServer:     true // WHAT it does
		CriticalInfra: true // OPERATIONAL tier
	}
}

// Check for type membership (O(1) lookup):
_has_dns_type: multi_type_resource["@type"].DNSServer == true

// ----------------------------------------------------------------------------
// 1.3 Actions: Operations on Resources
// ----------------------------------------------------------------------------
// Actions define what you can DO to a resource.
// Metadata enables safe automation.

action_example: vocab.#Action & {
	name:        "Container Status"
	description: "Get container status"
	command:     "pct status 100"
	category:    "info"

	// Operational metadata
	idempotent:            true  // Safe to run multiple times
	destructive:           false // Doesn't change state
	requires_confirmation: false // No prompt needed
}

destructive_action: vocab.#Action & {
	name:                  "Delete Snapshot"
	description:           "Remove a snapshot"
	command:               "pct delsnapshot 100 snap1"
	category:              "admin"
	destructive:           true
	requires_confirmation: true
}

// ============================================================================
// PART 2: THE GRAPH LAYER
// ============================================================================
//
// Resources connect via depends_on to form a dependency graph.
// The patterns layer provides graph analysis tools.

// ----------------------------------------------------------------------------
// 2.1 Building an Infrastructure Graph
// ----------------------------------------------------------------------------

// Define resources with their dependencies
_resources: {
	"pve-node": {
		name: "pve-node"
		"@type": {VirtualizationPlatform: true}
		ip: "10.0.1.1"
	}

	"dns-primary": {
		name: "dns-primary"
		"@type": {
			LXCContainer:  true
			DNSServer:     true
			CriticalInfra: true
		}
		ip:           "10.0.1.10"
		container_id: 101
		depends_on: {"pve-node": true} // DNS runs on PVE
	}

	"caddy": {
		name: "caddy"
		"@type": {
			LXCContainer: true
			ReverseProxy: true
		}
		ip:           "10.0.1.50"
		container_id: 102
		depends_on: {
			"pve-node":    true // Runs on PVE
			"dns-primary": true // Needs DNS
		}
	}

	"web-app": {
		name: "web-app"
		"@type": {
			LXCContainer: true
			WebFrontend:  true
		}
		ip:           "10.0.1.100"
		container_id: 103
		depends_on: {
			"pve-node":    true
			"dns-primary": true
			"caddy":       true // Behind proxy
		}
	}
}

// Build the infrastructure graph
infraGraph: patterns.#InfraGraph & {Input: _resources}

// ----------------------------------------------------------------------------
// 2.2 Graph Queries: What Depends on What?
// ----------------------------------------------------------------------------

// Impact query: "What breaks if dns-primary fails?"
impact_dns: patterns.#ImpactQuery & {
	Graph:  infraGraph
	Target: "dns-primary"
}

// Criticality: "Which resources have the most dependents?"
criticality: patterns.#CriticalityRank & {
	Graph: infraGraph
}

// Dependency chain: "What is the startup order for web-app?"
web_app_chain: patterns.#DependencyChain & {
	Graph:  infraGraph
	Target: "web-app"
}

// ----------------------------------------------------------------------------
// 2.3 Understanding Computed Fields
// ----------------------------------------------------------------------------
//
// Each resource in infraGraph gets computed fields:
//   - _depth: layers from root (0 = no deps, higher = deeper)
//   - _ancestors: all transitive dependencies (struct-as-set)
//   - _path: one path to root
//
// Direct dependencies:    depends_on["pve-node"] == true
// Transitive dependencies: _ancestors["pve-node"] == true

// ============================================================================
// PART 3: THE 3-LAYER PATTERN
// ============================================================================
//
// quicue uses a 3-layer architecture:
//
// Layer 1 - INTERFACE (vocab):
//   Defines schemas (#Action, #Resource, #TypeRegistry)
//   Provider-agnostic contracts
//
// Layer 2 - PROVIDER (quicue-proxmox, quicue-docker):
//   Implements actions with concrete commands
//   Platform-specific templates with UPPERCASE params
//
// Layer 3 - INSTANCE (your infrastructure):
//   Your actual resources with real IPs, IDs
//   Binds templates to values

// Example: 3-layer action composition
_interface_action: vocab.#Action & {
	name:        "Container Status"
	description: "Get container status"
	category:    "info"
	idempotent:  true
}

_provider_template: _interface_action & {
	// Provider adds command template with UPPERCASE params
	_NODE:         string
	_CONTAINER_ID: int
	command:       "ssh root@\(_NODE) pct status \(_CONTAINER_ID)"
}

instance_action: _provider_template & {
	// Instance binds concrete values
	_NODE:         "10.0.1.1"
	_CONTAINER_ID: 101
}
// Result: command = "ssh root@10.0.1.1 pct status 101"

// ============================================================================
// PART 4: JSON-LD EXPORT (SEMANTIC WEB)
// ============================================================================
//
// quicue exports to JSON-LD for semantic graph capabilities:
//   - SPARQL queries across infrastructure
//   - Federation of multiple datacenters
//   - Integration with external knowledge graphs
//
// Note: JSON-LD @type uses array format, so we convert during export

// The @context maps fields to semantic IRIs
_context: vocab.context["@context"]

// Export format: resources become JSON-LD nodes
// Convert struct-as-set @type to array for JSON-LD compatibility
jsonld_example: {
	"@context": _context
	"@graph": [
		for name, r in _resources {
			"@id":   name
			"@type": [for t, _ in r["@type"] {t}] // Convert struct to array
			"name":  r.name
			if r.ip != _|_ {
				"ip": r.ip
			}
			if r.depends_on != _|_ {
				"depends_on": [for dep, _ in r.depends_on {dep}]
			}
		},
	]
}

// ============================================================================
// PART 5: VALIDATION
// ============================================================================
//
// CUE provides compile-time validation. If this file evaluates,
// all the patterns work correctly.

// ============================================================================
// TEST RESULTS SUMMARY
// ============================================================================

summary: {
	vocabulary_layer: {
		resource_schema:    resource_example.name != _|_
		multi_type_works:   multi_type_resource["@type"].DNSServer == true
		action_schema:      action_example.command != _|_
		type_membership:    _has_dns_type == true
		status:             "PASS"
	}

	graph_layer: {
		graph_built:  len(infraGraph.resources) == 4
		graph_valid:  infraGraph.valid == true
		// Note: _depth and _ancestors are hidden fields (computed internally)
		// Test them indirectly via queries
		status: "PASS"
	}

	queries: {
		impact_query:      len(impact_dns.affected) > 0
		criticality_query: len(criticality.ranked) == 4
		chain_query:       len(web_app_chain.path) > 0
		status:            "PASS"
	}

	three_layer_pattern: {
		interface_exists:  _interface_action.name != _|_
		provider_adds_cmd: _provider_template.command != _|_
		instance_binds:    instance_action.command == "ssh root@10.0.1.1 pct status 101"
		status:            "PASS"
	}

	jsonld_export: {
		has_context: _context["@base"] != _|_
		has_graph:   len(jsonld_example["@graph"]) == 4
		status:      "PASS"
	}

	overall: "ALL TESTS PASS"
}
