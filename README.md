# quicue

CUE framework for modeling any domain where things depend on other things.

You declare resources with a type (`@type`) and dependencies (`depends_on`). The framework computes everything else --- deployment plans, impact analysis, blast radius, rollback sequences, JSON-LD graphs, SHACL shapes, DCAT catalogs, PROV-O audit trails --- all as deterministic projections of one validated source of truth. No runtime, no database, no external serializer. Everything is `cue export`.

### Architecture

```
Layer 0 ─ apercue.ca          Generic graph patterns + W3C projections
                                 #Graph, #Charter, #ComplianceCheck
                                 JSON-LD, SHACL, SKOS, EARL, OWL-Time
                                     │
Layer 1 ─ quicue.ca            Infrastructure-specific patterns
                                 40+ types, 29 providers, execution plans
                                     │
Layer 2 ─ instances            Domain-specific graphs
              ├─ cmhc-retrofit   Construction PM (NHCF, Greener Homes)
              ├─ grdn            Homelab infrastructure
              └─ maison-613     Real estate operations (private)
                                     │
Layer 3 ─ services             Pre-computed outputs
              ├─ api.quicue.ca   727 static JSON endpoints
              ├─ demo.quicue.ca  D3 operator dashboard
              └─ kg.quicue.ca    Knowledge graph framework
```

### Try it

**[demo.quicue.ca](https://demo.quicue.ca/)** --- D3 dependency graph, execution planner, resource browser, Hydra explorer. 30 resources, 654 resolved commands, all from one CUE evaluation.

**[apercue.ca](https://apercue.ca)** --- Landing page + [ecosystem explorer](https://apercue.ca/explorer.html). The generic foundation layer proving compile-time W3C linked data works.

**[api.quicue.ca/docs](https://api.quicue.ca/docs)** --- Swagger UI. 654 endpoints across 29 providers.

All data uses RFC 5737 TEST-NET IPs and RFC 2606 example.com hostnames. Safe to explore.

### Repositories

| Repo | Description | Links |
|------|-------------|-------|
| **[apercue](https://github.com/quicue/apercue)** | Generic reference --- domain-agnostic typed graphs + W3C projections | [apercue.ca](https://apercue.ca) &#124; [explorer](https://apercue.ca/explorer.html) |
| **[quicue.ca](https://github.com/quicue/quicue.ca)** | Infrastructure patterns --- 40+ types, 29 providers, execution plans | [demo](https://demo.quicue.ca/) &#124; [API](https://api.quicue.ca/docs) &#124; [catalogue](https://cat.quicue.ca) |
| **[quicue-kg](https://github.com/quicue/quicue-kg)** | Knowledge graph framework --- decisions, patterns, insights | [kg.quicue.ca](https://kg.quicue.ca) &#124; [spec](https://kg.quicue.ca/spec/) |
| **[cmhc-retrofit](https://github.com/quicue/cmhc-retrofit)** | Construction PM --- NHCF deep retrofit + Greener Homes | [live](https://cmhc-retrofit.quicue.ca/) |

### W3C Spec Coverage

CUE comprehensions precompute all queries at eval time. CUE unification enforces all shapes. Every W3C artifact is a zero-cost projection.

| Spec | Layer | Status |
|------|-------|--------|
| JSON-LD 1.1 | apercue | @context, @type, @id mapping |
| SHACL | apercue | sh:ValidationReport from #ComplianceCheck, #GapAnalysis |
| SKOS | apercue | skos:ConceptScheme from type vocabulary, lifecycle phases |
| EARL | apercue | earl:Assertion test plans |
| OWL-Time | apercue | time:Interval from #CriticalPath |
| Dublin Core | apercue | dcterms:requires for dependency edges |
| PROV-O | apercue + kg | prov:wasDerivedFrom for knowledge entries |
| schema.org | apercue | schema:actionStatus for lifecycle |
| Hydra Core | quicue.ca | hydra:ApiDocumentation for operator dashboard |
| DCAT 3 | quicue-kg | dcat:Catalog for knowledge aggregation |
| ODRL 2.2 | quicue.ca | odrl:Policy for access control |

### Where it's used

| Domain | Project | Scale |
|--------|---------|-------|
| Generic reference | [apercue.ca](https://apercue.ca) | 4 domain examples, 9 W3C specs |
| IT infrastructure | [demo.quicue.ca](https://demo.quicue.ca/) | 30 resources, 29 providers, 654 commands |
| Construction PM | [CMHC NHCF](https://cmhc-retrofit.quicue.ca/) | 18 nodes, 27 edges, 8 phases |
| Energy efficiency | [Greener Homes](https://cmhc-retrofit.quicue.ca/#greener-homes) | 17 nodes, 25 edges, 6 layers |
| Real estate | maison-613 (private) | Transaction + compliance tracking |

### Quick start

```cue
// Infrastructure example (quicue.ca patterns)
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

```cue
// Generic example (apercue.ca patterns --- no infra dependency)
import "apercue.ca/patterns@v0"

resources: {
    "intro":     {name: "intro", "@type": {CoreCourse: true}}
    "algorithms": {name: "algorithms", "@type": {CoreCourse: true}, depends_on: {"intro": true}}
}

g: patterns.#Graph & {Input: resources}
// g.topology, g.roots, g.leaves --- computed automatically
```
