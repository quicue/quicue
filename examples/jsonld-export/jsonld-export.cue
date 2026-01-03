// JSON-LD export with @context, @id, @type
// Run: cue export ./examples/jsonld-export/ --out json

package main

import "quicue.ca/vocab@v0"

// Infrastructure resources with JSON-LD annotations
// Validate against vocab.#Resource schema
_resources: [Name=string]: vocab.#Resource & {name: Name}
_resources: {
	"dns-primary": {
		"@id": "https://infra.example.com/resources/dns-primary"
		"@type": ["DNSServer", "LXCContainer", "CriticalInfra"]
		name:         "dns-primary"
		ip:           "10.0.1.10"
		host:         "pve-node-1"
		container_id: 100
		provides: ["dns"]
	}

	"reverse-proxy": {
		"@id": "https://infra.example.com/resources/reverse-proxy"
		"@type": ["ReverseProxy", "LXCContainer"]
		name:         "reverse-proxy"
		ip:           "10.0.1.50"
		host:         "pve-node-1"
		container_id: 105
		depends_on: ["dns-primary"]
		provides: ["proxy", "tls-termination"]
	}

	"git-server": {
		"@id": "https://infra.example.com/resources/git-server"
		"@type": ["SourceControlManagement", "LXCContainer"]
		name:         "git-server"
		ip:           "10.0.1.20"
		host:         "pve-node-2"
		container_id: 200
		depends_on: ["dns-primary", "reverse-proxy"]
		provides: ["git"]
	}

	"pve-node-1": {
		"@id": "https://infra.example.com/resources/pve-node-1"
		"@type": ["VirtualizationPlatform"]
		name:     "pve-node-1"
		ip:       "10.0.0.1"
		ssh_user: "root"
		provides: ["compute", "storage"]
	}
}

// JSON-LD document with embedded context
{
	// Use the quicue.ca context
	"@context": vocab.context."@context"

	// Graph of resources
	"@graph": [
		for _, r in _resources {r},
	]
}
