# Infrastructure dependencies in CUE

Resources with dependencies:

```cue
resources: {
    hypervisor: {}
    dns:        {depends_on: {"hypervisor": true}}
    database:   {depends_on: {"dns": true}}
    cache:      {depends_on: {"dns": true}}
    api:        {depends_on: {"database": true, "cache": true}}
    web:        {depends_on: {"api": true}}
}
```

Questions I want to answer:

- What breaks if `dns` goes down?
- What order should things start?

## The approach

Each resource gets an `ancestors` field containing everything it transitively depends on:

```cue
infra: {
    for name, r in resources {
        (name): r & {
            ancestors: {
                if r.depends_on != _|_ {
                    for dep, _ in r.depends_on {
                        (dep): true
                        for a, _ in infra[dep].ancestors {(a): true}
                    }
                }
            }
        }
    }
}
```

The line `for a, _ in infra[dep].ancestors` references the field being defined. CUE resolves the evaluation order.

## Output

```text
$ cue eval .

if_dns_fails: ["database", "cache", "api", "web"]

startup:  ["hypervisor", "dns", "database", "cache", "api", "web"]
shutdown: ["web", "api", "cache", "database", "dns", "hypervisor"]

criticality: {
    hypervisor: 5
    dns:        4
    database:   2
    cache:      2
    api:        1
    web:        0
}
```

## Question

Is this an idiomatic use of CUE? Is there a better way to compute transitive dependencies?
