// JSON-LD export with @context, @id, @type
// Run: cue export ./examples/jsonld-export/ --out json

package main

import (
	"quicue.ca/vocab@v0"
	"quicue.ca/patterns@v0"
)

// Infrastructure resources with JSON-LD annotations
// Validate against vocab.#Resource schema
_resources: [Name=string]: vocab.#Resource & {name: Name}
_resources: {
	"dns-primary": {
		"@id": "https://infra.example.com/resources/dns-primary"
		"@type": {DNSServer: true, LXCContainer: true, CriticalInfra: true}
		name:         "dns-primary"
		ip:           "10.0.1.10"
		host:         "pve-node-1"
		container_id: 100
		provides: {dns: true}
	}

	"reverse-proxy": {
		"@id": "https://infra.example.com/resources/reverse-proxy"
		"@type": {ReverseProxy: true, LXCContainer: true}
		name:         "reverse-proxy"
		ip:           "10.0.1.50"
		host:         "pve-node-1"
		container_id: 105
		depends_on: {"dns-primary": true}
		provides: {proxy: true, "tls-termination": true}
	}

	"git-server": {
		"@id": "https://infra.example.com/resources/git-server"
		"@type": {SourceControlManagement: true, LXCContainer: true}
		name:         "git-server"
		ip:           "10.0.1.20"
		host:         "pve-node-2"
		container_id: 200
		depends_on: {"dns-primary": true, "reverse-proxy": true}
		provides: {git: true}
	}

	"pve-node-1": {
		"@id": "https://infra.example.com/resources/pve-node-1"
		"@type": {VirtualizationPlatform: true}
		name:     "pve-node-1"
		ip:       "10.0.0.1"
		ssh_user: "root"
		provides: {compute: true, storage: true}
	}
}

// JSON-LD document with embedded context
// Converts struct-as-set fields to arrays for valid JSON-LD
jsonld: {
	// Use the quicue.ca context
	"@context": vocab.context."@context"

	// Graph of resources with set fields converted to arrays for valid JSON-LD
	"@graph": [
		for _, r in _resources {{
			"@id":   r."@id"
			"@type": [for t, _ in r."@type" {t}]
			name:    r.name
			if r.ip != _|_ {ip: r.ip}
			if r.host != _|_ {host: r.host}
			if r.container_id != _|_ {container_id: r.container_id}
			if r.ssh_user != _|_ {ssh_user: r.ssh_user}
			if r.depends_on != _|_ {depends_on: [for d, _ in r.depends_on {d}]}
			if r.provides != _|_ {provides: [for p, _ in r.provides {p}]}
		}},
	]
}

// Visualization data for graph explorer (includes @id for JSON-LD demo)
infra: patterns.#InfraGraph & {Input: _resources}
_viz: patterns.#VizData & {Graph: infra, Resources: _resources}
vizData: _viz.data & {
	// Add @id to nodes for this JSON-LD example
	nodes: [
		for n in _viz.data.nodes {
			n & {
				"@id": _resources[n.id]["@id"]
			}
		},
	]
	// Include @context reference
	"@context": "https://quicue.ca/vocab#"
	"@base":    "https://infra.example.com/resources/"
}

// Standard output for quicue eval
// Use the jsonld field which has properly converted arrays for valid JSON-LD
output: jsonld & {
	topology: infra.topology
	roots:    infra.roots
	leaves:   infra.leaves
}
