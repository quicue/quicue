package meta

project: {
	"@id":        "https://quicue.ca/project/quicue"
	description:  "Infrastructure as a CUE value. Dependencies become traversable edges enabling impact analysis, criticality ranking, and deployment planning."
	status:       "active"

	schemas: [{
		name:        "#Resource"
		description: "Base schema for all infrastructure resources with generic fields (ip, host, container_id, vm_id) and struct-as-set types."
	}, {
		name:        "#InfraGraph"
		description: "Transforms loose resources into a topological graph with computed _depth, _ancestors, topology, roots, leaves, and dependents."
	}, {
		name:        "#ImpactQuery"
		description: "Computes transitive failure cascades (blast radius) - 'If X fails, what breaks?'"
	}, {
		name:        "#TypeRegistry"
		description: "Maps semantic types (DNSServer, Database) to required fields and granted actions."
	}]

	quickstart: """
		import "quicue.ca@v0/patterns"
		import "quicue.ca@v0/vocab"

		infra: patterns.#InfraGraph & {
		    resources: {
		        dns: vocab.#Resource & {
		            "@type": {DNSServer: true}
		            ip: "10.0.0.1"
		        }
		        app: vocab.#Resource & {
		            "@type": {APIServer: true}
		            depends_on: {dns: true}
		        }
		    }
		}
		"""

	related: [
		{"@id": "https://quicue.ca/project/quicue-docker"},
		{"@id": "https://quicue.ca/project/quicue-proxmox"},
		{"@id": "https://quicue.ca/project/quicue-meta"},
	]
}
