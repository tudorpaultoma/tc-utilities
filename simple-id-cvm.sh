#!/bin/bash

#==============================================================================
# CVM Auto-Identifier Script
#==============================================================================
# 
# Purpose: Automatically identifies Tencent Cloud CVM instance details and 
#          configures nginx to respond with a single header containing:
#          Zone | IP | Instance-ID
#
# Usage:   sudo ./simple-id-cvm.sh
#
# Output:  X-CVM-Info header with format: "ap-singapore-1 | 10.0.0.100 | ins-abc123"
#
# Author:  Auto-generated for CVM identification
# Version: 1.0
#==============================================================================

# Exit immediately if any command fails
set -e

#------------------------------------------------------------------------------
# LOGGING FUNCTION
#------------------------------------------------------------------------------
# Logs messages with timestamp for debugging and monitoring
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

#------------------------------------------------------------------------------
# METADATA SERVICE FUNCTION
#------------------------------------------------------------------------------
# Queries Tencent Cloud metadata service for instance information
# The metadata service is available at http://metadata.tencentyun.com/latest/meta-data/
# and provides instance details without requiring authentication
get_metadata() {
    local endpoint="$1"
    # Use curl with timeout to prevent hanging
    # Suppress errors and return empty string if service unavailable
    curl -s --max-time 10 "http://metadata.tencentyun.com/latest/meta-data/$endpoint" 2>/dev/null || echo ""
}

#------------------------------------------------------------------------------
# IP ADDRESS DETECTION
#------------------------------------------------------------------------------
# Attempts to determine the CVM's IP address using multiple methods
get_cvm_ip() {
    # Method 1: Try to get private IP from metadata service (most reliable)
    local private_ip=$(get_metadata "local-ipv4")
    
    if [ -n "$private_ip" ]; then
        echo "$private_ip"
        return 0
    fi
    
    # Method 2: Fallback to system hostname command
    # This gets the first IP address from the system
    local ip=$(hostname -I | awk '{print $1}')
    if [ -n "$ip" ]; then
        echo "$ip"
        return 0
    fi
    
    # Method 3: Final fallback if all else fails
    echo "unknown-ip"
}

#------------------------------------------------------------------------------
# AVAILABILITY ZONE DETECTION
#------------------------------------------------------------------------------
# Determines the availability zone where the CVM is running
get_availability_zone() {
    # Method 1: Direct zone query from metadata service
    local az=$(get_metadata "placement/zone")
    
    if [ -n "$az" ]; then
        echo "$az"
        return 0
    fi
    
    # Method 2: Fallback - construct zone from region + default suffix
    local region=$(get_metadata "placement/region")
    if [ -n "$region" ]; then
        # Append default zone suffix if only region is available
        echo "${region}-1"
        return 0
    fi
    
    # Method 3: Final fallback
    echo "unknown-zone"
}

#------------------------------------------------------------------------------
# INSTANCE ID DETECTION
#------------------------------------------------------------------------------
# Retrieves the unique instance identifier for this CVM
get_instance_id() {
    local instance_id=$(get_metadata "instance-id")
    if [ -n "$instance_id" ]; then
        echo "$instance_id"
    else
        # Fallback identifier if metadata service fails
        echo "unknown-instance"
    fi
}

#==============================================================================
# MAIN EXECUTION FUNCTION
#==============================================================================
main() {
    log "Starting CVM auto-identification process..."
    
    #--------------------------------------------------------------------------
    # PRIVILEGE CHECK
    #--------------------------------------------------------------------------
    # Script must run as root to modify nginx configuration files
    if [ "$EUID" -ne 0 ]; then
        log "ERROR: This script must be run as root (use sudo)"
        log "       nginx configuration requires root privileges"
        exit 1
    fi
    
    #--------------------------------------------------------------------------
    # DEPENDENCY CHECK
    #--------------------------------------------------------------------------
    # Ensure nginx is installed and available
    if ! command -v nginx &> /dev/null; then
        log "ERROR: nginx is not installed"
        log "       Install nginx first: apt-get install nginx"
        exit 1
    fi
    
    #--------------------------------------------------------------------------
    # GATHER CVM INFORMATION
    #--------------------------------------------------------------------------
    log "Querying Tencent Cloud metadata service..."
    
    # Collect all required information
    local cvm_ip=$(get_cvm_ip)
    local availability_zone=$(get_availability_zone)
    local instance_id=$(get_instance_id)
    
    # Display detected information
    log "CVM Information Detected:"
    log "  IP Address: $cvm_ip"
    log "  Availability Zone: $availability_zone"
    log "  Instance ID: $instance_id"
    
    #--------------------------------------------------------------------------
    # CLEANUP OLD CONFIGURATIONS
    #--------------------------------------------------------------------------
    # Remove any existing backend identification configs to prevent conflicts
    log "Cleaning up old nginx configurations..."
    rm -f /etc/nginx/conf.d/backend-headers.conf
    rm -f /etc/nginx/conf.d/lb-test.conf
    rm -f /etc/nginx/conf.d/instance3.conf
    rm -f /etc/nginx/conf.d/auto-instance.conf
    
    #--------------------------------------------------------------------------
    # CREATE NGINX CONFIGURATION
    #--------------------------------------------------------------------------
    # Generate nginx config with single header containing all CVM info
    log "Creating nginx configuration with CVM identification header..."
    
    cat > /etc/nginx/conf.d/auto-instance.conf << EOF
# Auto-generated CVM identification configuration
# Generated on: $(date)
# Contains single header with format: Zone | IP | Instance-ID

server {
    listen 80;
    server_name _;
    
    # Primary identification header - visible in all responses
    # Format: "availability-zone | ip-address | instance-id"
    add_header X-CVM-Info "$availability_zone | $cvm_ip | $instance_id" always;
    
    # Default location - returns CVM info as plain text
    location / {
        return 200 "CVM: $availability_zone | $cvm_ip | $instance_id\\n";
        add_header Content-Type "text/plain" always;
        add_header X-CVM-Info "$availability_zone | $cvm_ip | $instance_id" always;
    }
    
    # Health check endpoint for load balancers
    location /health {
        return 200 "OK";
        add_header Content-Type "text/plain" always;
        add_header X-CVM-Info "$availability_zone | $cvm_ip | $instance_id" always;
    }
}
EOF
    
    #--------------------------------------------------------------------------
    # VALIDATE AND DEPLOY CONFIGURATION
    #--------------------------------------------------------------------------
    log "Validating nginx configuration..."
    
    # Test configuration syntax before applying
    if nginx -t; then
        log "Configuration syntax is valid"
        log "Reloading nginx with new configuration..."
        
        # Apply the new configuration
        systemctl reload nginx
        
        # Success message with header format
        log "SUCCESS! CVM identification configured"
        log "Header format: X-CVM-Info: $availability_zone | $cvm_ip | $instance_id"
        
    else
        log "ERROR: nginx configuration syntax validation failed"
        log "       Configuration not applied"
        exit 1
    fi
    
    #--------------------------------------------------------------------------
    # TESTING INSTRUCTIONS
    #--------------------------------------------------------------------------
    log ""
    log "=== TESTING ==="
    log "Test the configuration with these commands:"
    log "  curl -I http://localhost/          # View headers"
    log "  curl http://localhost/             # View response body"
    log "  curl http://localhost/health       # Health check"
    log ""
    log "Look for the X-CVM-Info header in your testing tool!"
}

#==============================================================================
# SCRIPT ENTRY POINT
#==============================================================================
# Execute main function with all command line arguments
main "$@"