package vocab

// Action Interfaces - Provider-agnostic contracts
// Define WHAT actions should exist, not HOW they're implemented.
// Providers satisfy these interfaces with concrete commands.
//
// OPEN DEFINITIONS: All interfaces use `...` to allow:
// - Provider-specific parameters (VMID, Node, VMPath, etc.)
// - Additional fields (provider, requires, etc.)
// - Custom actions beyond the interface contract
//
// PARAMETER CONVENTIONS:
// - Use UPPERCASE for template parameters (NODE, VMID, IP, USER)
// - These are filtered out of output when command field exists
// - Parameters are interpolated into command strings
//
// SECURITY WARNING:
// - Command strings use direct interpolation without escaping
// - Do NOT pass untrusted user input as parameters
// - Validate/sanitize at the provider or CLI layer
// - Shell injection is possible if parameters contain: ' " ` $ ; | &

// #Action - Base action structure with optional metadata
// NOTE: No defaults here - specific actions define their own defaults
// to avoid CUE disjunction conflicts during unification
#Action: {
	name:        string
	description: string
	command:     string
	icon:        string
	category:    string

	// Optional metadata for tooling
	timeout_seconds?:     int    // Expected max duration (0 = no timeout)
	requires_confirmation?: bool // Prompt before executing?
	idempotent?:          bool   // Safe to retry?
	destructive?:         bool   // Modifies state permanently?
	requires?: [...string]       // Prerequisites (e.g., ["ssh_access", "guest_agent"])
	...
}

// #VMActions - Standard actions any VM should support
#VMActions: {
	status: #Action & {
		name:     string | *"VM Status"
		icon:     string | *"[status]"
		category: string | *"monitor"
	}
	console: #Action & {
		name:     string | *"Console"
		icon:     string | *"[console]"
		category: string | *"connect"
	}
	config: #Action & {
		name:     string | *"Configuration"
		icon:     string | *"[config]"
		category: string | *"info"
	}
	...
}

// #ContainerActions - Actions for containers (LXC, Docker, etc.)
#ContainerActions: {
	status: #Action & {
		name:     string | *"Container Status"
		icon:     string | *"[status]"
		category: string | *"monitor"
	}
	console: #Action & {
		name:     string | *"Console"
		icon:     string | *"[console]"
		category: string | *"connect"
	}
	logs: #Action & {
		name:     string | *"Logs"
		icon:     string | *"[logs]"
		category: string | *"info"
	}
	...
}

// #ConnectivityActions - Universal network connectivity
#ConnectivityActions: {
	ping: #Action & {
		name:     string | *"Ping"
		icon:     string | *"[ping]"
		category: string | *"connect"
	}
	ssh: #Action & {
		name:     string | *"SSH"
		icon:     string | *"[ssh]"
		category: string | *"connect"
	}
	...
}

// #ServiceActions - Actions for managed services
#ServiceActions: {
	health: #Action & {
		name:     string | *"Health Check"
		icon:     string | *"[health]"
		category: string | *"monitor"
	}
	restart: #Action & {
		name:     string | *"Restart"
		icon:     string | *"[restart]"
		category: string | *"admin"
	}
	logs: #Action & {
		name:     string | *"View Logs"
		icon:     string | *"[logs]"
		category: string | *"info"
	}
	...
}

// #HypervisorActions - Actions for hypervisor nodes
#HypervisorActions: {
	list_vms: #Action & {
		name:     string | *"List VMs"
		icon:     string | *"[vms]"
		category: string | *"info"
	}
	list_containers: #Action & {
		name:     string | *"List Containers"
		icon:     string | *"[containers]"
		category: string | *"info"
	}
	cluster_status: #Action & {
		name:     string | *"Cluster Status"
		icon:     string | *"[cluster]"
		category: string | *"monitor"
	}
	...
}

// #SnapshotActions - Snapshot/backup management
#SnapshotActions: {
	list: #Action & {
		name:     string | *"List Snapshots"
		icon:     string | *"[list]"
		category: string | *"info"
	}
	create: #Action & {
		name:     string | *"Create Snapshot"
		icon:     string | *"[create]"
		category: string | *"admin"
	}
	revert: #Action & {
		name:     string | *"Revert Snapshot"
		icon:     string | *"[revert]"
		category: string | *"admin"
	}
	...
}

// #LifecycleActions - Power state management for VMs/containers
// Canonical action names - providers may alias (e.g., power_on -> start)
#LifecycleActions: {
	start: #Action & {
		name:     string | *"Start"
		icon:     string | *"[start]"
		category: string | *"admin"
	}
	stop: #Action & {
		name:     string | *"Stop"
		icon:     string | *"[stop]"
		category: string | *"admin"
	}
	restart: #Action & {
		name:     string | *"Restart"
		icon:     string | *"[restart]"
		category: string | *"admin"
	}
	...
}

// #GuestActions - Guest OS operations (requires guest agent/tools)
#GuestActions: {
	exec: #Action & {
		name:     string | *"Execute Command"
		icon:     string | *"[exec]"
		category: string | *"admin"
	}
	upload: #Action & {
		name:     string | *"Upload File"
		icon:     string | *"[upload]"
		category: string | *"admin"
	}
	download: #Action & {
		name:     string | *"Download File"
		icon:     string | *"[download]"
		category: string | *"admin"
	}
	...
}
