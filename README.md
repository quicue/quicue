# quicue

Infrastructure as typed dependency graphs in CUE.

Two modules, one IRI space:

**[quicue.ca](https://github.com/quicue/quicue.ca)** models what infrastructure *is* — resources, dependencies, actions, deployment plans. 29 provider templates, graph analysis, blast radius, health propagation. Everything validates at `cue vet` time.

**[quicue-kg](https://github.com/quicue/quicue-kg)** captures *why* it exists — architectural decisions, patterns, insights, rejected approaches. Exports to 8 linked data formats: PROV-O, DCAT, Web Annotation, SKOS, N-Triples, Turtle, Prolog, Datalog.

Both export to W3C standard vocabularies. A SPARQL query can join infrastructure state with the decisions that shaped it.

### Links

| | |
|---|---|
| **docs.quicue.ca** | [Infrastructure patterns documentation](https://docs.quicue.ca) |
| **kg.quicue.ca** | [Knowledge graph framework documentation](https://kg.quicue.ca) |
| **kg.quicue.ca/spec** | [W3C-style specification](https://kg.quicue.ca/spec/) |
| **kg.quicue.ca/semantic-web** | [Semantic web & linked data overview](https://kg.quicue.ca/semantic-web/) |
| **api.quicue.ca** | Infrastructure execution API (Hydra JSON-LD) |

### Quick start

```cue
import "quicue.ca/patterns@v0"

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
