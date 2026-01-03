# jsonld-export

Export graph as valid JSON-LD with @context and @graph.

## Key Concepts

- `@base` resolves relative IRI references in `depends_on` values
- `@context` maps generic field names to semantic IRIs
- `@graph` contains resources with `@id` and `@type`
- Output is valid JSON-LD - test at https://json-ld.org/playground/

## The Pattern

```cue
import "quicue.ca/vocab@v0"

// Resources with JSON-LD annotations
_resources: {
    "dns-primary": vocab.#Resource & {
        "@id":        "https://infra.example.com/resources/dns-primary"
        "@type":      ["DNSServer", "LXCContainer"]
        name:         "dns-primary"
        ip:           "10.0.1.10"
        host:         "pve-node-1"
        container_id: 100
    }
    "reverse-proxy": vocab.#Resource & {
        "@type":   ["ReverseProxy", "LXCContainer"]
        depends_on: ["dns-primary"]  // resolves via @base
        // ...
    }
}

// JSON-LD document
{
    "@context": vocab.context."@context"
    "@graph": [for _, r in _resources {r}]
}
```

With `@base: "https://infra.example.com/resources/"`, the string `"dns-primary"` in `depends_on` resolves to the full IRI `https://infra.example.com/resources/dns-primary`, making the graph traversable by RDF tools.

## Run

```bash
cue export ./examples/jsonld-export/ --out json
```

## Output

```json
{
    "@context": {
        "LXCContainer": "quicue:LXCContainer",
        "DNSServer": "quicue:DNSServer",
        "ReverseProxy": "quicue:ReverseProxy",
        "VirtualizationPlatform": "quicue:VirtualizationPlatform",
        "SourceControlManagement": "quicue:SourceControlManagement",
        "CriticalInfra": "quicue:CriticalInfra",
        "@base": "https://infra.example.com/resources/",
        "quicue": "https://quicue.ca/vocab#",
        "name": "quicue:name",
        "ip": "quicue:ipAddress",
        "host": "quicue:host",
        "container_id": "quicue:containerId",
        "depends_on": {
            "@id": "quicue:dependsOn",
            "@type": "@id"
        },
        "provides": {
            "@id": "quicue:provides",
            "@container": "@set"
        }
    },
    "@graph": [
        {
            "@id": "https://infra.example.com/resources/dns-primary",
            "@type": ["DNSServer", "LXCContainer", "CriticalInfra"],
            "name": "dns-primary",
            "ip": "10.0.1.10",
            "host": "pve-node-1",
            "container_id": 100,
            "provides": ["dns"]
        },
        {
            "@id": "https://infra.example.com/resources/reverse-proxy",
            "@type": ["ReverseProxy", "LXCContainer"],
            "name": "reverse-proxy",
            "depends_on": ["dns-primary"],
            "provides": ["proxy", "tls-termination"]
        }
    ]
}
```

Note: Output abbreviated. The full export includes all resources and context mappings.
