// Action Schema
//
// Usage:
//   import "quicue.ca/vocab@v0"
//
//   myAction: vocab.#Action & {
//       name: "Ping"
//       description: "Test connectivity"
//       command: "ping -c3 \(IP)"
//   }
//
// PARAMETER CONVENTIONS:
// - Use UPPERCASE for template parameters (NODE, VMID, IP, USER)
// - Parameters are interpolated into command strings
//
// SECURITY WARNING:
// - Command strings use direct interpolation without escaping
// - Do NOT pass untrusted user input as parameters
// - Validate/sanitize at the provider or CLI layer

package vocab

// #Action - Base schema for all actions
#Action: {
	name:         string
	description?: string
	command?:     string
	icon?:        string
	category?:    string // connect|info|monitor|admin (for UI grouping)

	// Operational metadata
	timeout_seconds?:       int  // Expected max duration (0 = no timeout)
	requires_confirmation?: bool // Prompt before executing?
	idempotent?:            bool // Safe to retry?
	destructive?:           bool // Modifies state permanently?
	requires?: {[string]: true} // Prerequisites (e.g., {ssh_access: true, guest_agent: true})
	...
}

// =============================================================================
// Action Interfaces - Providers implement these with concrete commands
// =============================================================================

// #VMActions - Virtual machine status and inspection
#VMActions: {
	status:   #Action
	console?: #Action
	config?:  #Action
	...
}

// #LifecycleActions - Power state management
#LifecycleActions: {
	start:    #Action
	stop:     #Action
	restart?: #Action
	...
}

// #SnapshotActions - Point-in-time capture/restore
#SnapshotActions: {
	list:    #Action
	create:  #Action
	revert?: #Action
	...
}

// #ContainerActions - Container status and access
#ContainerActions: {
	status:  #Action
	console: #Action
	logs?:   #Action
	...
}

// #HypervisorActions - Host/node level operations
#HypervisorActions: {
	list_vms:        #Action
	list_containers: #Action
	cluster_status?: #Action
	...
}

// #ConnectivityActions - Network connectivity
#ConnectivityActions: {
	ping: #Action
	ssh:  #Action
	...
}

// #GuestActions - Guest agent operations
#GuestActions: {
	exec:      #Action
	upload?:   #Action
	download?: #Action
	...
}
