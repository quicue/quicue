package vocab

// Type Registry - Pure data mapping semantic types to actions
// Consumers apply conditionals at their site, not here.
//
// Usage:
//   import "quicue.ca/vocab"
//
//   for typeName in res["@type"] {
//       if vocab.#TypeRegistry[typeName] != _|_ {
//           for actionName in vocab.#TypeRegistry[typeName].actions {
//               // Apply action template with resource params
//           }
//       }
//   }
//
// Type Categories:
//   - Semantic: DNSServer, ReverseProxy, Vault (what it does)
//   - Implementation: LXCContainer, DockerContainer (how it runs)
//   - Classification: CriticalInfra (operational tier)
//
// Validation:
//   Use #ValidTypes to validate @type arrays against the registry

#TypeRegistry: {
	// Infrastructure Services
	DNSServer: {
		description: "DNS/name resolution server"
		actions: ["check_dns", "verify_resolution", "query_zones"]
	}

	ReverseProxy: {
		description: "HTTP/HTTPS reverse proxy (Caddy, nginx, Traefik)"
		actions: ["proxy_health", "reload_config", "test_config"]
	}

	// Virtualization
	VirtualizationPlatform: {
		description: "Hypervisor node (Proxmox, VMware, Nutanix)"
		actions: ["list_vms", "list_containers", "cluster_status"]
	}

	// Source Control
	SourceControlManagement: {
		description: "Git server (Forgejo, GitLab, Gitea)"
		actions: ["git_health", "list_repos"]
	}

	// Security
	Bastion: {
		description: "SSH jump host / bastion server"
		actions: ["list_active_sessions", "check_auth_log"]
	}

	Vault: {
		description: "Secrets management (Vaultwarden, HashiCorp Vault)"
		actions: ["check_vault"]
	}

	// Monitoring
	MonitoringServer: {
		description: "Metrics/alerting server (Prometheus, Grafana)"
		actions: ["prometheus_targets"]
	}

	// Compute
	DevelopmentWorkstation: {
		description: "Developer machine with containers/VMs"
		actions: ["docker_ps", "disk_usage", "gpu_info"]
	}

	GPUCompute: {
		description: "GPU-enabled compute node"
		actions: ["gpu_info"]
	}

	// Containers
	LXCContainer: {
		description: "Linux container (Proxmox LXC, LXD)"
		actions: ["status", "start", "stop", "restart", "console", "logs"]
	}

	DockerContainer: {
		description: "Docker container"
		actions: ["status", "start", "stop", "restart", "logs", "exec", "shell"]
	}

	ComposeStack: {
		description: "Docker Compose application stack"
		actions: ["status", "up", "down", "restart", "logs", "pull"]
	}

	// Classification markers (no specific actions, used for filtering)
	CriticalInfra: {
		description: "Critical infrastructure - extra monitoring/alerting"
		actions: []
	}

	// Allow extension
	...
}

// #TypeNames - List of all known type names for validation
#TypeNames: or([for k, _ in #TypeRegistry {k}])

// #ValidTypes - Validate that all types in array are known
// Usage: myResource: { "@type": vocab.#ValidTypes & ["DNSServer", "LXCContainer"] }
#ValidTypes: [...#TypeNames]

// #TypeEntry - Schema for type registry entries
#TypeEntry: {
	description: string
	actions: [...string]
}
