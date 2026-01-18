# quicue Site

Interactive graph explorer for quicue infrastructure graphs.

**Live:** https://quicue.github.io/quicue/

## Files

| File | Purpose |
|------|---------|
| `index.html` | Full explorer with Cytoscape graph, D3 visualizations, API queries |
| `demo.html` | Guided demo showing CUE query patterns step-by-step |
| `presentation.html` | Slide deck for presentations |
| `shared.js` | Shared utilities: type colors, helpers |
| `shared.css` | Shared styles: CSS variables, base components |
| `data/*.json` | Pre-computed graph data from examples |

## Shared Utilities

### shared.js

```javascript
// Type colors - maps quicue types to display colors
typeColors['DNSServer']  // '#3fb950'
typeColors['Database']   // '#58a6ff'
typeColors['default']    // '#6e7681'

// Get types from a node (handles struct-as-set and array formats)
getTypes(node)           // ['DNSServer', 'LXCContainer']

// Get primary color for a node
getNodeColor(node)       // '#3fb950'

// Get criticality gradient color (blue -> yellow -> red)
criticalityColor(dependents, maxDependents)  // 'rgb(248,81,73)'

// Get type category for badge styling
getTypeCategory('DNSServer')     // 'semantic'
getTypeCategory('LXCContainer')  // 'implementation'
getTypeCategory('CriticalInfra') // 'classification'
```

### shared.css

CSS variables for theming:

```css
/* Override in your page to customize */
:root {
    /* Backgrounds */
    --bg-primary: #0d1117;
    --bg-secondary: #161b22;
    --bg-tertiary: #21262d;

    /* Text */
    --text-primary: #c9d1d9;
    --text-secondary: #8b949e;

    /* Accents */
    --accent-blue: #58a6ff;
    --accent-green: #3fb950;
    --accent-red: #f85149;

    /* Type categories (for badges) */
    --type-semantic: #58a6ff;
    --type-implementation: #a371f7;
    --type-classification: #f0883e;
}
```

## Usage Examples

### Minimal Page with Graph Data

```html
<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="shared.css">
    <script src="shared.js"></script>
</head>
<body>
    <div id="output"></div>
    <script>
        fetch('data/graph-patterns.json')
            .then(r => r.json())
            .then(data => {
                const container = document.getElementById('output');
                data.nodes.forEach(node => {
                    const div = document.createElement('div');
                    div.style.borderLeft = '4px solid ' + getNodeColor(node);
                    div.style.padding = '0.5rem';
                    div.style.margin = '0.5rem 0';

                    const strong = document.createElement('strong');
                    strong.textContent = node.id;
                    div.appendChild(strong);

                    const span = document.createTextNode(' - ' + getTypes(node).join(', '));
                    div.appendChild(span);

                    container.appendChild(div);
                });
            });
    </script>
</body>
</html>
```

### Custom Theme (Light Mode)

```html
<style>
:root {
    --bg-primary: #ffffff;
    --bg-secondary: #f6f8fa;
    --bg-tertiary: #f0f0f0;
    --text-primary: #24292f;
    --text-secondary: #57606a;
    --border-default: #d0d7de;
}
</style>
```

### Type Badge Styling

```html
<span class="type-badge semantic">DNSServer</span>
<span class="type-badge implementation">LXCContainer</span>
<span class="type-badge classification">CriticalInfra</span>
```

### Criticality Heatmap

```javascript
const maxDeps = Math.max(...nodes.map(n => n.dependents));
nodes.forEach(node => {
    const color = criticalityColor(node.dependents, maxDeps);
    // blue (0 deps) -> yellow (mid) -> red (max deps)
    element.style.backgroundColor = color;
});
```

## Live Examples

### URL Parameters

Load external data:
```
index.html?source=https://example.com/my-graph.json
```

Load specific example:
```
index.html?example=multi-region
```

### Available Examples

| Example | Nodes | Description |
|---------|-------|-------------|
| `graph-patterns` | 5 | Basic dependency patterns |
| `operational` | 8 | Web stack (web, api, db, cache) |
| `incident-cascade` | 9 | Cascading failure from core switch |
| `cicd-pipeline` | 9 | CI/CD pipeline stages |
| `microservices-mesh` | 12 | Service mesh with gateway |
| `multi-region` | 22 | Multi-region with failover |
| `provider-demo` | 5 | Proxmox/Docker provider actions |
| `3-layer` | 3 | Interface/provider composition |

### D3 Visualizations

The D3 tab in index.html provides 8 visualization types:

| View | Purpose |
|------|---------|
| Sankey | Dependency flow from roots to leaves |
| Chord | Type-to-type relationships |
| Matrix | Adjacency matrix of all dependencies |
| Treemap | Resources grouped by type |
| Sunburst | Hierarchical depth with drill-down |
| Force | Force-directed layout with dragging |
| Bundle | Hierarchical edge bundling by type |
| Gantt | Deployment order timeline |

### API Queries

The API tab provides interactive query endpoints:

| Endpoint | Description |
|----------|-------------|
| IMPACT | What breaks if X fails? |
| CHAIN | Dependency path to roots |
| IMMEDIATE | Direct dependents only |
| CRITICALITY | Resources ranked by dependent count |
| TOPOLOGY | Resources grouped by layer |
| PATHFINDER | Shortest path between two nodes |
| DIFF | Compare two graph states |

## Data Format

Graph JSON structure:

```json
{
    "nodes": [
        {
            "id": "dns-primary",
            "types": {"DNSServer": true, "LXCContainer": true},
            "depth": 0,
            "dependents": 3,
            "ancestors": []
        }
    ],
    "edges": [
        {"source": "web-frontend", "target": "dns-primary"}
    ],
    "roots": ["dns-primary"],
    "leaves": ["web-frontend"],
    "topology": {
        "0": ["dns-primary"],
        "1": ["api-server"],
        "2": ["web-frontend"]
    },
    "metrics": {
        "nodeCount": 5,
        "edgeCount": 4,
        "maxDepth": 2
    }
}
```

## CUE Theming (Future)

The CSS variables are designed for CUE-driven theming:

```cue
// theme.cue
theme: {
    dark: {
        bgPrimary: "#0d1117"
        accentBlue: "#58a6ff"
    }
    light: {
        bgPrimary: "#ffffff"
        accentBlue: "#0969da"
    }
}

// Generate CSS
_css: """
:root {
    --bg-primary: \(theme.dark.bgPrimary);
    --accent-blue: \(theme.dark.accentBlue);
}
"""
```

Inject via:
```bash
cue export theme.cue -e _css --out text > theme-override.css
```

## Development

Generate data files from CUE examples:
```bash
for ex in graph-patterns operational multi-region; do
    cue export ./examples/$ex/... -e output --out json > site/data/$ex.json
done
```

Serve locally:
```bash
python -m http.server 8000 -d site/
# Open http://localhost:8000
```
