// Type Registry - Semantic types for infrastructure resources
//
// Types describe WHAT a resource IS, not what it can do.
// Actions are defined by providers, not by type declarations.
//
// Usage:
//   import "quicue.ca/vocab@v0"
//
//   myResource: vocab.#Resource & {
//       "@type": ["LXCContainer", "DNSServer"]
//   }
//
// Type Categories:
//   - Semantic: DNSServer, ReverseProxy, Vault (what it does)
//   - Implementation: LXCContainer, DockerContainer (how it runs)
//   - Classification: CriticalInfra (operational tier)

package vocab

// #TypeRegistry - Catalog of known semantic types
#TypeRegistry: {
	// ========== Implementation Types (how it runs) ==========

	LXCContainer: {
		description: "Proxmox LXC container"
	}

	DockerContainer: {
		description: "Docker container"
	}

	ComposeStack: {
		description: "Docker Compose application stack"
	}

	VirtualMachine: {
		description: "Virtual machine (Proxmox QEMU, VMware, etc.)"
	}

	// ========== Semantic Types (what it does) ==========

	DNSServer: {
		description: "DNS/name resolution server"
	}

	ReverseProxy: {
		description: "HTTP/HTTPS reverse proxy (Caddy, nginx, Traefik)"
	}

	VirtualizationPlatform: {
		description: "Hypervisor node (Proxmox, VMware, Nutanix)"
	}

	SourceControlManagement: {
		description: "Git server (Forgejo, GitLab, Gitea)"
	}

	Bastion: {
		description: "SSH jump host / bastion server"
	}

	Vault: {
		description: "Secrets management (Vaultwarden, HashiCorp Vault)"
	}

	MonitoringServer: {
		description: "Metrics/alerting server (Prometheus, Grafana)"
	}

	LogAggregator: {
		description: "Log collection and aggregation (Loki, ELK)"
	}

	DevelopmentWorkstation: {
		description: "Developer machine with containers/VMs"
	}

	GPUCompute: {
		description: "GPU-enabled compute node"
	}

	AuthServer: {
		description: "Authentication/identity provider"
	}

	LoadBalancer: {
		description: "Load balancer / traffic distribution"
	}

	MessageQueue: {
		description: "Message broker (RabbitMQ, Kafka, NATS)"
	}

	CacheCluster: {
		description: "Distributed cache (Redis, Memcached)"
	}

	Database: {
		description: "Database server (PostgreSQL, MySQL, MongoDB)"
	}

	SearchIndex: {
		description: "Search engine (Elasticsearch, Meilisearch)"
	}

	APIServer: {
		description: "API backend service"
	}

	WebFrontend: {
		description: "Web frontend / UI server"
	}

	Worker: {
		description: "Background job processor"
	}

	ScheduledJob: {
		description: "Cron/scheduled task runner"
	}

	// ========== Infrastructure Types ==========

	Region: {
		description: "Geographic region / data center location"
	}

	AvailabilityZone: {
		description: "Availability zone within a region"
	}

	// ========== Classification Types (operational tier) ==========

	CriticalInfra: {
		description: "Critical infrastructure - extra monitoring/alerting"
	}

	// Allow extension
	...
}

// #TypeNames - Disjunction of all known type names for validation
#TypeNames: or([for k, _ in #TypeRegistry {k}])

// #ValidTypes - Validate that all types in array are known
// Usage: myResource: { "@type": vocab.#ValidTypes & ["DNSServer", "LXCContainer"] }
#ValidTypes: [...#TypeNames]

// #TypeEntry - Schema for type registry entries
#TypeEntry: {
	description: string
}
