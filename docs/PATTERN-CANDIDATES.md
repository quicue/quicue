# Pattern Candidates from quicue-icitte

This document identifies patterns from quicue-icitte demos that are strong candidates for promotion to core quicue.

## Summary

After reviewing 23 demos in quicue-icitte and comparing with the 7 existing core pattern files, these patterns emerge as candidates for core promotion based on general usefulness, domain independence, and battle-testing in icitte.

---

## High Priority Candidates

### 1. Reverse Lookup Patterns
**Demo:** 005-reverse-lookup

**What it does:**
- Query resources by arbitrary field values (IP, VLAN, port, owner, node)
- `#ByIP`, `#ByVLAN`, `#ByPort`, `#ByOwner`, `#ByNode` definitions
- Cross-reference queries (e.g., "What's on VLAN 20 on pve1?")

**Why it should be in core:**
- Universally useful regardless of infrastructure type
- Complements existing graph traversal (which goes dependency direction)
- Simple, composable patterns that work with any resource schema
- Core already has forward lookups (dependents, ancestors), needs reverse lookups by field

**Complexity:** Low
- Small, self-contained definitions
- No external dependencies
- Pattern already well-defined in demo

**Integration approach:** Add to `patterns/projections.cue` as generic field-based lookup patterns.

---

### 2. Environment Diff / Parity Analysis
**Demo:** 014-env-diff

**What it does:**
- Compare two environments (prod vs staging, primary vs DR)
- Detect: only_in_source, only_in_target, field-level differences
- Generate sync recommendations and parity scores

**Why it should be in core:**
- Multi-environment is universal (dev/staging/prod exists everywhere)
- Not domain-specific - works for any comparable resource sets
- Enables drift detection between intended states
- Core has validation but not cross-environment comparison

**Complexity:** Medium
- Requires generic field comparison logic
- May need helpers for deep struct comparison
- Pattern is well-defined but needs generalization

**Integration approach:** New file `patterns/diff.cue` with `#EnvDiff`, `#ParityScore`.

---

### 3. Orphan and Zombie Detection
**Demo:** 015-orphan-detection

**What it does:**
- Find orphans: resources with no dependencies AND nothing depends on them
- Find zombies: resources with unknown/missing owner
- Find stale: resources not accessed recently
- Calculate waste cost from orphans/zombies

**Why it should be in core:**
- Resource hygiene is universal (every org has orphaned resources)
- Directly enables cost optimization
- Builds on existing graph structure (uses depends_on)
- Works with any resource schema that has owner/accessed metadata

**Complexity:** Low-Medium
- Orphan detection: straightforward (uses existing graph)
- Zombie detection: needs convention for "owner" field
- Stale detection: needs date parsing (CUE limitation)

**Integration approach:** Add to `patterns/graph.cue` as `#OrphanQuery`, `#LeafResourceQuery`. Owner/staleness checks could be validation patterns.

---

### 4. Cascade Path Analysis
**Demo:** 022-cascade

**What it does:**
- Wave-based failure cascade simulation
- Given resource X fails, compute wave 0 (initial), wave 1 (direct), wave 2+ (transitive)
- Shows "domino effect" for infrastructure failures

**Why it should be in core:**
- Critical for incident planning and blast radius analysis
- Core has `#BlastRadius` but only computes flat list of affected
- Wave-based view shows TIME dimension (what fails first, second, etc.)
- Essential for runbook generation

**Complexity:** Medium
- Pattern exists but is hardcoded for specific depths
- Needs generalization for N waves
- CUE recursion limits apply

**Integration approach:** Enhance existing `#BlastRadius` in `patterns/graph.cue` with wave breakdown, or add new `#CascadeAnalysis`.

---

### 5. Bottleneck / Fan-In Analysis
**Demo:** 020-bottleneck

**What it does:**
- Count "fan-in" for each resource (how many things depend on it)
- Identify critical bottlenecks (fan-in >= threshold)
- Classify resources: critical, important, leaf

**Why it should be in core:**
- Core has `#CriticalityRank` which is similar
- But demo pattern is simpler and more queryable
- Classification buckets (critical/important/leaf) are actionable
- Fan-in is a fundamental graph metric

**Complexity:** Low
- Very simple pattern
- Core already does similar with `#CriticalityRank`
- May just need API adjustment

**Integration approach:** Enhance `#CriticalityRank` to include classification buckets and simpler fan-in counts.

---

### 6. Cycle Detection
**Demo:** 023-cycle-detect

**What it does:**
- Detect self-references (a -> a)
- Detect 2-hop cycles (a -> b -> a)
- Detect 3-hop cycles (a -> b -> c -> a)
- Detect missing dependency references

**Why it should be in core:**
- Graph validation fundamental - cycles break DAG assumption
- Core `#ValidateGraph` checks missing refs and self-refs
- Demo extends to 2-hop and 3-hop cycles
- Essential for preventing infinite loops in graph traversal

**Complexity:** Low-Medium
- Self-ref and 2-hop: trivial
- 3-hop+: O(n^3), may need limits
- CUE can't do true recursive cycle detection

**Integration approach:** Enhance `#ValidateGraph` in `patterns/graph.cue` to include 2-hop and 3-hop cycle detection.

---

### 7. Redundancy / SPOF Analysis
**Demo:** 021-redundancy

**What it does:**
- Identify resources with replicas vs single points of failure
- Assess SPOF risk by counting dependents
- Generate redundancy coverage metrics

**Why it should be in core:**
- Core has `#SinglePointsOfFailure` but it checks type/layer peers
- Demo pattern checks explicit replica relationships
- Both approaches valuable for different use cases
- Redundancy is universal infrastructure concern

**Complexity:** Low-Medium
- Requires convention for replica/replica_of fields
- Risk calculation straightforward
- Complements existing SPOF pattern

**Integration approach:** Add `#RedundancyCheck` to `patterns/graph.cue` as complement to `#SinglePointsOfFailure`.

---

## Medium Priority Candidates

### 8. Type-Based Capabilities
**Demo:** 006-type-capabilities

**What it does:**
- Registry mapping @type to available actions/capabilities
- Resources with multiple types get union of capabilities
- Query by capability (e.g., "find all resources that can be backed up")

**Why it should be in core:**
- Generalizes action dispatch based on type
- Core has interfaces but not a registry pattern
- Useful for building dynamic UIs/CLIs

**Complexity:** Medium
- Needs type registry schema
- Action merging from multiple types
- May overlap with existing interface pattern

**Integration approach:** New file `patterns/capabilities.cue` or extend `interfaces.cue`.

---

### 9. Compliance Policy Queries
**Demo:** 009-compliance-queries

**What it does:**
- Define policies as queryable data (not just pass/fail)
- Find violations with severity levels
- Generate compliance dashboards

**Why it should be in core:**
- Extends validation beyond structure to policy
- Generic policy framework applicable anywhere
- Queryable violations vs CUE's binary fail

**Complexity:** Medium-High
- Policy DSL design needed
- Severity levels, exceptions
- May be better as separate module

**Integration approach:** Could extend `patterns/validation.cue` or new `patterns/compliance.cue`.

---

### 10. Change Simulation
**Demo:** 016-change-simulation

**What it does:**
- `#BlockPort`: Simulate blocking a network port
- `#TakeDown`: Simulate resource failure
- `#ChangeIP`: Simulate IP address change
- Impact summary with severity classification

**Why it should be in core:**
- Enables "what-if" analysis before making changes
- Builds on graph structure
- Universal need for change management

**Complexity:** Medium
- Needs network topology modeling
- Severity classification heuristics
- Multiple simulation types

**Integration approach:** New file `patterns/simulation.cue`.

---

## Lower Priority / Domain-Specific

These are valuable but may be too specialized for core:

### 11. Capacity Planning (#CanFit)
**Demo:** 013-capacity-planning
- Bin-packing for VM placement
- Useful but requires specific resource fields (cores, memory, storage)
- Could be reference pattern rather than core

### 12. Cost Modeling
**Demo:** 011-cost-modeling
- Pricing models, chargeback calculation
- Very useful but pricing is organization-specific
- Better as example than core pattern

### 13. Migration Planner
**Demo:** 010-migration-planner
- Dependency-ordered migration with scripts
- Proxmox-specific command generation
- Core should have ordering; command gen is provider-specific

### 14. DNS Zone Generation
**Demo:** 018-dns-zones
- BIND/dnsmasq zone file generation
- Domain-specific but well-executed
- Better as separate module

### 15. Runbook Generation
**Demo:** 004-runbook-gen
- Markdown runbook from graph
- Proxmox-specific commands
- Core has building blocks; runbook template is user-specific

### 16. Incident Response Trees
**Demo:** 012-incident-response
- Decision tree for diagnostics
- Very domain-specific workflow
- Interesting pattern but hard to generalize

---

## Already Covered by Core

These demos demonstrate capabilities that already exist in core:

| Demo | Covered By |
|------|------------|
| 001-multi-projection | `patterns/projections.cue` |
| 002-impact-analysis | `#ImpactQuery`, `#BlastRadius` in `graph.cue` |
| 003-bulk-operations | Comprehensions + provider commands |
| 007-mermaid-diagrams | `#MermaidDiagram` in `visualization.cue` |
| 008-validation | `patterns/validation.cue` |
| 017-live-drift | Needs tool/ commands (outside core patterns) |
| 019-federated-gen | Standard CUE comprehensions |

---

## Recommended Implementation Order

1. **Reverse Lookup Patterns** - Low complexity, high value
2. **Cycle Detection Enhancement** - Low complexity, fills validation gap
3. **Bottleneck/Fan-In Enhancement** - Low complexity, enhances existing
4. **Orphan Detection** - Low-medium complexity, immediate cost value
5. **Cascade Path Analysis** - Medium complexity, enhances blast radius
6. **Redundancy Check** - Medium complexity, complements SPOF
7. **Environment Diff** - Medium complexity, universal need
8. **Type Capabilities** - Medium complexity, enables dynamic dispatch
9. **Change Simulation** - Medium complexity, unique value
10. **Compliance Queries** - Medium-high complexity, may warrant own module

---

## Notes

- All patterns should maintain the core design principles:
  - Use `#` definitions for schemas
  - Accept `Graph: #InfraGraph` parameter for graph-aware patterns
  - Be provider-agnostic (no hardcoded Proxmox/VMware/etc.)
  - Support struct-as-set `@type` pattern

- Consider performance implications:
  - Fan-in counting is O(n) per resource
  - Cascade waves are O(depth * n)
  - Environment diff is O(n * fields)

- Some patterns may benefit from `tool/` commands for live data (drift detection, capacity updates) but the core patterns should work with static data.
