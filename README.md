# quicue

CUE framework for modeling any domain where things depend on other things.

You declare resources with a type (`@type`) and dependencies (`depends_on`). The framework computes everything else: deployment order, impact analysis, blast radius, rollback plans, and W3C linked data exports. No runtime, no database — all at `cue vet` time.

Used across IT infrastructure, construction project management, energy efficiency, and real estate operations — same pattern library, different domains.

**[quicue.ca](https://github.com/quicue/quicue.ca)** — the framework. 29 provider templates, 18 graph patterns, 12+ export formats.

**[quicue-kg](https://github.com/quicue/quicue-kg)** — the knowledge layer. Architectural decisions, patterns, insights. Exports to PROV-O, DCAT, SKOS, N-Triples, Turtle, Prolog, Datalog.

Both share one IRI space. Inside the CUE closed world, comprehensions precompute every query at eval time — no SPARQL needed. The W3C exports exist for when the data leaves CUE and joins external systems.

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
