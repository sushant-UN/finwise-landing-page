#!/bin/bash

# Lighthouse Results Viewer Script
# This script helps you view and analyze Lighthouse CI results

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

# Show quick summary of latest results
show_summary() {
    if [ ! -d ".lighthouseci" ]; then
        print_error "No Lighthouse results found. Run 'yarn lighthouse:local' first."
        exit 1
    fi
    
    # Get the latest result file
    latest_file=$(ls -t .lighthouseci/lhr-*.json 2>/dev/null | head -n1)
    
    if [ -z "$latest_file" ]; then
        print_error "No Lighthouse result files found."
        exit 1
    fi
    
    print_header "Latest Lighthouse Results Summary"
    
    node -e "
    const fs = require('fs');
    const result = JSON.parse(fs.readFileSync('$latest_file', 'utf8'));
    
    console.log('🌐 URL:', result.finalUrl);
    console.log('⏰ Run Time:', new Date(result.fetchTime).toLocaleString());
    console.log('');
    
    // Core Web Vitals
    console.log('📊 Core Web Vitals:');
    const lcp = Math.round(result.audits['largest-contentful-paint'].numericValue);
    const fcp = Math.round(result.audits['first-contentful-paint'].numericValue);
    const cls = result.audits['cumulative-layout-shift'].numericValue.toFixed(3);
    const tbt = Math.round(result.audits['total-blocking-time'].numericValue);
    
    // Color coding for results
    const formatMetric = (value, good, okay, unit = 'ms') => {
        let color = '';
        if (unit === 'ms') {
            if (value <= good) color = '🟢';
            else if (value <= okay) color = '🟡';
            else color = '🔴';
        } else { // CLS
            if (value <= good) color = '🟢';
            else if (value <= okay) color = '🟡';
            else color = '🔴';
        }
        return color + ' ' + value + unit;
    };
    
    console.log('  LCP (Largest Contentful Paint):', formatMetric(lcp, 2500, 4000));
    console.log('  FCP (First Contentful Paint):', formatMetric(fcp, 1800, 3000));
    console.log('  CLS (Cumulative Layout Shift):', formatMetric(cls, 0.1, 0.25, ''));
    console.log('  TBT (Total Blocking Time):', formatMetric(tbt, 200, 600));
    console.log('');
    
    // Performance score
    const perfScore = Math.round(result.categories.performance.score * 100);
    let scoreColor = '🔴';
    if (perfScore >= 90) scoreColor = '🟢';
    else if (perfScore >= 50) scoreColor = '🟡';
    
    console.log('🎯 Performance Score:', scoreColor, perfScore + '%');
    console.log('');
    
    // Quick recommendations
    console.log('💡 Quick Analysis:');
    if (lcp > 4000) console.log('  ⚠️  LCP is slow - optimize largest image/element loading');
    if (fcp > 3000) console.log('  ⚠️  FCP is slow - reduce render-blocking resources');
    if (cls > 0.25) console.log('  ⚠️  CLS is high - fix layout shifts (images without dimensions, dynamic content)');
    if (tbt > 600) console.log('  ⚠️  TBT is high - reduce JavaScript execution time');
    
    if (lcp <= 2500 && fcp <= 1800 && cls <= 0.1 && tbt <= 200) {
        console.log('  ✅ All Core Web Vitals are in the GOOD range!');
    }
    "
}

# Show all available results
list_results() {
    if [ ! -d ".lighthouseci" ]; then
        print_error "No Lighthouse results found."
        exit 1
    fi
    
    print_header "Available Lighthouse Results"
    
    echo "JSON Reports (detailed data):"
    ls -la .lighthouseci/*.json 2>/dev/null | while read line; do
        echo "  📄 $line"
    done
    
    echo ""
    echo "HTML Reports (visual reports):"
    ls -la .lighthouseci/*.html 2>/dev/null | while read line; do
        echo "  🌐 $line"
    done
}

# Open HTML report in browser
open_report() {
    if [ ! -d ".lighthouseci" ]; then
        print_error "No Lighthouse results found."
        exit 1
    fi
    
    # Get the latest HTML file
    latest_html=$(ls -t .lighthouseci/lhr-*.html 2>/dev/null | head -n1)
    
    if [ -z "$latest_html" ]; then
        print_error "No HTML report files found."
        exit 1
    fi
    
    print_status "Opening latest HTML report: $latest_html"
    
    # Try different ways to open based on OS
    if command -v open &> /dev/null; then
        # macOS
        open "$latest_html"
    elif command -v xdg-open &> /dev/null; then
        # Linux
        xdg-open "$latest_html"
    elif command -v start &> /dev/null; then
        # Windows
        start "$latest_html"
    else
        print_warning "Could not auto-open browser. Please manually open: $latest_html"
        echo "You can also copy this path and open it in your browser:"
        echo "file://$(pwd)/$latest_html"
    fi
}

# Compare with previous run
compare_runs() {
    if [ ! -d ".lighthouseci" ]; then
        print_error "No Lighthouse results found."
        exit 1
    fi
    
    # Get the two latest result files
    results=($(ls -t .lighthouseci/lhr-*.json 2>/dev/null | head -n2))
    
    if [ ${#results[@]} -lt 2 ]; then
        print_error "Need at least 2 runs to compare. Only found ${#results[@]} result(s)."
        exit 1
    fi
    
    latest="${results[0]}"
    previous="${results[1]}"
    
    print_header "Comparing Latest vs Previous Run"
    
    node -e "
    const fs = require('fs');
    const latest = JSON.parse(fs.readFileSync('$latest', 'utf8'));
    const previous = JSON.parse(fs.readFileSync('$previous', 'utf8'));
    
    console.log('📊 Latest Run:', new Date(latest.fetchTime).toLocaleString());
    console.log('📊 Previous Run:', new Date(previous.fetchTime).toLocaleString());
    console.log('');
    
    const compareMetric = (name, latestVal, prevVal, unit = 'ms', lowerIsBetter = true) => {
        const diff = latestVal - prevVal;
        const percentChange = ((diff / prevVal) * 100).toFixed(1);
        
        let indicator = '➡️ ';
        if (Math.abs(diff) < 0.001) indicator = '➡️ ';
        else if (lowerIsBetter) {
            indicator = diff < 0 ? '🟢⬇️' : '🔴⬆️';
        } else {
            indicator = diff > 0 ? '🟢⬆️' : '🔴⬇️';
        }
        
        const sign = diff > 0 ? '+' : '';
        console.log('  ' + name + ':');
        console.log('    Latest: ' + latestVal + unit + ' | Previous: ' + prevVal + unit);
        console.log('    Change: ' + indicator + ' ' + sign + diff.toFixed(unit === '' ? 3 : 0) + unit + ' (' + sign + percentChange + '%)');
        console.log('');
    };
    
    // Compare Core Web Vitals
    console.log('Core Web Vitals Comparison:');
    compareMetric('LCP', latest.audits['largest-contentful-paint'].numericValue, previous.audits['largest-contentful-paint'].numericValue);
    compareMetric('FCP', latest.audits['first-contentful-paint'].numericValue, previous.audits['first-contentful-paint'].numericValue);
    compareMetric('CLS', latest.audits['cumulative-layout-shift'].numericValue, previous.audits['cumulative-layout-shift'].numericValue, '', true);
    compareMetric('TBT', latest.audits['total-blocking-time'].numericValue, previous.audits['total-blocking-time'].numericValue);
    
    // Performance score comparison
    const latestScore = latest.categories.performance.score * 100;
    const prevScore = previous.categories.performance.score * 100;
    compareMetric('Performance Score', latestScore, prevScore, '%', false);
    "
}

# Show assertion results
show_assertions() {
    if [ ! -f ".lighthouseci/assertion-results.json" ]; then
        print_error "No assertion results found. Run Lighthouse CI first."
        exit 1
    fi
    
    print_header "Lighthouse CI Assertion Results"
    
    node -e "
    const fs = require('fs');
    const assertions = JSON.parse(fs.readFileSync('.lighthouseci/assertion-results.json', 'utf8'));
    
    // Group assertions by status
    const passed = assertions.filter(a => a.passed);
    const failed = assertions.filter(a => !a.passed);
    
    console.log('📊 Assertion Summary:');
    console.log('  ✅ Passed:', passed.length);
    console.log('  ❌ Failed:', failed.length);
    console.log('  📈 Total:', assertions.length);
    console.log('');
    
    if (failed.length > 0) {
        console.log('❌ Failed Assertions:');
        failed.forEach(assertion => {
            console.log('  🔴', assertion.auditTitle || assertion.auditId);
            console.log('    Expected:', assertion.operator, assertion.expected);
            console.log('    Actual:', assertion.actual);
            console.log('    URL:', assertion.url);
            if (assertion.auditDocumentationLink) {
                console.log('    Docs:', assertion.auditDocumentationLink);
            }
            console.log('');
        });
    } else {
        console.log('🎉 All assertions passed!');
    }
    
    if (passed.length > 0 && failed.length === 0) {
        console.log('');
        console.log('✅ Key Metrics (All Passed):');
        const coreWebVitals = passed.filter(a => 
            ['largest-contentful-paint', 'first-contentful-paint', 'cumulative-layout-shift', 'total-blocking-time'].includes(a.auditId)
        );
        
        coreWebVitals.forEach(assertion => {
            console.log('  ✅', assertion.auditTitle, ':', assertion.actual, assertion.operator, assertion.expected);
        });
    }
    "
}

# Show help
show_help() {
    echo "🔍 Lighthouse Results Viewer"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  summary         Show quick summary of latest results (default)"
    echo "  list           List all available result files"
    echo "  open           Open latest HTML report in browser"
    echo "  compare        Compare latest vs previous run"
    echo "  assertions     Show assertion results (pass/fail)"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Quick summary"
    echo "  $0 summary                  # Same as above"
    echo "  $0 open                     # Open visual report"
    echo "  $0 compare                  # Compare with previous run"
    echo ""
    echo "File Locations:"
    echo "  📁 Results folder: .lighthouseci/"
    echo "  📄 JSON reports: .lighthouseci/lhr-*.json"
    echo "  🌐 HTML reports: .lighthouseci/lhr-*.html"
    echo "  ✅ Assertions: .lighthouseci/assertion-results.json"
    echo ""
}

# Main script logic
case "${1:-summary}" in
    "summary")
        show_summary
        ;;
    "list")
        list_results
        ;;
    "open")
        open_report
        ;;
    "compare")
        compare_runs
        ;;
    "assertions")
        show_assertions
        ;;
    "help"|*)
        show_help
        ;;
esac
