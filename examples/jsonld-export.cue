// JSON-LD Export Demo
// Shows: Resources as valid JSON-LD with @context, @id, @type
//
// Run: cue export ./examples/jsonld-export.cue --out json
// Validate: Paste output into https://json-ld.org/playground/

package jsonldexport

import "quicue.ca/vocab"

// Infrastructure resources with JSON-LD annotations
_resources: {
	"dns-primary": {
		"@id":   "https://infra.example.com/resources/dns-primary"
		"@type": ["DNSServer", "LXCContainer", "CriticalInfra"]
		name:    "dns-primary"
		ip:      "10.0.1.10"
		node:    "pve-node-1"
		lxcid:   100
		provides: ["dns"]
	}

	"reverse-proxy": {
		"@id":   "https://infra.example.com/resources/reverse-proxy"
		"@type": ["ReverseProxy", "LXCContainer"]
		name:    "reverse-proxy"
		ip:      "10.0.1.50"
		node:    "pve-node-1"
		lxcid:   105
		depends_on: ["dns-primary"]
		provides: ["proxy", "tls-termination"]
	}

	"git-server": {
		"@id":   "https://infra.example.com/resources/git-server"
		"@type": ["SourceControlManagement", "LXCContainer"]
		name:    "git-server"
		ip:      "10.0.1.20"
		node:    "pve-node-2"
		lxcid:   200
		depends_on: ["dns-primary", "reverse-proxy"]
		provides: ["git"]
	}

	"pve-node-1": {
		"@id":   "https://infra.example.com/resources/pve-node-1"
		"@type": ["VirtualizationPlatform"]
		name:    "pve-node-1"
		ip:      "10.0.0.1"
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
