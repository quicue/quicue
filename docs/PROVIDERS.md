# Provider Development Guide

A **provider** is a CUE module that implements platform-specific actions for quicue. Providers translate abstract action interfaces (like "status", "console", "logs") into concrete commands for a specific platform (Proxmox, Docker, AWS, etc.).

## Core Concepts

### What Providers Do

1. **Implement interfaces** from `quicue.ca/vocab` or `quicue.ca/patterns`
2. **Define commands** using platform-specific CLI tools
3. **Export templates** that users unify with their infrastructure data

### Architecture

```
quicue (core)
├── vocab/actions.cue      # #Action schema
└── patterns/interfaces.cue # Interface contracts (#VMActions, #ContainerActions, etc.)

quicue-proxmox (provider)
└── patterns/
    ├── proxmox.cue        # Interface implementations
    └── templates.cue      # Reusable action templates

quicue-docker (provider)
└── patterns/
    ├── docker.cue         # Interface implementations
    └── templates.cue      # Reusable action templates
```

## Required Interfaces

Import and implement interfaces from the core vocabulary:

```cue
import "quicue.ca/vocab"

// Implement vocab.#VMActions for VM management
#VMActions: vocab.#VMActions & {
    // Your implementation
}

// Implement vocab.#ContainerActions for containers
#ContainerActions: vocab.#ContainerActions & {
    // Your implementation
}
```

### Available Interfaces

| Interface | Required Actions | Optional Actions |
|-----------|-----------------|------------------|
| `#VMActions` | `status` | `console`, `config` |
| `#ContainerActions` | `status`, `console` | `logs` |
| `#LifecycleActions` | `start`, `stop` | `restart` |
| `#SnapshotActions` | `list`, `create` | `revert` |
| `#HypervisorActions` | `list_vms`, `list_containers` | `cluster_status` |
| `#ConnectivityActions` | `ping`, `ssh` | - |
| `#GuestActions` | `exec` | `upload`, `download` |

## Template Pattern

### UPPERCASE Parameters

Template parameters MUST use UPPERCASE names. This is a CUE requirement - hidden fields (`_foo`) are package-scoped and don't unify across import boundaries.

```cue
// CORRECT: UPPERCASE parameters are visible and unify
#VMActions: {
    VMID: int           // Required parameter
    NODE: string        // Required parameter
    USER: string | *"root"  // Optional with default

    status: {
        command: "ssh \(USER)@\(NODE) 'qm status \(VMID)'"
    }
}

// WRONG: Hidden fields won't work across packages
#VMActions: {
    _vmid: int  // Will not unify when imported
    ...
}
```

### Default Values

Use `| *` for optional fields so consumers can override specific values:

```cue
status: {
    name:        string | *"VM Status"
    description: string | *"Check VM \(VMID) status"
    command:     string | *"ssh \(NODE) 'qm status \(VMID)'"
    icon:        string | *"[status]"
    category:    string | *"monitor"
}
```

## Step-by-Step: Create a New Provider

### 1. Create Module Structure

```bash
mkdir -p quicue-myplatform/patterns
cd quicue-myplatform
cue mod init quicue.ca/myplatform
```

### 2. Add Dependencies

Create `cue.mod/module.cue`:

```cue
module: "quicue.ca/myplatform"
language: version: "v0.9.0"

deps: "quicue.ca/vocab@v0": v: "v0.0.1"
```

### 3. Implement Actions (patterns/myplatform.cue)

```cue
package patterns

import "quicue.ca/vocab"

// #VMActions - VM management via myplatform CLI
#VMActions: vocab.#VMActions & {
    VM_ID: string    // Platform-specific VM identifier
    HOST:  string    // Management host/API endpoint

    status: {
        name:        "VM Status"
        description: "Check VM \(VM_ID) status"
        command:     "myplatform vm status \(VM_ID) --host \(HOST)"
        category:    "monitor"
    }
    console: {
        name:        "Console"
        description: "Open VM \(VM_ID) console"
        command:     "myplatform vm console \(VM_ID) --host \(HOST)"
        category:    "connect"
    }
    config: {
        name:        "Configuration"
        description: "Show VM \(VM_ID) configuration"
        command:     "myplatform vm config \(VM_ID) --host \(HOST)"
        category:    "info"
    }
}

// #ContainerActions - Container management
#ContainerActions: vocab.#ContainerActions & {
    CONTAINER: string
    HOST:      string

    status: {
        name:        "Container Status"
        description: "Check container \(CONTAINER) status"
        command:     "myplatform container status \(CONTAINER) --host \(HOST)"
        category:    "monitor"
    }
    console: {
        name:        "Console"
        description: "Attach to container \(CONTAINER)"
        command:     "myplatform container attach \(CONTAINER) --host \(HOST)"
        category:    "connect"
    }
    logs: {
        name:        "Logs"
        description: "View container \(CONTAINER) logs"
        command:     "myplatform container logs \(CONTAINER) --host \(HOST)"
        category:    "info"
    }
}

// #LifecycleActions - Power management
#LifecycleActions: vocab.#LifecycleActions & {
    RESOURCE_ID: string
    HOST:        string

    start: {
        name:        "Start"
        description: "Start resource \(RESOURCE_ID)"
        command:     "myplatform start \(RESOURCE_ID) --host \(HOST)"
        category:    "admin"
    }
    stop: {
        name:        "Stop"
        description: "Stop resource \(RESOURCE_ID)"
        command:     "myplatform stop \(RESOURCE_ID) --host \(HOST)"
        category:    "admin"
    }
    restart: {
        name:        "Restart"
        description: "Restart resource \(RESOURCE_ID)"
        command:     "myplatform restart \(RESOURCE_ID) --host \(HOST)"
        category:    "admin"
    }
}
```

### 4. Create Action Templates (patterns/templates.cue)

Templates provide granular building blocks for flexible composition:

```cue
package patterns

// #ActionTemplates - Building blocks for action generation
#ActionTemplates: {
    // VM actions
    vm_status: {
        VM_ID:       string
        HOST:        string
        name:        string | *"VM Status"
        description: string | *"Check VM \(VM_ID) status"
        command:     string | *"myplatform vm status \(VM_ID) --host \(HOST)"
        icon:        string | *"[status]"
        category:    string | *"monitor"
    }

    vm_console: {
        VM_ID:       string
        HOST:        string
        name:        string | *"Console"
        description: string | *"Open VM \(VM_ID) console"
        command:     string | *"myplatform vm console \(VM_ID) --host \(HOST)"
        icon:        string | *"[console]"
        category:    string | *"connect"
    }

    // Connectivity
    ping: {
        IP:          string
        name:        string | *"Ping"
        description: string | *"Test connectivity to \(IP)"
        command:     string | *"ping -c 3 \(IP)"
        icon:        string | *"[ping]"
        category:    string | *"connect"
    }

    ssh: {
        IP:          string
        USER:        string
        name:        string | *"SSH"
        description: string | *"SSH into \(IP) as \(USER)"
        command:     string | *"ssh \(USER)@\(IP)"
        icon:        string | *"[ssh]"
        category:    string | *"connect"
    }
}
```

### 5. Usage Example

Consumers import and unify with their data:

```cue
import "quicue.ca/myplatform/patterns"

// Define a VM with actions
webServer: {
    name: "web-server-01"
    vm_actions: patterns.#VMActions & {
        VM_ID: "vm-12345"
        HOST:  "api.myplatform.com"
    }
    lifecycle: patterns.#LifecycleActions & {
        RESOURCE_ID: "vm-12345"
        HOST:        "api.myplatform.com"
    }
}

// Or use templates for custom composition
_T: patterns.#ActionTemplates
customActions: {
    status: _T.vm_status & {VM_ID: "vm-12345", HOST: "api.myplatform.com"}
    ping:   _T.ping & {IP: "10.0.0.5"}
    ssh:    _T.ssh & {IP: "10.0.0.5", USER: "admin"}
}
```

## Action Categories

Use these standard categories for UI grouping:

| Category | Purpose | Examples |
|----------|---------|----------|
| `connect` | Interactive access | SSH, console, shell |
| `info` | Read-only inspection | config, inspect, list |
| `monitor` | Status/health checks | status, health, stats |
| `admin` | State-changing operations | start, stop, restart |
| `cost` | Cost tracking (enterprise) | breakdown, forecast |

## Best Practices

1. **Keep actions atomic** - One action, one command
2. **Use descriptive names** - `name` should be clear and concise
3. **Include descriptions** - Help users understand what the action does
4. **Set appropriate categories** - Enables UI grouping and filtering
5. **Provide defaults** - Use `| *` so users can override selectively
6. **Document parameters** - Comment required vs optional parameters
7. **Handle SSH consistently** - Use `ssh -t` for interactive commands

## Reference Implementations

- **Proxmox**: `quicue.ca/proxmox/patterns` - Full-featured hypervisor provider with VMs, LXC, clusters
- **Docker**: `quicue.ca/docker/patterns` - Container runtime with Compose support

## Security Note

Commands use direct string interpolation. Never pass untrusted user input as parameters. Input validation should happen at the CLI or API layer, not in CUE templates.
