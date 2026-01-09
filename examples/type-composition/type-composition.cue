// Type composition: @type array grants actions additively
// Run: cue eval ./examples/type-composition/ -e output

package main

import (
	"quicue.ca/vocab@v0"
	"quicue.ca/patterns@v0"
)

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
// UPPERCASE parameters are template params (see vocab/actions.cue)
#ActionFactory: {
	ping: {
		IP: string
		vocab.#Action & {
			name:        "Ping"
			description: "Test connectivity to \(IP)"
			command:     "ping -c 3 \(IP)"
		}
	}
	check_dns: {
		IP: string
		vocab.#Action & {
			name:        "Check DNS"
			description: "Query DNS server at \(IP)"
			command:     "dig @\(IP) SOA"
		}
	}
	proxy_health: {
		IP: string
		vocab.#Action & {
			name:        "Proxy Health"
			description: "Check reverse proxy health"
			command:     "curl -s http://\(IP)/health"
		}
	}
	list_vms: {
		IP:   string
		USER: string
		vocab.#Action & {
			name:        "List VMs"
			description: "List virtual machines"
			command:     "ssh \(USER)@\(IP) 'qm list'"
		}
	}
}

// Resources with semantic types
resources: {
	"pve-node": {
		name:     "pve-node"
		ip:       "10.0.1.1"
		ssh_user: "root"
		"@type": {VirtualizationPlatform: true}
	}

	"technitium": {
		name: "technitium"
		ip:   "10.0.1.10"
		depends_on: {"pve-node": true}
		"@type": {DNSServer: true, CriticalInfra: true}
	}

	"caddy": {
		name: "caddy"
		ip:   "10.0.1.50"
		depends_on: {technitium: true}
		"@type": {ReverseProxy: true}
	}

	"multi-role": {
		name: "multi-role"
		ip:   "10.0.1.99"
		depends_on: {technitium: true}
		"@type": {DNSServer: true, ReverseProxy: true} // Two types = gets actions from both
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
					ping: _F.ping & {IP: res.ip}
				}

				// Type-driven: lookup actions from #TypeActions mapping
				for typeName, _ in res["@type"] if #TypeActions[typeName] != _|_ {
					for actionName in #TypeActions[typeName] if _F[actionName] != _|_ {
						"\(actionName)": _F[actionName] & {
							IP: res.ip
							if actionName == "list_vms" && res.ssh_user != _|_ {
								USER: res.ssh_user
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

// Visualization data for graph explorer
_graphResources: {
	for rname, r in resources {
		(rname): {
			name:    rname
			"@type": r["@type"]
			if r.depends_on != _|_ {
				depends_on: r.depends_on
			}
		}
	}
}
infra: patterns.#InfraGraph & {Input: _graphResources}
_viz: patterns.#VizData & {Graph: infra, Resources: _graphResources}

// Action data per resource (for explorer sidebar)
_actionData: {
	for rname, r in infraGraph {
		(rname): {
			names: [for aname, action in r.actions if action.command != _|_ {aname}]
			commands: {for aname, action in r.actions if action.command != _|_ {(aname): action.command}}
		}
	}
}

// Merge actions into viz nodes
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
}
