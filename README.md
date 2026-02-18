# quicue

Typed dependency graphs in CUE — model any domain as resources with `@type` and `depends_on`.

Two modules, one IRI space:

**[quicue.ca](https://github.com/quicue/quicue.ca)** models what exists — resources, dependencies, actions, deployment plans. 29 provider templates, graph analysis, blast radius, health propagation. Everything validates at `cue vet` time.

**[quicue-kg](https://github.com/quicue/quicue-kg)** captures why — architectural decisions, patterns, insights, rejected approaches. Exports to 8 linked data formats: PROV-O, DCAT, Web Annotation, SKOS, N-Triples, Turtle, Prolog, Datalog.

Both export to W3C standard vocabularies. A SPARQL query can join infrastructure state with the decisions that shaped it.

### Where it's used

| Domain | Project | Scale |
|--------|---------|-------|
| IT infrastructure | grdn, apercue | 50 nodes, 29 providers |
| Construction PM | [CMHC Retrofit](https://cmhc-retrofit.quicue.ca/) | 18 nodes / 27 edges |
| Energy efficiency | Greener Homes | 17 nodes / 25 edges |
| Real estate | maison-613 | 7 workflow graphs |

Same vocabulary, same patterns, different domains.

### Links

| | |
|---|---|
| **docs.quicue.ca** | [Patterns documentation](https://docs.quicue.ca) |
| **kg.quicue.ca** | [Knowledge graph documentation](https://kg.quicue.ca) |
| **kg.quicue.ca/spec** | [W3C-style specification](https://kg.quicue.ca/spec/) |
| **cat.quicue.ca** | [Provider catalogue](https://cat.quicue.ca) — 29 providers, OpenAPI, Swagger |

### Quick start

```cue
import "quicue.ca/patterns"

resources: {
    "dns":  {"@type": {DNSServer: true}}
    "db":   {"@type": {Database: true}, depends_on: {"dns": true}}
    "api":  {"@type": {APIServer: true}, depends_on: {"db": true}}
}

infra: patterns.#InfraGraph & {Input: resources}
// infra.topology = [["dns"], ["db"], ["api"]]

impact: patterns.#ImpactQuery & {Graph: infra, Target: "dns"}
// impact.affected = ["db", "api"]
```
