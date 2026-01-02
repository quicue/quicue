package vocab

// JSON-LD context for quicue semantic types
// Generated from #TypeRegistry
// Export: cue export ./vocab -e context --out json > context.jsonld

context: {
	"@context": {
		// Namespace
		"quicue": "https://quicue.ca/vocab#"

		// Map each semantic type to the vocabulary
		for typeName, _ in #TypeRegistry {
			"\(typeName)": {
				"@id":   "quicue:\(typeName)"
				"@type": "@id"
			}
		}

		// Standard resource fields
		"name": "quicue:name"
		"ip":   "quicue:ipAddress"
		"ssh_user": {
			"@id":   "quicue:sshUser"
			"@type": "@id"
		}
		"node":  "quicue:hypervisorNode"
		"vmid":  "quicue:virtualMachineId"
		"lxcid": "quicue:containerId"

		// Relationships
		"depends_on": {
			"@id":   "quicue:dependsOn"
			"@type": "@id"
		}
		"hosted_on": {
			"@id":   "quicue:hostedOn"
			"@type": "@id"
		}
		"provides": {
			"@id":        "quicue:provides"
			"@container": "@set"
		}

		// Actions
		"actions": {
			"@id":        "quicue:hasAction"
			"@container": "@set"
		}
	}
}
