# Provider Demo

Demonstrates provider-swapping: same resource definitions, different commands.

## The Idea

Resources define WHAT exists. Providers define HOW to interact with them.

```cue
"dns-server": {
    "@type": {DNSServer: true, Container: true}
    name: "dns"
    ip:   "10.0.1.10"
}
```

Same resource, different providers:

## Action Mapping: Proxmox vs Docker

### Container Actions

| Action | Proxmox LXC | Docker |
|--------|-------------|--------|
| status | `pct status 100` | `docker inspect -f '{{.State.Status}}' dns` |
| console | `pct enter 100` | `docker exec -it dns /bin/sh` |
| logs | `pct exec 100 -- journalctl -n 100` | `docker logs --tail 100 dns` |
| start | `pct start 100` | `docker start dns` |
| stop | `pct stop 100` | `docker stop dns` |
| restart | `pct restart 100` | `docker restart dns` |

### VM Actions (Proxmox only)

| Action | Proxmox VM |
|--------|------------|
| status | `qm status 100` |
| console | `qm terminal 100` |
| config | `qm config 100` |
| start | `qm start 100` |
| stop | `qm stop 100` |
| snapshot | `qm snapshot 100 snap1` |

### Compose Actions (Docker only)

| Action | Docker Compose |
|--------|----------------|
| up | `docker compose -p PROJECT -f DIR/docker-compose.yml up -d` |
| down | `docker compose -p PROJECT -f DIR/docker-compose.yml down` |
| ps | `docker compose -p PROJECT ps` |
| logs | `docker compose -p PROJECT logs --tail 100` |

### Host/Hypervisor Actions

| Action | Proxmox | Docker |
|--------|---------|--------|
| list containers | `pvesh get /nodes/NODE/lxc` | `docker ps -a` |
| list VMs | `pvesh get /nodes/NODE/qemu` | - |
| system info | `pvesh get /nodes/NODE/status` | `docker info` |
| disk usage | - | `docker system df` |
| prune | - | `docker system prune -f` |

### Connectivity (Both)

| Action | Command |
|--------|---------|
| ping | `ping -c 3 IP` |
| ssh | `ssh USER@IP` |

## Provider Repos

- [quicue-proxmox](https://github.com/quicue/quicue-proxmox) - Full Proxmox implementation
- [quicue-docker](https://github.com/quicue/quicue-docker) - Full Docker implementation

## Run

```bash
./quicue eval provider-demo
```
