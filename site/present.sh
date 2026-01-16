#!/bin/bash
# Terminal presentation for quicue
# Run: ./present.sh (press Enter to advance)

BOLD='\033[1m'
DIM='\033[2m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
RESET='\033[0m'
CLEAR='\033[2J\033[H'

wait_key() {
    read -s -n 1
}

slide() {
    echo -e "${CLEAR}"
    echo ""
}

# ============================================================================
slide
cat << 'EOF'

                                    ██████╗ ██╗   ██╗██╗ ██████╗██╗   ██╗███████╗
                                   ██╔═══██╗██║   ██║██║██╔════╝██║   ██║██╔════╝
                                   ██║   ██║██║   ██║██║██║     ██║   ██║█████╗
                                   ██║▄▄ ██║██║   ██║██║██║     ██║   ██║██╔══╝
                                   ╚██████╔╝╚██████╔╝██║╚██████╗╚██████╔╝███████╗
                                    ╚══▀▀═╝  ╚═════╝ ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝

EOF
echo -e "                              ${DIM}Infrastructure Dependency Graphs${RESET}"
echo ""
echo ""
echo -e "                    ${DIM}Typed resources. Computed patterns. Pre-CAB validation.${RESET}"
echo ""
echo ""
echo -e "                                        ${DIM}[Press Enter]${RESET}"
wait_key

# ============================================================================
slide
echo -e "${RED}${BOLD}  THE PROBLEM${RESET}"
echo ""
echo -e "  ${DIM}\"We updated the cache config...\"${RESET}"
echo ""
wait_key
echo -e "  ${RED}\"...and 6 services stopped authenticating.\"${RESET}"
echo ""
wait_key
echo ""
echo -e "  ${DIM}------------------------------------------${RESET}"
echo ""
echo -e "  ${YELLOW}->  Dependency knowledge lives in people's heads${RESET}"
echo -e "  ${YELLOW}->  Impact analysis is manual and incomplete${RESET}"
echo -e "  ${YELLOW}->  CAB reviews lack systematic tooling${RESET}"
echo ""
wait_key

# ============================================================================
slide
echo -e "${CYAN}${BOLD}  REAL IMPACT${RESET}"
echo ""
echo ""
echo -e "        ${BOLD}${RED}16${RESET}                    ${BOLD}${YELLOW}87%${RESET}                    ${BOLD}${RED}0${RESET}"
echo -e "   ${DIM}services affected${RESET}       ${DIM}of graph depends${RESET}       ${DIM}redundant auth${RESET}"
echo -e "   ${DIM}by single DNS${RESET}          ${DIM}on one hypervisor${RESET}        ${DIM}servers (SPOF)${RESET}"
echo ""
echo ""
echo -e "  ${DIM}------------------------------------------${RESET}"
echo ""
echo -e "  ${WHITE}All of this is computable from the dependency graph.${RESET}"
echo ""
wait_key

# ============================================================================
slide
echo -e "${GREEN}${BOLD}  WHAT QUICUE DOES${RESET}"
echo ""
echo -e "  ${DIM}Typed dependency graphs with ${YELLOW}computable patterns${RESET}"
echo ""
echo -e "  ${BLUE}\"dns-primary\"${RESET}: {"
echo -e "      ${MAGENTA}\"@type\"${RESET}: { ${GREEN}DNSServer${RESET}: true, ${GREEN}CriticalInfra${RESET}: true },"
echo -e "      ${MAGENTA}depends_on${RESET}: { ${CYAN}\"pve-node\"${RESET}: true }"
echo -e "  }"
echo ""
echo -e "  ${BLUE}\"api-server\"${RESET}: {"
echo -e "      ${MAGENTA}\"@type\"${RESET}: { ${GREEN}APIServer${RESET}: true },"
echo -e "      ${MAGENTA}depends_on${RESET}: { ${CYAN}\"dns\"${RESET}: true, ${CYAN}\"db\"${RESET}: true, ${CYAN}\"cache\"${RESET}: true }"
echo -e "  }"
echo ""
wait_key
echo -e "  ${DIM}Computed:${RESET} ${BLUE}ancestors${RESET} ${BLUE}dependents${RESET} ${BLUE}topology${RESET} ${RED}SPOF${RESET} ${YELLOW}coupling${RESET}"
echo ""
wait_key

# ============================================================================
slide
echo -e "${MAGENTA}${BOLD}  THREE-LAYER ARCHITECTURE${RESET}"
echo ""
echo -e "  ${DIM}CUE Unification: Schema + Template + Values = Commands${RESET}"
echo ""
echo -e "  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐"
echo -e "  │ ${MAGENTA}INTERFACE${RESET}       │    │ ${BLUE}PROVIDER${RESET}        │    │ ${GREEN}INSTANCE${RESET}        │"
echo -e "  │                 │    │                 │    │                 │"
echo -e "  │ ${DIM}#Resource${RESET}       │ -> │ ${DIM}#ProxmoxLXC${RESET}     │ -> │ ${DIM}host: pve-1${RESET}     │"
echo -e "  │ ${DIM}#Action${RESET}         │    │ ${DIM}#Docker${RESET}         │    │ ${DIM}container: 100${RESET}  │"
echo -e "  │ ${DIM}#InfraGraph${RESET}     │    │ ${DIM}#Kubernetes${RESET}     │    │ ${DIM}ip: 10.0.1.10${RESET}   │"
echo -e "  │                 │    │                 │    │                 │"
echo -e "  │ ${MAGENTA}Schema${RESET}          │    │ ${BLUE}Templates${RESET}       │    │ ${GREEN}Values${RESET}          │"
echo -e "  └─────────────────┘    └─────────────────┘    └─────────────────┘"
echo ""
wait_key
echo -e "  ${DIM}Result:${RESET} ${WHITE}ssh -t pve-1 'pct enter 100'${RESET}"
echo ""
wait_key

# ============================================================================
slide
echo -e "${CYAN}${BOLD}  IMPACT ANALYSIS${RESET}"
echo ""
echo -e "  ${DIM}\"What breaks if ${RED}auth${DIM} goes down?\"${RESET}"
echo ""
echo -e "  ┌──────────────────────────────────────────────────────────┐"
echo -e "  │ ${BLUE}ImpactQuery${RESET} { Target: ${CYAN}\"auth\"${RESET} }                           │"
echo -e "  ├──────────────────────────────────────────────────────────┤"
echo -e "  │                                                          │"
echo -e "  │  ${RED}affected${RESET}: [                                           │"
echo -e "  │      \"lb-us\", \"lb-eu\", \"mq\", \"db-primary\",              │"
echo -e "  │      \"api-us\", \"api-eu\", \"web-us\", \"web-eu\",            │"
echo -e "  │      \"worker-ingest\", \"worker-notify\",                  │"
echo -e "  │      \"search\", \"logging\", \"monitoring\",                 │"
echo -e "  │      \"job-cleanup\", \"job-report\", \"db-replica\"          │"
echo -e "  │  ]                                                       │"
echo -e "  │                                                          │"
echo -e "  │  ${YELLOW}count${RESET}: ${BOLD}16${RESET}                                               │"
echo -e "  │                                                          │"
echo -e "  └──────────────────────────────────────────────────────────┘"
echo ""
wait_key

# ============================================================================
slide
echo -e "${RED}${BOLD}  SPOF DETECTION${RESET}"
echo ""
echo -e "  ${DIM}Automatically identifies single points of failure${RESET}"
echo ""
echo -e "  ┌────────────────────────────┐   ┌────────────────────────────┐"
echo -e "  │ ${RED}! dns-primary${RESET}              │   │ ${GREEN}+ dns-primary${RESET}              │"
echo -e "  │                            │   │ ${GREEN}+ dns-secondary${RESET}            │"
echo -e "  │ Dependents: ${BOLD}3${RESET}              │   │                            │"
echo -e "  │ Layer: ${BOLD}1${RESET}                   │   │ Same type at layer 1       │"
echo -e "  │ Peers at layer: ${RED}0${RESET}          │   │ Automatic failover         │"
echo -e "  │                            │   │                            │"
echo -e "  │ ${RED}No redundancy${RESET}              │   │ ${GREEN}Redundancy achieved${RESET}        │"
echo -e "  └────────────────────────────┘   └────────────────────────────┘"
echo ""
wait_key

# ============================================================================
slide
echo -e "${YELLOW}${BOLD}  COUPLING ANALYSIS${RESET}"
echo ""
echo -e "  ${DIM}Shared dependency hotspots (>30% of graph)${RESET}"
echo ""
echo -e "  ┌──────────────┬────────────┬─────────────────────────┬────────┐"
echo -e "  │ Resource     │ Dependents │ % of Graph              │ Risk   │"
echo -e "  ├──────────────┼────────────┼─────────────────────────┼────────┤"
echo -e "  │ ${CYAN}pve-node${RESET}     │ 7          │ ${RED}████████████████████${RESET}░░░ │ ${RED}87.5%${RESET}  │"
echo -e "  │ ${CYAN}dns-us${RESET}       │ 5          │ ${YELLOW}███████████████${RESET}░░░░░░░░ │ ${YELLOW}62.5%${RESET}  │"
echo -e "  │ ${CYAN}db${RESET}           │ 3          │ ${BLUE}█████████${RESET}░░░░░░░░░░░░░░ │ ${BLUE}37.5%${RESET}  │"
echo -e "  └──────────────┴────────────┴─────────────────────────┴────────┘"
echo ""
wait_key

# ============================================================================
slide
echo -e "${BLUE}${BOLD}  WHAT-IF SIMULATION${RESET}"
echo ""
echo -e "  ${DIM}Simulate before you execute${RESET}"
echo ""
echo -e "  ${YELLOW}Simulate Failure:${RESET}                 ${GREEN}Simulate Addition:${RESET}"
echo ""
echo -e "  ${DIM}\$ qcnu diagram --down dns,cache${RESET}     ${DIM}+ cache-replica${RESET}"
echo ""
echo -e "  ${RED}DOWN${RESET}:     2 resources              Types: [CacheCluster]"
echo -e "  ${YELLOW}DEGRADED${RESET}: 5 resources              Deps:  [dns-primary]"
echo -e "  ${GREEN}HEALTHY${RESET}:  1 resource"
echo -e "                                    Validation:"
echo -e "                                      ${GREEN}+${RESET} Layer 2 (correct)"
echo -e "                                      ${YELLOW}~${RESET} Will be SPOF (no peer)"
echo -e "                                      ${GREEN}+${RESET} 1 transitive dep"
echo ""
wait_key

# ============================================================================
slide
echo -e "${GREEN}${BOLD}  WEB EXPLORER${RESET}"
echo ""
echo -e "  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐"
echo -e "  │ ${CYAN}/ Search${RESET}        │ │ ${CYAN}Layouts${RESET}         │ │ ${CYAN}+ Add Resource${RESET}  │"
echo -e "  │                 │ │                 │ │                 │"
echo -e "  │ Fuzzy search    │ │ Hierarchical    │ │ Click nodes to  │"
echo -e "  │ by name or type │ │ Force-directed  │ │ add as deps     │"
echo -e "  │                 │ │ Circular, Grid  │ │ then validate   │"
echo -e "  └─────────────────┘ └─────────────────┘ └─────────────────┘"
echo ""
echo -e "  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐"
echo -e "  │ ${CYAN}Path Finder${RESET}     │ │ ${CYAN}Export${RESET}          │ │ ${CYAN}What-If${RESET}         │"
echo -e "  │                 │ │                 │ │                 │"
echo -e "  │ Find path from  │ │ PNG export      │ │ Simulate fails  │"
echo -e "  │ A to B          │ │ Shareable URLs  │ │ See cascade     │"
echo -e "  └─────────────────┘ └─────────────────┘ └─────────────────┘"
echo ""
wait_key

# ============================================================================
slide
echo -e "${MAGENTA}${BOLD}  CLICK-TO-ADD WORKFLOW${RESET}"
echo ""
echo ""
echo -e "     ${BLUE}1.${RESET} Click + Add"
echo -e "          │"
echo -e "          ▼"
echo -e "     ${BLUE}2.${RESET} Click nodes in graph ${DIM}(green = selected)${RESET}"
echo -e "          │"
echo -e "          ▼"
echo -e "     ${YELLOW}3.${RESET} Validate ${DIM}(warns about SPOFs, bottlenecks)${RESET}"
echo -e "          │"
echo -e "          ▼"
echo -e "     ${GREEN}4.${RESET} Add to graph"
echo ""
echo ""
echo -e "  Visual feedback:"
echo -e "     ${BLUE}┄ ┄ ┄${RESET} dashed blue = clickable candidate"
echo -e "     ${GREEN}━━━━━${RESET} solid green  = selected as dependency"
echo ""
wait_key

# ============================================================================
slide
echo -e "${WHITE}${BOLD}  VALUE PROPOSITION${RESET}"
echo ""
echo -e "  ┌──────────────────────────────────────────────────────────┐"
echo -e "  │ ${BLUE}For Engineers${RESET}                                            │"
echo -e "  │   -> See dependencies before touching                   │"
echo -e "  │   -> Validate changes pre-CAB                           │"
echo -e "  │   -> Single source of truth for commands                │"
echo -e "  ├──────────────────────────────────────────────────────────┤"
echo -e "  │ ${GREEN}For Ops${RESET}                                                  │"
echo -e "  │   -> Computed startup/shutdown order                    │"
echo -e "  │   -> Automatic SPOF detection                           │"
echo -e "  │   -> One-click impact analysis                          │"
echo -e "  ├──────────────────────────────────────────────────────────┤"
echo -e "  │ ${YELLOW}For Management${RESET}                                           │"
echo -e "  │   -> Fewer outages from dependency blindness            │"
echo -e "  │   -> Faster CAB approval with systematic analysis       │"
echo -e "  │   -> Documentation that stays accurate                  │"
echo -e "  └──────────────────────────────────────────────────────────┘"
echo ""
wait_key

# ============================================================================
slide
echo -e "${GREEN}${BOLD}  DEMO${RESET}"
echo ""
echo -e "  ${DIM}quicue/site/index.html${RESET}"
echo ""
echo -e "  ${BLUE}1.${RESET} Load ${CYAN}multi-region${RESET} example (22 nodes)"
echo ""
echo -e "  ${BLUE}2.${RESET} Press ${CYAN}/${RESET}, search for ${CYAN}auth${RESET}"
echo ""
echo -e "  ${BLUE}3.${RESET} Enable ${YELLOW}Impact Mode${RESET}, click ${CYAN}auth${RESET}"
echo -e "     ${DIM}-> 16 services turn red${RESET}"
echo ""
echo -e "  ${BLUE}4.${RESET} Check ${YELLOW}Analysis${RESET} tab for SPOFs"
echo ""
echo -e "  ${BLUE}5.${RESET} Click ${GREEN}+ Add${RESET}, add ${CYAN}auth-replica${RESET}"
echo -e "     ${DIM}-> Click region-eu as dependency${RESET}"
echo ""
echo -e "  ${BLUE}6.${RESET} Validate: ${GREEN}\"No longer a SPOF\"${RESET}"
echo ""
wait_key

# ============================================================================
slide
cat << 'EOF'

                                   ██████╗ ██╗   ██╗███████╗███████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
                                  ██╔═══██╗██║   ██║██╔════╝██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
                                  ██║   ██║██║   ██║█████╗  ███████╗   ██║   ██║██║   ██║██╔██╗ ██║███████╗
                                  ██║▄▄ ██║██║   ██║██╔══╝  ╚════██║   ██║   ██║██║   ██║██║╚██╗██║╚════██║
                                  ╚██████╔╝╚██████╔╝███████╗███████║   ██║   ██║╚██████╔╝██║ ╚████║███████║
                                   ╚══▀▀═╝  ╚═════╝ ╚══════╝╚══════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

EOF
echo ""
echo -e "                                 ${BLUE}github.com/quicue/quicue${RESET}"
echo ""
echo -e "                    ${DIM}patterns/graph.cue${RESET}  -  Core patterns"
echo -e "                    ${DIM}site/index.html${RESET}     -  Web explorer"
echo -e "                    ${DIM}quicue-nu/${RESET}          -  CLI tools"
echo ""
echo ""
