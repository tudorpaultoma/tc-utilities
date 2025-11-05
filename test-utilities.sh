#!/bin/bash

#==============================================================================
# Utilities Testing Script
#==============================================================================
# 
# Purpose: Comprehensive testing suite for Tencent Cloud Utilities
# Tests both NGINX installation and CVM identification functionality
#
# Usage: bash test-utilities.sh [URL]
#   URL: Optional URL to test (defaults to http://localhost/)
#
# Author: Tencent Cloud Utilities
# Version: 1.0
#==============================================================================

# Configuration
DEFAULT_URL="http://localhost/"
TEST_URL="${1:-$DEFAULT_URL}"
TIMEOUT=10

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS")
            echo -e "${GREEN}✓ PASSED${NC}: $message"
            ;;
        "FAIL")
            echo -e "${RED}✗ FAILED${NC}: $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠ WARNING${NC}: $message"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ INFO${NC}: $message"
            ;;
    esac
}

# Function to test HTTP connectivity
test_connectivity() {
    echo ""
    echo "=== Connectivity Tests ==="
    
    # Test basic connectivity
    if curl -s --connect-timeout $TIMEOUT --max-time $TIMEOUT "$TEST_URL" >/dev/null 2>&1; then
        print_status "PASS" "HTTP connectivity to $TEST_URL"
    else
        print_status "FAIL" "Cannot connect to $TEST_URL"
        return 1
    fi
    
    # Test response code
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout $TIMEOUT "$TEST_URL")
    if [ "$response_code" = "200" ]; then
        print_status "PASS" "HTTP response code: $response_code"
    else
        print_status "FAIL" "HTTP response code: $response_code (expected 200)"
    fi
}

# Function to test NGINX installation
test_nginx() {
    echo ""
    echo "=== NGINX Installation Tests ==="
    
    # Test if NGINX is installed
    if command -v nginx >/dev/null 2>&1; then
        print_status "PASS" "NGINX is installed"
        local nginx_version=$(nginx -v 2>&1 | grep -o 'nginx/[0-9.]*')
        print_status "INFO" "NGINX version: $nginx_version"
    else
        print_status "FAIL" "NGINX is not installed"
        return 1
    fi
    
    # Test NGINX service status
    if systemctl is-active nginx >/dev/null 2>&1; then
        print_status "PASS" "NGINX service is running"
    else
        print_status "FAIL" "NGINX service is not running"
    fi
    
    # Test NGINX boot configuration
    if systemctl is-enabled nginx >/dev/null 2>&1; then
        print_status "PASS" "NGINX is enabled to start on boot"
    else
        print_status "WARN" "NGINX is not enabled for boot startup"
    fi
    
    # Test NGINX configuration
    if nginx -t >/dev/null 2>&1; then
        print_status "PASS" "NGINX configuration is valid"
    else
        print_status "FAIL" "NGINX configuration has errors"
    fi
    
    # Test if NGINX is listening on port 80
    if ss -tlnp 2>/dev/null | grep -q ':80 ' || netstat -tlnp 2>/dev/null | grep -q ':80 '; then
        print_status "PASS" "NGINX is listening on port 80"
    else
        print_status "WARN" "NGINX may not be listening on port 80"
    fi
}

# Function to test CVM identification
test_cvm_identification() {
    echo ""
    echo "=== CVM Identification Tests ==="
    
    # Test for CVM header presence
    local cvm_header=$(curl -s -I --connect-timeout $TIMEOUT "$TEST_URL" | grep -i "X-CVM-Info" | head -1)
    if [ -n "$cvm_header" ]; then
        print_status "PASS" "CVM identification header found"
        print_status "INFO" "Header: $cvm_header"
        
        # Parse header components
        local header_value=$(echo "$cvm_header" | cut -d':' -f2- | xargs)
        local zone=$(echo "$header_value" | cut -d'|' -f1 | xargs)
        local ip=$(echo "$header_value" | cut -d'|' -f2 | xargs)
        local instance=$(echo "$header_value" | cut -d'|' -f3 | xargs)
        
        print_status "INFO" "Zone: $zone"
        print_status "INFO" "IP: $ip"
        print_status "INFO" "Instance: $instance"
        
        # Validate format
        if [[ "$header_value" == *"|"*"|"* ]]; then
            print_status "PASS" "Header format is correct (zone | ip | instance)"
        else
            print_status "WARN" "Header format may be incorrect"
        fi
    else
        print_status "FAIL" "CVM identification header not found"
    fi
    
    # Test health endpoint
    local health_url="${TEST_URL%/}/health"
    if curl -s --connect-timeout $TIMEOUT "$health_url" | grep -q "OK"; then
        print_status "PASS" "Health endpoint is working"
    else
        print_status "WARN" "Health endpoint not found or not working"
    fi
}

# Function to test performance
test_performance() {
    echo ""
    echo "=== Performance Tests ==="
    
    # Test response time
    local response_time=$(curl -w "%{time_total}" -s -o /dev/null --connect-timeout $TIMEOUT "$TEST_URL")
    print_status "INFO" "Response time: ${response_time}s"
    
    if (( $(echo "$response_time < 1.0" | bc -l) )); then
        print_status "PASS" "Response time is good (< 1s)"
    elif (( $(echo "$response_time < 3.0" | bc -l) )); then
        print_status "WARN" "Response time is acceptable (< 3s)"
    else
        print_status "FAIL" "Response time is slow (> 3s)"
    fi
    
    # Test multiple requests for consistency
    local consistent=true
    local first_header=""
    
    print_status "INFO" "Testing consistency across 5 requests..."
    for i in {1..5}; do
        local current_header=$(curl -s -I --connect-timeout $TIMEOUT "$TEST_URL" | grep -i "X-CVM-Info" | head -1)
        if [ -z "$first_header" ]; then
            first_header="$current_header"
        elif [ "$current_header" != "$first_header" ]; then
            consistent=false
            break
        fi
        sleep 0.1
    done
    
    if [ "$consistent" = true ]; then
        print_status "PASS" "CVM identification is consistent across requests"
    else
        print_status "INFO" "CVM identification varies (normal for load balancers)"
    fi
}

# Function to run load balancer specific tests
test_load_balancer() {
    echo ""
    echo "=== Load Balancer Tests ==="
    
    print_status "INFO" "Collecting 10 requests to analyze distribution..."
    
    declare -A instance_count
    local total_requests=10
    
    for i in $(seq 1 $total_requests); do
        local header=$(curl -s -I --connect-timeout $TIMEOUT "$TEST_URL" | grep -i "X-CVM-Info" | head -1)
        if [ -n "$header" ]; then
            local instance=$(echo "$header" | cut -d':' -f2- | xargs)
            instance_count["$instance"]=$((${instance_count["$instance"]} + 1))
        fi
        sleep 0.1
    done
    
    if [ ${#instance_count[@]} -gt 0 ]; then
        print_status "PASS" "Load balancer distribution analysis:"
        for instance in "${!instance_count[@]}"; do
            local count=${instance_count[$instance]}
            local percentage=$((count * 100 / total_requests))
            print_status "INFO" "  $instance: $count requests (${percentage}%)"
        done
        
        if [ ${#instance_count[@]} -gt 1 ]; then
            print_status "PASS" "Multiple backend instances detected (${#instance_count[@]} instances)"
        else
            print_status "INFO" "Single backend instance (not load balanced or sticky sessions)"
        fi
    else
        print_status "FAIL" "No CVM identification found in requests"
    fi
}

# Main execution
main() {
    echo "=== Tencent Cloud Utilities Test Suite ==="
    echo "Testing URL: $TEST_URL"
    echo "Timeout: ${TIMEOUT}s"
    
    # Check dependencies
    if ! command -v curl >/dev/null 2>&1; then
        print_status "FAIL" "curl is required but not installed"
        exit 1
    fi
    
    # Run tests
    test_connectivity || exit 1
    test_nginx
    test_cvm_identification
    test_performance
    
    # Only run load balancer tests if URL is not localhost
    if [[ "$TEST_URL" != *"localhost"* && "$TEST_URL" != *"127.0.0.1"* ]]; then
        test_load_balancer
    fi
    
    echo ""
    echo "=== Test Suite Complete ==="
    echo ""
    echo "Additional manual tests you can run:"
    echo "  Continuous monitoring:    while true; do curl -s -I $TEST_URL | grep -i 'X-CVM-Info' || date; sleep 0.5; done"
    echo "  Watch-based monitoring:   watch -n0.5 'curl -s -I $TEST_URL | grep X-CVM-Info'"
    echo "  Response time monitoring: while true; do curl -w \"\$(date '+%H:%M:%S') | Time: %{time_total}s\\n\" -s -o /dev/null $TEST_URL; sleep 1; done"
}

# Show usage if help requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [URL]"
    echo ""
    echo "Test the Tencent Cloud Utilities installation and functionality"
    echo ""
    echo "Arguments:"
    echo "  URL    Optional URL to test (default: http://localhost/)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Test localhost"
    echo "  $0 http://poc.fluffbits.com/         # Test remote server"
    echo "  $0 http://your-load-balancer.com/    # Test load balancer"
    exit 0
fi

# Run main function
main "$@"