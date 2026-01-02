# quicue

Semantic vocabulary for infrastructure-as-graph using CUE.

## Overview

quicue provides a CUE-based vocabulary for describing infrastructure:
- **Semantic types** - JSON-LD compatible `@type` annotations
- **Action providers** - Composable action sets (Proxmox, Docker)
- **Graph patterns** - Dependency tracking, impact analysis

## Quick Start

```bash
./quicue                      # List resources
./quicue dns                  # Show resource details
./quicue dns ping             # Execute action
./quicue dns ping dry         # Show command without executing
./quicue actions dns          # List all actions
./quicue types                # List resource types
./quicue types LXCContainer   # List resources of type
./quicue critical             # List critical infrastructure
./quicue deps                 # Show dependency graph
./quicue json                 # Export full inventory
```

## Structure

```
vocab/                  Semantic vocabulary (importable)
├── types.cue           Type registry (13 types)
├── actions.cue         Action interfaces (#Action, #ContainerActions, etc.)
└── context.cue         JSON-LD @context

patterns/               Graph utilities
└── graph.cue           #InfraGraph, #ImpactQuery, #ValidateGraph

reference/              Example implementation
├── schema.cue          #Resource definition
├── providers/
│   ├── proxmox/        LXC/VM actions (pct, qm commands)
│   └── docker/         Container/Compose actions
├── inventory.cue       Example 3-node cluster
└── cmd_tool.cue        CLI commands

examples/               Standalone demos
├── 3-layer.cue         Interface/Provider/Instance pattern
├── type-composition.cue
└── jsonld-export.cue
```

## Example Cluster

The reference includes a 3-node Proxmox cluster:

| Node | Resources |
|------|-----------|
| pve-alpha | dns (192.33.33.53), proxy (192.33.33.80) |
| pve-beta | git (192.33.33.81), monitoring (192.33.33.82) |
| pve-gamma | vault (192.33.33.83), bastion (192.33.33.22) |

## Adding Resources

Edit `reference/inventory.cue`:

```cue
_resources: {
    "my-service": {
        types:       ["LXCContainer", "MyServiceType"]
        node:        _nodes.alpha
        lxcid:       150
        ip:          "192.33.33.150"
        ssh_user:    "root"
        depends_on:  ["dns", "proxy"]
        provides:    ["my-capability"]
        description: "My new service"
    }
}
```

Actions are computed by unifying providers in the `output` section.

## Type Registry

Available types in `vocab/types.cue`:

| Category | Types |
|----------|-------|
| Infrastructure | DNSServer, ReverseProxy, VirtualizationPlatform |
| Services | SourceControlManagement, MonitoringServer, Vault |
| Compute | DevelopmentWorkstation, GPUCompute, Bastion |
| Containers | LXCContainer, DockerContainer, ComposeStack |
| Classification | CriticalInfra |

## CI Artifacts

Generated on push to main:
- `context.jsonld` - JSON-LD @context
- `inventory.json` - Full inventory with actions
- `3-layer.json`, `type-composition.json`, `jsonld-graph.json`

## Development

```bash
cue vet ./...                                           # Validate
cue export ./reference/inventory.cue -e output --out json  # Export inventory
cue export ./vocab -e context --out json                # Export context
```
