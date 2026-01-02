// 3-Layer System Demo
// Shows: interface (quicue.ca) → provider (jacue-proxmox) → instance (your infra)
//
// Run: cue eval ./examples/3-layer.cue

package threelayer

import "quicue.ca/vocab"

// ============================================================================
// LAYER 1: Interface (quicue.ca/vocab)
// Defines WHAT actions should exist, not HOW
// ============================================================================

// vocab.#ContainerActions defines: status, console, logs
// vocab.#ConnectivityActions defines: ping, ssh

// ============================================================================
// LAYER 2: Provider (e.g., jacue-proxmox)
// Implements interfaces with platform-specific commands
// ============================================================================

// Proxmox LXC provider - satisfies #ContainerActions
#ProxmoxLXC: vocab.#ContainerActions & {
	LXCID: int
	Node:  string

	status: {
		description: "Get LXC container status"
		command:     "ssh \(Node) 'pct status \(LXCID)'"
	}
	console: {
		description: "Enter LXC container console"
		command:     "ssh -t \(Node) 'pct enter \(LXCID)'"
	}
	logs: {
		description: "View container logs"
		command:     "ssh \(Node) 'pct exec \(LXCID) -- journalctl -n 50'"
	}
}

// Connectivity provider
#Connectivity: vocab.#ConnectivityActions & {
	IP:   string
	User: string

	ping: {
		description: "Test network connectivity"
		command:     "ping -c 3 \(IP)"
	}
	ssh: {
		description: "SSH to resource"
		command:     "ssh \(User)@\(IP)"
	}
}

// ============================================================================
// LAYER 3: Instance (your infrastructure)
// Concrete resources using providers
// ============================================================================

resources: {
	"dns-server": {
		name:   "dns-server"
		ip:     "10.0.1.10"
		node:   "pve-node-1"
		lxcid:  100
		"@type": ["DNSServer", "LXCContainer"]

		// Compose actions from providers
		actions: {
			#ProxmoxLXC & {LXCID: 100, Node: "pve-node-1"}
			#Connectivity & {IP: "10.0.1.10", User: "root"}
		}
	}

	"git-server": {
		name:   "git-server"
		ip:     "10.0.1.20"
		node:   "pve-node-2"
		lxcid:  200
		"@type": ["SourceControlManagement", "LXCContainer"]

		actions: {
			#ProxmoxLXC & {LXCID: 200, Node: "pve-node-2"}
			#Connectivity & {IP: "10.0.1.20", User: "git"}
		}
	}
}

// ============================================================================
// Output: Show generated actions
// ============================================================================

output: {
	for name, r in resources {
		"\(name)": {
			resource: name
			"@type":  r["@type"]
			actions: {
				// Only include fields that have a command (filter out UPPERCASE params)
				for aname, action in r.actions if action.command != _|_ {
					"\(aname)": action.command
				}
			}
		}
	}
}
