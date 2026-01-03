# multi-region

Complex multi-region infrastructure for testing all graph patterns.

## Test Coverage

| Feature | How it's tested |
|---------|-----------------|
| Multi-root | 2 regions (region-us, region-eu) |
| Diamond dependencies | web-eu → api-eu → db-replica → db-primary ← api-us |
| Deep chains | 6 layers (region → dns → lb → api → worker → job) |
| Cross-region deps | db-replica depends on db-primary (US→EU replication) |
| Cross-cutting | auth used by both regions |
| All 9 patterns | Exercised in output |

## Graph Structure

```
Layer 0: region-us, region-eu
Layer 1: dns-us, dns-eu, auth
Layer 2: lb-us, lb-eu, mq, cache, db-primary, monitoring
Layer 3: db-replica, search, api-us, logging
Layer 4: api-eu, web-us, worker-ingest, worker-notify
Layer 5: web-eu, job-cleanup, job-report
```

## Key Metrics

- **22 resources**
- **40 edges**
- **6 layers** (depth 5)
- **2 roots** (regions)
- **6 leaves** (frontends, jobs, observability)

## Run

```bash
cue eval ./examples/multi-region/ -e output
```

## Impact Analysis

| If this fails | Affected |
|---------------|----------|
| region-us | 19 resources |
| dns-us | 16 resources |
| auth | 16 resources |
| db-primary | 9 resources |
| mq | 8 resources |

## Diamond Dependency Example

`web-eu` has ancestors from both regions:

```cue
ancestors: [
    "lb-eu", "api-eu",           // EU path
    "dns-eu", "region-eu",       // EU infra
    "db-replica", "cache",       // Data tier
    "db-primary", "dns-us",      // Cross-region
    "auth", "region-us"          // Shared infra
]
```

This tests that `_ancestors` correctly computes transitive closure across diamond dependencies.

## Patterns Exercised

1. `#InfraGraph` - topology, roots, leaves, valid
2. `#ImpactQuery` - 4 different targets
3. `#DependencyChain` - deepest node (job-cleanup), cross-region (web-eu)
4. `#ImmediateDependents` - dns-us, auth
5. `#CriticalityRank` - sorted top 5
6. `#GroupByType` - 12 different types
7. `#GraphMetrics` - summary stats
8. `#ExportGraph` - (available via export)
9. `#ValidateGraph` - confirms no issues
