# quicue

CUE framework for modeling any domain where things depend on other things.

You declare resources with a type (`@type`) and dependencies (`depends_on`). The framework computes everything else — deployment plans, impact analysis, blast radius, rollback sequences, JSON-LD graphs, SHACL shapes, DCAT catalogs, N-Triples, PROV-O audit trails — all as deterministic projections of one validated source of truth. No runtime, no database, no external serializer. Everything is `cue export`.

Used across IT infrastructure, construction project management, energy efficiency, and real estate operations — same pattern library, different domains.

**[quicue.ca](https://github.com/quicue/quicue.ca)** — the framework. 29 provider templates, 18 graph patterns, 19 W3C projection files.

**[quicue-kg](https://github.com/quicue/quicue-kg)** — the knowledge layer. Architectural decisions, patterns, insights. Projects to PROV-O, DCAT, SKOS, Web Annotation, N-Triples, Turtle, Prolog, Datalog.

Both share one IRI space. CUE comprehensions precompute every query at eval time — SPARQL is only needed once the data leaves the CUE closed world and joins external systems.

### Where it's used

| Domain | Project | Scale |
|--------|---------|-------|
| IT infrastructure | grdn, apercue | 50 nodes, 29 providers |
| Construction PM | [CMHC NHCF Deep Retrofit](https://cmhc-retrofit.quicue.ca/) | 18 nodes / 27 edges |
| Energy efficiency | [Greener Homes](https://cmhc-retrofit.quicue.ca/#greener-homes) | 17 nodes / 25 edges |
| Real estate | maison-613 | 7 workflow graphs |

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
