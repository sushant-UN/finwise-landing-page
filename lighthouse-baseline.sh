#!/bin/bash

# Lighthouse CI Baseline Management Script
# This script helps manage performance baselines for regression testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create baseline from current master branch
create_baseline() {
    print_status "Creating baseline from current branch..."
    
    # Ensure we're on a target branch
    current_branch=$(git branch --show-current)
    target_branches=("env1" "env2" "env3" "staging")
    
    is_target_branch=false
    for branch in "${target_branches[@]}"; do
        if [[ "$current_branch" == "$branch" ]]; then
            is_target_branch=true
            break
        fi
    done
    
    if [[ "$is_target_branch" == false ]]; then
        print_warning "Not on a target branch. Current branch: $current_branch"
        print_status "Target branches: env1, env2, env3, staging"
        read -p "Continue with current branch as baseline? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Baseline creation cancelled"
            exit 1
        fi
    fi
    
    # Create baseline directory
    mkdir -p .lighthouseci
    
    # Run Lighthouse CI and save as baseline
    print_status "Running Lighthouse CI to create baseline..."
    
    # Check if dev server is running
    if ! curl -s http://localhost:3000 > /dev/null; then
        print_error "Development server is not running at http://localhost:3000"
        print_status "Please run 'yarn dev' in another terminal first"
        exit 1
    fi
    
    # Run lighthouse and save results
    yarn lhci:collect
    
    # Copy results as baseline
    if [ -d ".lighthouseci" ]; then
        cp .lighthouseci/lhr-*.json .lighthouseci/baseline-lhr.json 2>/dev/null || true
        print_success "Baseline created successfully"
        print_status "Baseline saved to .lighthouseci/baseline-lhr.json"
    else
        print_error "No Lighthouse results found"
        exit 1
    fi
}

# Compare current performance against baseline
compare_with_baseline() {
    print_status "Comparing current performance against baseline..."
    
    if [ ! -f ".lighthouseci/baseline-lhr.json" ]; then
        print_error "No baseline found. Run 'create-baseline' first."
        exit 1
    fi
    
    # Check if dev server is running
    if ! curl -s http://localhost:3000 > /dev/null; then
        print_error "Development server is not running at http://localhost:3000"
        print_status "Please run 'yarn dev' in another terminal first"
        exit 1
    fi
    
    # Run current lighthouse
    yarn lhci:collect
    
    # Run assertions with baseline comparison
    yarn lhci:assert
    
    print_success "Baseline comparison completed"
}

# View baseline information
view_baseline() {
    if [ ! -f ".lighthouseci/baseline-lhr.json" ]; then
        print_error "No baseline found. Run 'create-baseline' first."
        exit 1
    fi
    
    print_status "Baseline Information:"
    echo "----------------------------------------"
    
    # Extract key metrics from baseline using node
    node -e "
    const fs = require('fs');
    const baseline = JSON.parse(fs.readFileSync('.lighthouseci/baseline-lhr.json', 'utf8'));
    
    console.log('URL:', baseline.finalUrl);
    console.log('Fetch Time:', new Date(baseline.fetchTime).toLocaleString());
    console.log('');
    console.log('Core Web Vitals (Baseline):');
    console.log('  LCP (Largest Contentful Paint):', Math.round(baseline.audits['largest-contentful-paint'].numericValue) + 'ms');
    console.log('  FCP (First Contentful Paint):', Math.round(baseline.audits['first-contentful-paint'].numericValue) + 'ms');
    console.log('  CLS (Cumulative Layout Shift):', baseline.audits['cumulative-layout-shift'].numericValue.toFixed(3));
    console.log('  TBT (Total Blocking Time):', Math.round(baseline.audits['total-blocking-time'].numericValue) + 'ms');
    console.log('');
    console.log('Performance Thresholds (will fail if current exceeds):');
    console.log('  LCP: ≤', Math.round(baseline.audits['largest-contentful-paint'].numericValue * 1.2) + 'ms (20% worse)');
    console.log('  FCP: ≤', Math.round(baseline.audits['first-contentful-paint'].numericValue * 1.2) + 'ms (20% worse)');
    console.log('  CLS: ≤', (baseline.audits['cumulative-layout-shift'].numericValue * 1.5).toFixed(3), '(50% worse)');
    console.log('  TBT: ≤', Math.round(baseline.audits['total-blocking-time'].numericValue * 1.3) + 'ms (30% worse)');
    "
}

# Reset baseline (delete current baseline)
reset_baseline() {
    if [ -f ".lighthouseci/baseline-lhr.json" ]; then
        print_warning "This will delete the current baseline"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm .lighthouseci/baseline-lhr.json
            print_success "Baseline reset successfully"
        else
            print_status "Reset cancelled"
        fi
    else
        print_warning "No baseline found to reset"
    fi
}

# Show help
show_help() {
    echo "Lighthouse CI Baseline Management"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  create-baseline     Create baseline from current branch"
    echo "  compare            Compare current performance vs baseline"
    echo "  view-baseline      View current baseline information"
    echo "  reset-baseline     Delete current baseline"
    echo "  help              Show this help message"
    echo ""
    echo "Workflow:"
    echo "  1. Checkout target branch (env1, env2, env3, or staging)"
    echo "  2. Run 'yarn dev' in another terminal"
    echo "  3. Run '$0 create-baseline' to establish baseline"
    echo "  4. Switch to feature branch"
    echo "  5. Run '$0 compare' to check for regressions"
    echo ""
    echo "Baseline Comparison Logic:"
    echo "  - LCP can be up to 20% slower than baseline"
    echo "  - FCP can be up to 20% slower than baseline"
    echo "  - CLS can be up to 50% worse than baseline"
    echo "  - TBT can be up to 30% slower than baseline"
    echo ""
    echo "Focus: Only Core Web Vitals are tested for performance regression"
    echo ""
}

# Main script logic
case "${1:-help}" in
    "create-baseline")
        create_baseline
        ;;
    "compare")
        compare_with_baseline
        ;;
    "view-baseline")
        view_baseline
        ;;
    "reset-baseline")
        reset_baseline
        ;;
    "help"|*)
        show_help
        ;;
esac
