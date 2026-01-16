// Proxmox Provider - Action implementations for Proxmox VE
//
// Usage:
//   actions: proxmox.#LXCActions & {NODE: "pve-node-1", LXCID: 100}

package proxmox

import "quicue.ca/vocab"

// #LXCActions - Actions for Proxmox LXC containers
#LXCActions: vocab.#ContainerActions & {
	NODE:  string
	LXCID: int

	status: {
		name:        "Container Status"
		description: "Get LXC container status via pct"
		command:     "ssh \(NODE) 'pct status \(LXCID)'"
	}
	console: {
		name:        "Container Console"
		description: "Enter LXC container console"
		command:     "ssh -t \(NODE) 'pct enter \(LXCID)'"
	}
	logs: {
		name:        "Container Logs"
		description: "View container journal logs"
		command:     "ssh \(NODE) 'pct exec \(LXCID) -- journalctl -n 100'"
	}
	exec: {
		name:        "Execute Command"
		description: "Run command inside container"
		command:     "ssh \(NODE) 'pct exec \(LXCID) -- '"
	}
	start: {
		name:        "Start Container"
		description: "Start the LXC container"
		command:     "ssh \(NODE) 'pct start \(LXCID)'"
	}
	stop: {
		name:        "Stop Container"
		description: "Stop the LXC container"
		command:     "ssh \(NODE) 'pct stop \(LXCID)'"
	}
	restart: {
		name:        "Restart Container"
		description: "Restart the LXC container"
		command:     "ssh \(NODE) 'pct restart \(LXCID)'"
	}
	config: {
		name:        "Container Config"
		description: "Show container configuration"
		command:     "ssh \(NODE) 'pct config \(LXCID)'"
	}
}

// #VMActions - Actions for Proxmox QEMU VMs
#VMActions: vocab.#VMActions & {
	NODE: string
	VMID: int

	status: {
		name:        "VM Status"
		description: "Get VM status via qm"
		command:     "ssh \(NODE) 'qm status \(VMID)'"
	}
	console: {
		name:        "VM Console"
		description: "Open VM terminal (requires virt-viewer)"
		command:     "ssh -t \(NODE) 'qm terminal \(VMID)'"
	}
	config: {
		name:        "VM Config"
		description: "Show VM configuration"
		command:     "ssh \(NODE) 'qm config \(VMID)'"
	}
	start: {
		name:        "Start VM"
		description: "Start the virtual machine"
		command:     "ssh \(NODE) 'qm start \(VMID)'"
	}
	stop: {
		name:        "Stop VM"
		description: "Stop the virtual machine"
		command:     "ssh \(NODE) 'qm stop \(VMID)'"
	}
	shutdown: {
		name:        "Shutdown VM"
		description: "Gracefully shutdown the VM"
		command:     "ssh \(NODE) 'qm shutdown \(VMID)'"
	}
	reset: {
		name:        "Reset VM"
		description: "Hard reset the VM"
		command:     "ssh \(NODE) 'qm reset \(VMID)'"
	}
}

// #HypervisorActions - Actions for Proxmox nodes
#HypervisorActions: vocab.#HypervisorActions & {
	NODE: string

	list_vms: {
		name:        "List VMs"
		description: "List all VMs on this node"
		command:     "ssh \(NODE) 'qm list'"
	}
	list_containers: {
		name:        "List Containers"
		description: "List all LXC containers on this node"
		command:     "ssh \(NODE) 'pct list'"
	}
	cluster_status: {
		name:        "Cluster Status"
		description: "Show Proxmox cluster status"
		command:     "ssh \(NODE) 'pvecm status'"
	}
	storage: {
		name:        "Storage Status"
		description: "Show storage status"
		command:     "ssh \(NODE) 'pvesm status'"
	}
	tasks: {
		name:        "Recent Tasks"
		description: "Show recent cluster tasks"
		command:     "ssh \(NODE) 'pvesh get /cluster/tasks --limit 10'"
	}
}

// #ConnectivityActions - Network connectivity actions
#ConnectivityActions: vocab.#ConnectivityActions & {
	IP:   string
	USER: string | *"root"

	ping: {
		name:        "Ping"
		description: "Test network connectivity"
		command:     "ping -c 3 \(IP)"
	}
	ssh: {
		name:        "SSH"
		description: "SSH to resource"
		command:     "ssh \(USER)@\(IP)"
	}
	mtr: {
		name:        "MTR"
		description: "Network path analysis"
		command:     "mtr -r -c 5 \(IP)"
	}
}

// #SnapshotActions - Snapshot management for LXC
#LXCSnapshotActions: vocab.#SnapshotActions & {
	NODE:  string
	LXCID: int

	list: {
		name:        "List Snapshots"
		description: "List container snapshots"
		command:     "ssh \(NODE) 'pct listsnapshot \(LXCID)'"
	}
	create: {
		name:        "Create Snapshot"
		description: "Create container snapshot"
		command:     "ssh \(NODE) 'pct snapshot \(LXCID) snap-$(date +%Y%m%d-%H%M)'"
	}
	revert: {
		name:        "Revert Snapshot"
		description: "Revert to snapshot (requires name)"
		command:     "ssh \(NODE) 'pct rollback \(LXCID) '"
	}
}
