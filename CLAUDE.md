# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Style Rules

- **NEVER use emojis** in code, comments, commit messages, or documentation
- **NEVER include AI attribution** in commits (no "Generated with Claude", no Co-Authored-By)

## Project Overview

**quicue** (`quicue.ca@v0`) is a CUE vocabulary for modeling infrastructure as typed, queryable graphs. Dependencies become traversable edges enabling impact analysis, criticality ranking, and deployment planning.

## Commands

```bash
# Validate all CUE
cue vet ./...

# Run E2E tests (validates vocab, patterns, examples, and linked providers)
./examples/e2e/run.sh
./examples/e2e/run.sh -v  # Verbose
./examples/e2e/run.sh -j  # JSON summary only

# Evaluate examples
cue eval ./examples/graph-patterns/
cue eval ./examples/multi-region/ -e infra.topology

# Export JSON-LD
cue export ./examples/jsonld-export/ -e jsonld --out json

# CLI (thin wrapper with command echo for learning)
./bin/quicue impact dns-primary        # What breaks if dns-primary fails?
./bin/quicue impact dns-primary -f multi-region
./bin/quicue criticality -n 5          # Top 5 critical resources
./bin/quicue eval [example]            # Evaluate example
./bin/quicue list                      # List available examples
```

## Architecture

### Three-Layer Pattern

```
vocab/      LAYER 1: Interface - #Resource, #Action schemas
patterns/   LAYER 2: Patterns  - #InfraGraph, #ImpactQuery, providers
examples/   LAYER 3: Instance  - Concrete infrastructure definitions
```

**vocab/** defines the vocabulary:
- `resource.cue` - `#Resource` schema with generic fields (ip, host, container_id, vm_id)
- `types.cue` - `#TypeRegistry` mapping semantic types to required fields and granted actions
- `actions.cue` - `#Action` schema for executable operations

**patterns/** provides graph operations:
- `graph.cue` - `#InfraGraph` computes _depth, _ancestors, topology, roots, leaves
- `interfaces.cue` - `#VMActions`, `#ContainerActions` (provider-agnostic contracts)
- `providers.cue` - Provider templates mapping generic fields to platform commands

### Key Type System

Resources use struct-as-set for types (O(1) membership):
```cue
"@type": {DNSServer: true, LXCContainer: true}  // Internal
// Exports as: ["DNSServer", "LXCContainer"]    // JSON-LD
```

Types have three categories:
- **Semantic** (what it does): DNSServer, ReverseProxy, Database
- **Implementation** (how it runs): LXCContainer, DockerContainer, VirtualMachine
- **Classification** (operational tier): CriticalInfra

### Dependencies

```cue
depends_on: {dns: true, auth: true}  // Struct-as-set, not arrays
```

The `#InfraGraph` pattern converts string-based depends_on to traversable references, computing:
- `_depth` - Distance from roots (0 = no dependencies)
- `_ancestors` - Transitive closure of all dependencies
- `topology` - Resources grouped by layer

### Library vs Instance

**quicue is a LIBRARY, not an application.** It provides reusable patterns for others to consume.

```
LIBRARY LAYER (quicue ecosystem) - Generic, reusable patterns
├── quicue.ca           → Core vocab + graph algorithms
├── quicue.ca/infra     → Infrastructure projections (#DCOverview, etc.)
├── quicue.ca/proxmox   → Proxmox provider templates
├── quicue.ca/docker    → Docker provider templates
├── meta.quicue.ca      → Knowledge graph (projects, decisions, patterns)
├── quicue.ca/docs      → Ecosystem documentation generator
└── ...

INSTANCE LAYER (consumers) - Specific deployments
├── jrdn                → One team's cluster (mthdn homelab)
├── rfam                → Another tenant
└── [other clusters]    → Other teams using quicue
```

**When adding new code, ask:**
1. "Would another cluster/team need this?" → YES = put in quicue-* library
2. "Does it reference cluster-specific data?" → YES = belongs in instance layer
3. "Is it a reusable pattern (#Schema) or instance data?" → Pattern = library

**Schemas (`#Name`) belong in library. Instances (`name: #Schema & {...}`) belong in consumer repos.**
