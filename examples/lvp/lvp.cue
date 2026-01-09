// Infrastructure dependencies in CUE
//
// Run: cue eval .

package lvp

import "list"

// A small infrastructure
resources: {
	hypervisor: {}
	dns: {depends_on: {hypervisor: true}}
	database: {depends_on: {dns: true}}
	cache: {depends_on: {dns: true}}
	api: {depends_on: {database: true, cache: true}}
	web: {depends_on: {api: true}}
}

// Enrich each resource with what it transitively depends on
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

// ═══════════════════════════════════════════════════════════════
// What you can now ask:
// ═══════════════════════════════════════════════════════════════

// Q: What does 'web' actually depend on? (all the way down)
web_depends_on: [for a, _ in infra.web.ancestors {a}]
// → ["api", "database", "cache", "dns", "hypervisor"]

// Q: What breaks if 'dns' goes down?
if_dns_fails: [for name, r in infra if r.ancestors.dns != _|_ {name}]
// → ["database", "cache", "api", "web"]

// Q: What's safe if 'dns' goes down?
still_safe: [for name, r in infra if r.ancestors.dns == _|_ {name}]
// → ["hypervisor", "dns"]

// Q: How critical is each resource? (how many things depend on it)
criticality: {
	for name, _ in resources {
		(name): len([for n, r in infra if r.ancestors[name] != _|_ {n}])
	}
}
// → hypervisor: 5, dns: 4, database: 2, cache: 2, api: 1, web: 0

// Q: Startup order? (things with no dependencies first)
_byDepth: {for name, r in infra {(name): len(r.ancestors)}}
startup: list.Sort([for n, _ in resources {n}], {x: string, y: string, less: _byDepth[x] < _byDepth[y]})
// → ["hypervisor", "dns", "database", "cache", "api", "web"]

shutdown: list.Reverse(startup)

// Standard output for quicue eval
output: {
	web_depends_on: [for a, _ in infra.web.ancestors {a}]
	if_dns_fails:   [for name, r in infra if r.ancestors.dns != _|_ {name}]
	still_safe:     [for name, r in infra if r.ancestors.dns == _|_ {name}]
	criticality: {
		for name, _ in resources {
			(name): len([for n, r in infra if r.ancestors[name] != _|_ {n}])
		}
	}
	startup:  list.Sort([for n, _ in resources {n}], {x: string, y: string, less: _byDepth[x] < _byDepth[y]})
	shutdown: list.Reverse(output.startup)
}
