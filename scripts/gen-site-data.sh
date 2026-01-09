#!/bin/bash
# Generate visualization data for site/data/
# Run after modifying examples

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

mkdir -p site/data

examples=(
    "graph-patterns"
    "multi-region"
    "3-layer"
    "jsonld-export"
    "operational"
    "provider-demo"
    "type-composition"
)

for example in "${examples[@]}"; do
    echo "Generating: $example"
    cue export "./examples/$example/" -e vizData --out json > "site/data/$example.json"
done

echo ""
echo "Generated $(ls site/data/*.json | wc -l) files in site/data/"
