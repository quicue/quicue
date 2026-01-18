#!/bin/bash
set -euo pipefail

# Files/dirs to exclude from public push
EXCLUDE_PATTERNS=("CLAUDE.md" ".claude" ".cursorrules" ".cursor")

# Patterns to search for contamination (with word boundaries where needed)
# Using \b for word boundary in grep -E
CONTAMINATION_PATTERNS=("\\bclaude\\b" "\\banthropic\\b" "\\bmcp\\b" "\\bllm\\b" "\\bcopilot\\b" "\\bgpt\\b" "\\bopenai\\b")

REPOS_DIR="${1:-$(dirname "$(pwd)")}"
INTERNAL_REMOTE_PATTERN="internal.example.com"
PUBLIC_REMOTE="gitlab-pub"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[SKIP]${NC} $1"; }

check_contamination() {
    local repo_dir="$1"
    local contaminated_files=""
    
    for pattern in "${CONTAMINATION_PATTERNS[@]}"; do
        matches=$(git -C "$repo_dir" grep -ilE "$pattern" 2>/dev/null | \
            grep -v -E "(CLAUDE\.md|\.claude|\.cursorrules|\.cursor|^\.gitignore$|\.gitignore$)" || true)
        if [ -n "$matches" ]; then
            contaminated_files+="$matches"$'\n'
        fi
    done
    
    echo "$contaminated_files" | sort -u | grep -v '^$' || true
}

get_internal_remote() {
    local repo_dir="$1"
    local ssh_remote=$(git -C "$repo_dir" remote -v 2>/dev/null | \
        grep "$INTERNAL_REMOTE_PATTERN" | grep "git@" | head -1 | awk '{print $1}' || true)
    if [ -n "$ssh_remote" ]; then
        echo "$ssh_remote"
    else
        git -C "$repo_dir" remote -v 2>/dev/null | \
            grep "$INTERNAL_REMOTE_PATTERN" | head -1 | awk '{print $1}' || true
    fi
}

sync_repo() {
    local repo_dir="$1"
    local repo_name=$(basename "$repo_dir")
    
    echo ""
    echo "=== $repo_name ==="
    
    if [ ! -d "$repo_dir/.git" ]; then
        log_warn "Not a git repo, skipping"
        return
    fi
    
    local branch=$(git -C "$repo_dir" branch --show-current 2>/dev/null || echo "main")
    
    local internal_remote=$(get_internal_remote "$repo_dir")
    if [ -n "$internal_remote" ]; then
        echo "Pushing to $internal_remote..."
        if git -C "$repo_dir" push "$internal_remote" "$branch" 2>&1; then
            log_ok "Pushed to internal"
        else
            log_warn "Push to internal failed (may be up to date)"
        fi
    else
        log_warn "No internal remote found"
    fi
    
    local has_public=$(git -C "$repo_dir" remote -v 2>/dev/null | grep "$PUBLIC_REMOTE" || true)
    if [ -z "$has_public" ]; then
        log_warn "No $PUBLIC_REMOTE remote, skipping public push"
        return
    fi
    
    local contaminated=$(check_contamination "$repo_dir")
    if [ -n "$contaminated" ]; then
        log_err "Contaminated files found:"
        echo "$contaminated" | sed 's/^/    /'
        return
    fi
    
    echo "Creating clean push to $PUBLIC_REMOTE..."
    
    local stash_needed=false
    if ! git -C "$repo_dir" diff --quiet 2>/dev/null; then
        stash_needed=true
        git -C "$repo_dir" stash push -q
    fi
    
    local temp_branch="__public_sync_$$"
    git -C "$repo_dir" checkout -b "$temp_branch" -q
    
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        git -C "$repo_dir" rm -rf --ignore-unmatch "$pattern" -q 2>/dev/null || true
    done
    
    if ! git -C "$repo_dir" diff --cached --quiet 2>/dev/null; then
        git -C "$repo_dir" commit -q -m "Remove LLM configuration files for public release"
    fi
    
    if git -C "$repo_dir" push -f "$PUBLIC_REMOTE" "$temp_branch:$branch" 2>&1; then
        log_ok "Pushed to public (clean)"
    else
        log_err "Push to public failed"
    fi
    
    git -C "$repo_dir" checkout "$branch" -q
    git -C "$repo_dir" branch -D "$temp_branch" -q
    
    if [ "$stash_needed" = true ]; then
        git -C "$repo_dir" stash pop -q
    fi
}

echo "Syncing quicue repos from: $REPOS_DIR"
echo "Internal pattern: $INTERNAL_REMOTE_PATTERN"
echo "Public remote: $PUBLIC_REMOTE"

for repo in "$REPOS_DIR"/quicue*/; do
    if [ -d "$repo" ]; then
        sync_repo "$repo"
    fi
done

echo ""
echo "Done."
