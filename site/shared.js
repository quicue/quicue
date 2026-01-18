// quicue shared utilities
// Extracted for reuse across index.html, demo.html
// Future: CUE can generate/inject theming into this file

// Type colors - semantic meaning through color
// Structure mirrors quicue type categories:
//   Semantic (what it does), Implementation (how it runs), Classification (operational tier)
const typeColors = {
    // Semantic types
    'Region': '#f0883e',
    'DNSServer': '#3fb950',
    'AuthServer': '#a371f7',
    'Database': '#58a6ff',
    'CacheCluster': '#f778ba',
    'APIServer': '#79c0ff',
    'WebFrontend': '#ffa657',
    'LoadBalancer': '#ff7b72',
    'MessageQueue': '#d2a8ff',
    'Worker': '#7ee787',
    'ScheduledJob': '#a5d6ff',
    'MonitoringServer': '#ffc658',
    'LogAggregator': '#ffb86c',
    'SearchIndex': '#bd93f9',
    'ReverseProxy': '#50fa7b',
    'SourceControlManagement': '#f1fa8c',
    'GitServer': '#f1fa8c',
    'CIServer': '#8be9fd',
    'CDServer': '#50fa7b',
    'ArtifactRegistry': '#ffb86c',
    'SecretManager': '#ff79c6',
    'ConfigServer': '#bd93f9',

    // Implementation types
    'VirtualizationPlatform': '#ff79c6',
    'LXCContainer': '#8be9fd',
    'DockerContainer': '#8be9fd',
    'Container': '#8be9fd',
    'VirtualMachine': '#ff79c6',
    'BareMetalServer': '#6e7681',

    // Classification types
    'CriticalInfra': '#ff5555',
    'Tier1': '#ff5555',
    'Tier2': '#ffa657',
    'Tier3': '#7ee787',

    // Default fallback
    'default': '#6e7681'
};

// Convert types from struct-as-set {Type: true} to array ["Type"]
// Handles both quicue internal format and JSON-LD export format
function getTypes(node) {
    if (!node) return [];
    const t = node.types || node['@type'];
    if (!t) return [];
    if (Array.isArray(t)) return t;
    if (typeof t === 'object') return Object.keys(t);
    return [t];
}

// Get primary color for a node based on its types
// Checks types in order, returns first match
function getNodeColor(node) {
    const types = getTypes(node);
    for (const t of types) {
        if (typeColors[t]) return typeColors[t];
    }
    return typeColors.default;
}

// Criticality color gradient: blue (low) -> yellow -> red (high)
// Used for visualizing dependent count / impact radius
function criticalityColor(dependents, maxDependents) {
    if (maxDependents === 0) return '#58a6ff';
    const ratio = dependents / maxDependents;
    if (ratio < 0.5) {
        // Blue to yellow
        const r = Math.round(88 + (240 - 88) * (ratio * 2));
        const g = Math.round(166 + (136 - 166) * (ratio * 2));
        const b = Math.round(255 + (62 - 255) * (ratio * 2));
        return `rgb(${r},${g},${b})`;
    } else {
        // Yellow to red
        const r = Math.round(240 + (248 - 240) * ((ratio - 0.5) * 2));
        const g = Math.round(136 - 136 * ((ratio - 0.5) * 2));
        const b = Math.round(62 - 62 * ((ratio - 0.5) * 2));
        return `rgb(${r},${g},${b})`;
    }
}

// Type category classification for badge styling
function getTypeCategory(typeName) {
    const implementation = ['LXCContainer', 'DockerContainer', 'Container', 'VirtualMachine', 'BareMetalServer', 'VirtualizationPlatform'];
    const classification = ['CriticalInfra', 'Tier1', 'Tier2', 'Tier3'];

    if (implementation.includes(typeName)) return 'implementation';
    if (classification.includes(typeName)) return 'classification';
    return 'semantic';
}

// Export for ES modules (future)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { typeColors, getTypes, getNodeColor, criticalityColor, getTypeCategory };
}
