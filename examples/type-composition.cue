// Type Composition Demo
// Shows: @type array grants capabilities additively
//
// Run: cue export ./examples/type-composition.cue -e output --out json

package typecomposition

import "quicue.ca/vocab"

// Action templates with UPPERCASE parameters
#ActionTemplates: {
	ping: {
		IP:          string
		name:        "Ping"
		description: "Test connectivity to \(IP)"
		command:     "ping -c 3 \(IP)"
	}
	check_dns: {
		IP:          string
		name:        "Check DNS"
		description: "Query DNS server at \(IP)"
		command:     "dig @\(IP) SOA"
	}
	proxy_health: {
		IP:          string
		name:        "Proxy Health"
		description: "Check reverse proxy health"
		command:     "curl -s http://\(IP)/health"
	}
	list_vms: {
		IP:          string
		User:        string
		name:        "List VMs"
		description: "List virtual machines"
		command:     "ssh \(User)@\(IP) 'qm list'"
	}
}

// Resources with semantic types
resources: {
	"caddy": {
		name:    "caddy"
		ip:      "10.0.1.50"
		"@type": ["ReverseProxy"] // Gets: proxy_health
	}

	"technitium": {
		name:    "technitium"
		ip:      "10.0.1.10"
		"@type": ["DNSServer", "CriticalInfra"] // Gets: check_dns (CriticalInfra has no actions)
	}

	"pve-node": {
		name:     "pve-node"
		ip:       "10.0.1.1"
		ssh_user: "root"
		"@type":  ["VirtualizationPlatform"] // Gets: list_vms
	}

	"multi-role": {
		name:    "multi-role"
		ip:      "10.0.1.99"
		"@type": ["DNSServer", "ReverseProxy"] // Gets BOTH: check_dns + proxy_health
	}
}

// Generate actions based on @type
_T: #ActionTemplates
_R: vocab.#TypeRegistry

infraGraph: {
	for name, res in resources {
		"\(name)": res & {
			actions: {
				// Universal: ping if IP exists
				if res.ip != _|_ {
					ping: _T.ping & {IP: res.ip}
				}

				// Type-driven: check each @type against registry
				for typeName in res["@type"] {
					// DNSServer → check_dns
					if typeName == "DNSServer" && res.ip != _|_ {
						check_dns: _T.check_dns & {IP: res.ip}
					}

					// ReverseProxy → proxy_health
					if typeName == "ReverseProxy" && res.ip != _|_ {
						proxy_health: _T.proxy_health & {IP: res.ip}
					}

					// VirtualizationPlatform → list_vms
					if typeName == "VirtualizationPlatform" && res.ip != _|_ && res.ssh_user != _|_ {
						list_vms: _T.list_vms & {IP: res.ip, User: res.ssh_user}
					}
				}
			}
		}
	}
}

// Output: resource → action names
output: {
	for name, r in infraGraph {
		"\(name)": {
			types: r["@type"]
			actions: [for aname, _ in r.actions {aname}]
			// Show what each type contributed
			type_contributions: {
				for t in r["@type"] if _R[t] != _|_ {
					"\(t)": _R[t].actions
				}
			}
		}
	}
}
