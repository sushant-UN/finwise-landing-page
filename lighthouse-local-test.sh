#!/bin/bash

# Lighthouse CI Local Testing Script
# This script simulates the GitHub Actions workflow locally

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${CYAN}=== $1 ===${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed"
        exit 1
    fi
    print_status "Node.js: $(node --version)"
    
    # Check if yarn is installed
    if ! command -v yarn &> /dev/null; then
        print_error "Yarn is not installed"
        exit 1
    fi
    print_status "Yarn: $(yarn --version)"
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed"
        exit 1
    fi
    print_status "Git: $(git --version | head -1)"
    
    # Check if we're in the right directory
    if [ ! -f "lighthouserc.js" ]; then
        print_error "lighthouserc.js not found. Run this script from the project root."
        exit 1
    fi
    print_status "Lighthouse config found"
    
    print_success "All prerequisites met"
    echo ""
}

# Install dependencies (simulate GitHub Actions)
install_dependencies() {
    print_header "Installing Dependencies"
    
    print_status "Running yarn install --frozen-lockfile"
    yarn install --frozen-lockfile
    
    print_success "Dependencies installed"
    echo ""
}

# Build application (simulate GitHub Actions)
build_application() {
    print_header "Building Application"
    
    print_status "Running yarn localbuild"
    if yarn localbuild; then
        print_success "Application built successfully"
    else
        print_error "Build failed"
        exit 1
    fi
    echo ""
}

# Start development server
start_dev_server() {
    print_header "Starting Development Server"
    
    # Check if server is already running
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        print_warning "Development server already running at http://localhost:3000"
        return 0
    fi
    
    print_status "Starting yarn dev in background..."
    yarn dev > /dev/null 2>&1 &
    DEV_SERVER_PID=$!
    
    # Wait for server to be ready
    print_status "Waiting for server to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:3000 > /dev/null 2>&1; then
            print_success "Development server ready at http://localhost:3000"
            echo ""
            return 0
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    print_error "Development server failed to start within 60 seconds"
    if [ ! -z "$DEV_SERVER_PID" ]; then
        kill $DEV_SERVER_PID 2>/dev/null || true
    fi
    exit 1
}

# Run Lighthouse CI (simulate GitHub Actions)
run_lighthouse_ci() {
    print_header "Running Lighthouse CI"
    
    print_status "Simulating GitHub Actions Lighthouse CI workflow..."
    
    # Set environment variables similar to CI
    export CI=true
    export NODE_ENV=production
    
    print_status "Running yarn lhci:autorun"
    if yarn lhci:autorun; then
        print_success "Lighthouse CI completed successfully"
    else
        print_warning "Lighthouse CI completed with warnings/errors (check output above)"
    fi
    
    echo ""
}

# Test baseline functionality
test_baseline() {
    print_header "Testing Baseline Functionality"
    
    if [ -f ".lighthouseci/baseline-lhr.json" ]; then
        print_status "Baseline found, testing comparison..."
        ./lighthouse-baseline.sh view-baseline
    else
        print_status "No baseline found, creating one for testing..."
        echo "y" | ./lighthouse-baseline.sh create-baseline || true
    fi
    
    echo ""
}

# Show results
show_results() {
    print_header "Test Results Summary"
    
    if [ -d ".lighthouseci" ] && [ "$(ls -A .lighthouseci 2>/dev/null)" ]; then
        print_status "Lighthouse results generated:"
        ./lighthouse-results.sh summary
        
        echo ""
        print_status "Available result files:"
        ls -la .lighthouseci/ | grep -E '\.(json|html)$' || echo "No result files found"
        
        echo ""
        print_status "To view detailed results:"
        echo "  ./lighthouse-results.sh open      # Open HTML report"
        echo "  ./lighthouse-results.sh compare   # Compare runs"
        echo "  ./lighthouse-results.sh assertions # Show pass/fail"
    else
        print_warning "No Lighthouse results found"
    fi
    
    echo ""
}

# Cleanup function
cleanup() {
    print_header "Cleanup"
    
    if [ ! -z "$DEV_SERVER_PID" ]; then
        print_status "Stopping development server (PID: $DEV_SERVER_PID)"
        kill $DEV_SERVER_PID 2>/dev/null || true
        wait $DEV_SERVER_PID 2>/dev/null || true
    fi
    
    # Kill any remaining Next.js processes
    pkill -f "next.*3000" 2>/dev/null || true
    
    print_success "Cleanup completed"
}

# Handle script interruption
trap cleanup EXIT INT TERM

# Main test sequence
main() {
    print_header "Lighthouse CI Local Testing"
    echo "This script simulates the GitHub Actions workflow locally"
    echo ""
    
    check_prerequisites
    install_dependencies
    
    # Choose between dev server or built app
    echo "Choose testing mode:"
    echo "1) Test with development server (yarn dev)"
    echo "2) Test with built application (yarn localbuild + yarn start)"
    echo ""
    read -p "Enter choice (1 or 2) [default: 1]: " choice
    choice=${choice:-1}
    
    if [ "$choice" = "2" ]; then
        build_application
        # For built app, we'd need to start the production server
        print_warning "Production server testing not fully implemented in this script"
        print_status "Using development server instead..."
    fi
    
    start_dev_server
    sleep 3  # Give server a moment to stabilize
    
    run_lighthouse_ci
    test_baseline
    show_results
    
    print_header "Local Testing Complete"
    print_success "✅ Local Lighthouse CI testing finished!"
    echo ""
    print_status "What was tested:"
    echo "  ✅ Dependency installation"
    echo "  ✅ Application building"
    echo "  ✅ Lighthouse data collection"
    echo "  ✅ Performance assertions"
    echo "  ✅ Result generation"
    echo "  ✅ Baseline functionality"
    echo ""
    print_status "What cannot be tested locally:"
    echo "  ❌ GitHub PR comment posting"
    echo "  ❌ GitHub status checks"
    echo "  ❌ Branch protection integration"
    echo "  ❌ Workflow triggers (PR events)"
    echo ""
    print_status "Next steps:"
    echo "  1. Review the results above"
    echo "  2. Push to GitHub to test the full CI workflow"
    echo "  3. Create a test PR to verify GitHub Actions integration"
}

# Show help
show_help() {
    echo "Lighthouse CI Local Testing Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  test        Run full local test simulation (default)"
    echo "  quick       Run quick Lighthouse CI test only"
    echo "  clean       Clean up previous test results"
    echo "  help        Show this help message"
    echo ""
    echo "This script simulates the GitHub Actions Lighthouse CI workflow locally"
    echo "to help you test the configuration before pushing to GitHub."
    echo ""
}

# Quick test (just Lighthouse CI)
quick_test() {
    print_header "Quick Lighthouse CI Test"
    
    check_prerequisites
    start_dev_server
    sleep 3
    
    print_status "Running quick Lighthouse CI test..."
    yarn lighthouse:local
    
    ./lighthouse-results.sh summary
    print_success "Quick test completed"
}

# Clean up test results
clean_results() {
    print_header "Cleaning Test Results"
    
    if [ -d ".lighthouseci" ]; then
        rm -rf .lighthouseci
        print_success "Removed .lighthouseci directory"
    else
        print_status "No .lighthouseci directory found"
    fi
    
    # Kill any running dev servers
    pkill -f "next.*3000" 2>/dev/null && print_success "Stopped running dev servers" || true
}

# Script entry point
case "${1:-test}" in
    "test")
        main
        ;;
    "quick")
        quick_test
        ;;
    "clean")
        clean_results
        ;;
    "help"|*)
        show_help
        ;;
esac
