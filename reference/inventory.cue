// Inventory - Example DC resources unified with providers
//
// This is a sanitized example demonstrating all quicue patterns.
// Replace with your actual infrastructure details.
//
// Run: cue eval ./reference/inventory.cue -e output --out json

package reference

import (
	"quicue.ca/reference/providers/proxmox"
)

// ============================================================================
// Cluster Configuration - 3-node Proxmox cluster
// ============================================================================

_nodes: {
	alpha: "pve-alpha"
	beta:  "pve-beta"
	gamma: "pve-gamma"
}

// ============================================================================
// Resource Data - Clean definitions without action generation
// ============================================================================

_resources: {
	dns: {
		types: ["DNSServer", "LXCContainer", "CriticalInfra"]
		node:        _nodes.alpha
		lxcid:       100
		ip:          "192.33.33.53"
		ssh_user:    "root"
		provides:    ["dns"]
		description: "Primary DNS server"
	}

	proxy: {
		types: ["ReverseProxy", "LXCContainer", "CriticalInfra"]
		node:        _nodes.alpha
		lxcid:       101
		ip:          "192.33.33.80"
		ssh_user:    "root"
		depends_on:  ["dns"]
		provides:    ["proxy", "tls"]
		description: "Reverse proxy with TLS termination"
	}

	git: {
		types: ["SourceControlManagement", "LXCContainer"]
		node:        _nodes.beta
		lxcid:       200
		ip:          "192.33.33.81"
		ssh_user:    "root"
		depends_on:  ["dns", "proxy"]
		provides:    ["git", "ci-cd"]
		description: "Git server with CI/CD"
	}

	monitoring: {
		types: ["MonitoringServer", "LXCContainer"]
		node:        _nodes.beta
		lxcid:       201
		ip:          "192.33.33.82"
		ssh_user:    "root"
		depends_on:  ["dns", "proxy"]
		provides:    ["prometheus", "grafana"]
		description: "Prometheus + Grafana stack"
	}

	vault: {
		types: ["Vault", "LXCContainer"]
		node:        _nodes.gamma
		lxcid:       300
		ip:          "192.33.33.83"
		ssh_user:    "root"
		depends_on:  ["dns", "proxy"]
		provides:    ["secrets"]
		description: "Secrets management"
	}

	bastion: {
		types: ["Bastion", "LXCContainer"]
		node:        _nodes.gamma
		lxcid:       301
		ip:          "192.33.33.22"
		ssh_user:    "root"
		depends_on:  ["dns"]
		provides:    ["ssh-gateway"]
		description: "SSH bastion host"
	}
}

// ============================================================================
// Output - Resources with computed actions
// ============================================================================

output: {
	for name, r in _resources {
		// Compute actions by unifying providers with resource data
		let lxcActions = proxmox.#LXCActions & {NODE: r.node, LXCID: r.lxcid}
		let netActions = proxmox.#ConnectivityActions & {IP: r.ip, USER: r.ssh_user}

		"\(name)": {
			"@id":        "https://example.com/resources/\(name)"
			"@type":      r.types
			ip:           r.ip
			node:         r.node
			lxcid:        r.lxcid
			if r.provides != _|_ {provides: r.provides}
			if r.depends_on != _|_ {depends_on: r.depends_on}
			if r.description != _|_ {description: r.description}

			actions: {
				for aname, action in lxcActions if action.command != _|_ {
					"\(aname)": action.command
				}
				for aname, action in netActions if action.command != _|_ {
					"\(aname)": action.command
				}
			}
		}
	}
}

// ============================================================================
// Queries - Find resources by type, dependency, etc.
// ============================================================================

// Resources by type
by_type: {
	for typeName in ["DNSServer", "ReverseProxy", "MonitoringServer", "SourceControlManagement", "Vault", "Bastion", "CriticalInfra", "LXCContainer"] {
		"\(typeName)": [
			for name, r in _resources
			for t in r.types
			if t == typeName {name}
		]
	}
}

// Critical infrastructure
critical: by_type.CriticalInfra

// Root resources (no dependencies)
roots: [for name, r in _resources if r.depends_on == _|_ {name}]

// Dependency graph (for ordering)
deps: {
	for name, r in _resources if r.depends_on != _|_ {
		"\(name)": r.depends_on
	}
}
