// Homelab Example: Real Proxmox Cluster (jrdn + rfam)
//
// This example models an actual 3-node Proxmox cluster with LXC containers,
// VMs, and Docker services. Dependencies show startup order and impact analysis.
//
// Run:
//   cue vet ./examples/homelab/
//   cue export ./examples/homelab/ -e summary
//   cue export ./examples/homelab/ -e impact_dns

package homelab

import (
	"quicue.ca/vocab@v0"
	"quicue.ca/patterns@v0"
)

// ============================================================================
// INFRASTRUCTURE RESOURCES
// ============================================================================

_resources: [Name=string]: vocab.#Resource & {name: Name}

_resources: {
	// =========================================================================
	// Layer 0: Proxmox Nodes (bare metal)
	// =========================================================================
	"tulip": {
		"@type": {VirtualizationPlatform: true}
		ip:       "172.20.1.10"
		ssh_user: "root"
	}

	"poppy": {
		"@type": {VirtualizationPlatform: true}
		ip:       "172.20.1.20"
		ssh_user: "root"
	}

	"clover": {
		"@type": {VirtualizationPlatform: true}
		ip:       "172.20.1.30"
		ssh_user: "root"
	}

	// =========================================================================
	// Layer 1: Core Infrastructure (DNS, Proxy, Registry)
	// =========================================================================
	"technitium": {
		"@type": {LXCContainer: true, DNSServer: true, CriticalInfra: true}
		ip:           "172.20.1.211"
		container_id: 211
		host:         "tulip"
		depends_on: {"tulip": true}
	}

	"caddy": {
		"@type": {LXCContainer: true, ReverseProxy: true, CriticalInfra: true}
		ip:           "172.20.1.212"
		container_id: 212
		host:         "tulip"
		depends_on: {
			"tulip":      true
			"technitium": true
		}
	}

	"zot": {
		"@type": {LXCContainer: true, ContainerRegistry: true}
		ip:           "172.20.1.220"
		url:          "http://172.20.1.220:5000"
		container_id: 220
		host:         "tulip"
		depends_on: {
			"tulip":      true
			"technitium": true
		}
	}

	// =========================================================================
	// Layer 2: Platform Services (GitLab, Monitoring, Storage)
	// =========================================================================
	"gitlab": {
		"@type": {LXCContainer: true, SourceControlManagement: true}
		ip:           "172.20.1.214"
		url:          "https://gitlab.jrdn.local"
		container_id: 214
		host:         "poppy"
		depends_on: {
			"poppy":      true
			"technitium": true
			"caddy":      true
		}
	}

	"gitlab-runner": {
		"@type": {LXCContainer: true, CIRunner: true}
		ip:           "172.20.1.218"
		container_id: 218
		host:         "poppy"
		depends_on: {
			"poppy":      true
			"technitium": true
			"gitlab":     true
			"zot":        true
		}
	}

	"monitoring": {
		"@type": {LXCContainer: true, MonitoringServer: true}
		ip:           "172.20.1.213"
		url:          "http://172.20.1.213:3000"
		container_id: 213
		host:         "tulip"
		depends_on: {
			"tulip":      true
			"technitium": true
		}
	}

	"minio": {
		"@type": {LXCContainer: true, ObjectStorage: true}
		ip:           "172.20.1.217"
		url:          "http://172.20.1.217:9000"
		container_id: 217
		host:         "clover"
		depends_on: {
			"clover":     true
			"technitium": true
		}
	}

	"jaeger": {
		"@type": {LXCContainer: true, TracingBackend: true}
		ip:           "172.20.1.227"
		url:          "http://172.20.1.227:16686"
		container_id: 227
		host:         "clover"
		depends_on: {
			"clover":     true
			"technitium": true
		}
	}

	// =========================================================================
	// Layer 3: Application Services
	// =========================================================================
	"vaultwarden": {
		"@type": {LXCContainer: true, Vault: true}
		ip:           "172.20.1.215"
		url:          "https://vault.jrdn.local"
		container_id: 215
		host:         "poppy"
		depends_on: {
			"poppy":      true
			"technitium": true
			"caddy":      true
		}
	}

	"uptime-kuma": {
		"@type": {LXCContainer: true, StatusMonitor: true}
		ip:           "172.20.1.216"
		url:          "http://172.20.1.216:3001"
		container_id: 216
		host:         "poppy"
		depends_on: {
			"poppy":      true
			"technitium": true
			"caddy":      true
		}
	}

	"guacamole": {
		"@type": {LXCContainer: true, Bastion: true}
		ip:           "172.20.1.219"
		container_id: 219
		host:         "clover"
		ssh_user:     "root"
		depends_on: {
			"clover":     true
			"technitium": true
			"caddy":      true
		}
	}

	// =========================================================================
	// Layer 4: Docker Host + Media Services (family-stack)
	// =========================================================================
	"family-stack": {
		"@type": {VirtualMachine: true, CriticalInfra: true}
		ip:    "172.20.1.131"
		vm_id: 131
		host:  "clover"
		depends_on: {
			"clover":     true
			"technitium": true
			"caddy":      true
			"minio":      true
		}
	}

	// --- Docker containers on family-stack ---

	"jellyfin": {
		"@type": {DockerContainer: true, MediaServer: true}
		container_name: "jellyfin"
		host:           "family-stack"
		url:            "http://172.20.1.131:8096"
		port:           8096
		depends_on: {
			"family-stack": true
			"technitium":   true
			"caddy":        true
		}
	}

	"immich-postgres": {
		"@type": {DockerContainer: true, Database: true}
		container_name: "immich-postgres"
		host:           "family-stack"
		url:            "postgresql://172.20.1.131:5432"
		port:           5432
		depends_on: {
			"family-stack": true
		}
	}

	"immich-redis": {
		"@type": {DockerContainer: true, CacheCluster: true}
		container_name: "immich-redis"
		host:           "family-stack"
		url:            "redis://172.20.1.131:6379"
		port:           6379
		depends_on: {
			"family-stack": true
		}
	}

	"immich-ml": {
		"@type": {DockerContainer: true, Worker: true}
		container_name: "immich-machine-learning"
		host:           "family-stack"
		depends_on: {
			"family-stack": true
		}
	}

	"immich-server": {
		"@type": {DockerContainer: true, PhotoManagement: true}
		container_name: "immich-server"
		host:           "family-stack"
		url:            "http://172.20.1.131:2283"
		port:           2283
		depends_on: {
			"family-stack":   true
			"immich-postgres": true
			"immich-redis":    true
			"immich-ml":       true
			"caddy":           true
		}
	}

	"audiobookshelf": {
		"@type": {DockerContainer: true, AudiobookLibrary: true}
		container_name: "audiobookshelf"
		host:           "family-stack"
		url:            "http://172.20.1.131:13378"
		port:           13378
		depends_on: {
			"family-stack": true
			"caddy":        true
		}
	}

	"calibreweb": {
		"@type": {DockerContainer: true, EbookLibrary: true}
		container_name: "calibre-web"
		host:           "family-stack"
		url:            "http://172.20.1.131:8083"
		port:           8083
		depends_on: {
			"family-stack": true
			"caddy":        true
		}
	}

	"kavita": {
		"@type": {DockerContainer: true, EbookLibrary: true}
		container_name: "kavita"
		host:           "family-stack"
		url:            "http://172.20.1.131:5000"
		port:           5000
		depends_on: {
			"family-stack": true
			"caddy":        true
		}
	}

	"mealie": {
		"@type": {DockerContainer: true, RecipeManager: true}
		container_name: "mealie"
		host:           "family-stack"
		url:            "http://172.20.1.131:9925"
		port:           9925
		depends_on: {
			"family-stack": true
			"caddy":        true
		}
	}

	"cloudflared": {
		"@type": {DockerContainer: true, TunnelEndpoint: true}
		container_name: "cloudflared"
		host:           "family-stack"
		depends_on: {
			"family-stack": true
			"caddy":        true
		}
	}

	"landing": {
		"@type": {DockerContainer: true, WebFrontend: true}
		container_name: "landing"
		host:           "family-stack"
		url:            "http://172.20.1.131:80"
		port:           80
		depends_on: {
			"family-stack": true
			"caddy":        true
		}
	}

	// =========================================================================
	// Other VMs / LXCs
	// =========================================================================
	"plex": {
		"@type": {LXCContainer: true, MediaServer: true}
		ip:           "172.20.1.228"
		url:          "http://172.20.1.228:32400"
		container_id: 228
		host:         "clover"
		depends_on: {
			"clover":     true
			"technitium": true
		}
	}

	"haos": {
		"@type": {VirtualMachine: true, HomeAutomation: true}
		ip:    "172.20.1.119"
		url:   "http://172.20.1.119:8123"
		vm_id: 119
		host:  "poppy"
		depends_on: {
			"poppy":      true
			"technitium": true
		}
	}

	"beeton": {
		"@type": {LXCContainer: true, Bastion: true}
		ip:           "172.20.1.117"
		container_id: 117
		host:         "tulip"
		ssh_user:     "jump"
		depends_on: {
			"tulip":      true
			"technitium": true
		}
	}

	"devqg": {
		"@type": {VirtualMachine: true, DevelopmentWorkstation: true}
		ip:    "172.20.1.101"
		vm_id: 101
		host:  "tulip"
		depends_on: {
			"tulip":      true
			"technitium": true
			"gitlab":     true
			"beeton":     true
		}
	}
}

// ============================================================================
// GRAPH & QUERIES
// ============================================================================

infraGraph: patterns.#InfraGraph & {Input: _resources}

// Impact: What breaks if DNS fails?
impact_dns: patterns.#ImpactQuery & {
	Graph:  infraGraph
	Target: "technitium"
}

// Impact: What breaks if family-stack fails?
impact_family_stack: patterns.#ImpactQuery & {
	Graph:  infraGraph
	Target: "family-stack"
}

// Criticality: What are the most critical resources?
criticality: patterns.#CriticalityRank & {
	Graph: infraGraph
}

// Dependency chain: What's needed to start immich?
chain_immich: patterns.#DependencyChain & {
	Graph:  infraGraph
	Target: "immich-server"
}

// Validation
validation: patterns.#ValidateGraph & {
	Input: _resources
}

// VizData for graph explorer
vizData: patterns.#VizData & {
	Graph:     infraGraph
	Resources: _resources
}

// ============================================================================
// SUMMARY
// ============================================================================

summary: {
	total_resources:          len(_resources)
	proxmox_nodes:            3
	docker_containers:        11
	graph_valid:              infraGraph.valid
	dns_impact_count:         len(impact_dns.affected)
	family_stack_impact:      len(impact_family_stack.affected)
	most_critical:            criticality.ranked[0].name
	immich_startup_depth:     chain_immich.depth
}
