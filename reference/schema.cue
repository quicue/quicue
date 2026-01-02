// Schema - Standardized resource definition for DC administration
//
// Usage:
//   import "quicue.ca/reference"
//
//   resources: [Name=string]: reference.#Resource & { name: Name }

package reference

import "quicue.ca/vocab"

// #Resource - Core resource definition
// Every DC resource conforms to this schema
#Resource: {
	// Identity
	name: string
	"@id"?: string | *"https://infra.example.com/resources/\(name)"

	// Semantic types - determines available actions
	"@type": [...string] & [_, ...]  // At least one type required

	// Network
	ip?: string
	fqdn?: string

	// Hosting relationship
	node?: string          // Hypervisor node name
	vmid?: int            // VM ID (Proxmox VMID)
	lxcid?: int           // Container ID (Proxmox LXCID)
	hosted_on?: string    // Parent resource name

	// Dependencies
	depends_on?: [...string]

	// Access
	ssh_user?: string | *"root"

	// Capabilities this resource provides
	provides?: [...string]

	// Actions - unified from providers
	actions: [string]: vocab.#Action

	// Metadata
	tags?: [...string]
	description?: string
}

// #LXCResource - Resource running as Proxmox LXC container
#LXCResource: #Resource & {
	node:  string
	lxcid: int
	ip:    string
}

// #VMResource - Resource running as Proxmox VM
#VMResource: #Resource & {
	node: string
	vmid: int
	ip:   string
}

// #HypervisorResource - Proxmox node itself
#HypervisorResource: #Resource & {
	ip: string
}

// #Inventory - Collection of resources with validation
#Inventory: {
	resources: [Name=string]: #Resource & {name: Name}

	// Computed: all resource names
	_names: [for n, _ in resources {n}]

	// Validation: depends_on references must exist
	for _, r in resources if r.depends_on != _|_ {
		for dep in r.depends_on {
			_valid: dep
			_valid: or(_names)
		}
	}
}
