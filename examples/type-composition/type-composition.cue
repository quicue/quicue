// Type composition: @type array grants actions additively
// Run: cue eval ./examples/type-composition/ -e output

package main

import "quicue.ca/vocab@v0"

// Type-to-action mapping (declarative, not imperative)
// Each type declares which actions it grants
#TypeActions: {
	DNSServer: ["check_dns"]
	ReverseProxy: ["proxy_health"]
	VirtualizationPlatform: ["list_vms"]
	// Types without specific actions (capabilities inherited structurally)
	CriticalInfra: []
}

// Action factories - create action from resource fields
// Hidden fields (_ip, _user) hold template parameters, excluded from output
#ActionFactory: {
	ping: {
		_ip: string
		vocab.#Action & {
			name:        "Ping"
			description: "Test connectivity to \(_ip)"
			command:     "ping -c 3 \(_ip)"
		}
	}
	check_dns: {
		_ip: string
		vocab.#Action & {
			name:        "Check DNS"
			description: "Query DNS server at \(_ip)"
			command:     "dig @\(_ip) SOA"
		}
	}
	proxy_health: {
		_ip: string
		vocab.#Action & {
			name:        "Proxy Health"
			description: "Check reverse proxy health"
			command:     "curl -s http://\(_ip)/health"
		}
	}
	list_vms: {
		_ip:   string
		_user: string
		vocab.#Action & {
			name:        "List VMs"
			description: "List virtual machines"
			command:     "ssh \(_user)@\(_ip) 'qm list'"
		}
	}
}

// Resources with semantic types
resources: {
	"caddy": {
		name: "caddy"
		ip:   "10.0.1.50"
		"@type": ["ReverseProxy"]
	}

	"technitium": {
		name: "technitium"
		ip:   "10.0.1.10"
		"@type": ["DNSServer", "CriticalInfra"]
	}

	"pve-node": {
		name:     "pve-node"
		ip:       "10.0.1.1"
		ssh_user: "root"
		"@type": ["VirtualizationPlatform"]
	}

	"multi-role": {
		name: "multi-role"
		ip:   "10.0.1.99"
		"@type": ["DNSServer", "ReverseProxy"]
	}
}

// Generate actions declaratively via type mapping
_F: #ActionFactory

infraGraph: {
	for rname, res in resources {
		"\(rname)": res & {
			actions: {
				// Universal: ping if IP exists
				if res.ip != _|_ {
					ping: _F.ping & {_ip: res.ip}
				}

				// Type-driven: lookup actions from #TypeActions mapping
				for typeName in res["@type"] if #TypeActions[typeName] != _|_ {
					for actionName in #TypeActions[typeName] if _F[actionName] != _|_ {
						"\(actionName)": _F[actionName] & {
							_ip: res.ip
							if actionName == "list_vms" && res.ssh_user != _|_ {
								_user: res.ssh_user
							}
						}
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
			// List only action names (filter out template params)
			actions: [for aname, action in r.actions if action.command != _|_ {aname}]
		}
	}
}
