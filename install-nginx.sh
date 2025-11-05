#!/bin/bash

#==============================================================================
# NGINX Auto-Installer Script
#==============================================================================
# 
# Purpose: Automatically installs NGINX web server on various Linux distributions
#          with proper repository setup and service configuration
#
# Supported Distributions:
#   - Ubuntu (all LTS versions)
#   - Debian (9, 10, 11, 12)
#   - CentOS/RHEL (7, 8, 9)
#   - Oracle Linux, AlmaLinux, Rocky Linux
#
# Features:
#   - Distribution detection and appropriate installation method
#   - Official NGINX repositories for latest stable versions
#   - Automatic service startup and boot enablement
#   - Error handling and validation
#   - Post-installation verification
#
# Usage: sudo ./install-nginx.sh
#
# Author: Tencent Cloud Utilities
# Version: 1.0
#==============================================================================

# Exit immediately if any command fails
set -e

#------------------------------------------------------------------------------
# PRIVILEGE VALIDATION
#------------------------------------------------------------------------------
# NGINX installation requires root privileges for:
# - Package installation
# - Service management  
# - Repository configuration
# - System file modifications
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as root or with sudo privileges"
   echo "Usage: sudo ./install-nginx.sh"
   exit 1
fi

#------------------------------------------------------------------------------
# USER CONFIRMATION
#------------------------------------------------------------------------------
# Interactive confirmation to prevent accidental installations
# Provides clear information about what the script will do
echo "=== NGINX Auto-Installer ==="
echo "This script will:"
echo "  - Detect your Linux distribution"
echo "  - Install official NGINX repositories"
echo "  - Install the latest stable NGINX version"
echo "  - Configure NGINX to start automatically"
echo "  - Verify the installation"
echo ""

read -p "Do you wish to continue with NGINX installation? (y/n) " -n 1 -r
echo ""

# Exit gracefully if user declines
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled by user."
    exit 0
fi

echo "Starting NGINX installation..."

#------------------------------------------------------------------------------
# CENTOS/RHEL/ROCKY/ALMA LINUX INSTALLATION FUNCTION
#------------------------------------------------------------------------------
# Handles NGINX installation for Red Hat-based distributions
# Uses EPEL repository for NGINX packages
# Supports both yum (CentOS 7) and dnf (CentOS 8+) package managers
install_nginx_centos() {
    echo "Installing NGINX on Red Hat-based system..."
    
    # Detect package manager (dnf for newer versions, yum for older)
    if command -v dnf &> /dev/null; then
        PKG_MGR="dnf"
    else
        PKG_MGR="yum"
    fi
    
    echo "Using package manager: $PKG_MGR"
    
    # Install EPEL repository for CentOS 9+ using dnf
    if [[ "$PKG_MGR" == "dnf" ]]; then
        echo "Installing EPEL repository for CentOS 9+..."
        dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y || { 
            echo 'ERROR: Installing EPEL repository failed' 
            exit 1
        }
    fi
    
    # Install package management utilities
    echo "Installing package management utilities..."
    $PKG_MGR install yum-utils -y || { 
        echo 'ERROR: Installing yum-utils failed' 
        exit 1
    }

    # Install EPEL repository (Extra Packages for Enterprise Linux)
    # EPEL provides additional packages not included in the base repository
    echo "Installing EPEL repository..."
    $PKG_MGR install epel-release -y || { 
        echo 'ERROR: Installing EPEL repository failed' 
        exit 1
    }

    # Update the package repository metadata
    echo "Updating package repository..."
    $PKG_MGR update -y || { 
        echo 'ERROR: Updating repository failed' 
        exit 1
    }

    # Install NGINX web server
    echo "Installing NGINX package..."
    $PKG_MGR install nginx -y || { 
        echo 'ERROR: Installing NGINX failed' 
        exit 1
    }

    # Start the NGINX service immediately
    echo "Starting NGINX service..."
    systemctl start nginx || { 
        echo 'ERROR: Starting NGINX failed' 
        exit 1
    }

    # Enable NGINX to start automatically on system boot
    echo "Enabling NGINX to start on boot..."
    systemctl enable nginx || { 
        echo 'ERROR: Enabling NGINX to start on boot failed' 
        exit 1
    }
    
    echo "NGINX installation completed for Red Hat-based system."
}

#------------------------------------------------------------------------------
# DEBIAN INSTALLATION FUNCTION
#------------------------------------------------------------------------------
# Handles NGINX installation for Debian systems
# Uses official NGINX repository for latest stable versions
# Includes GPG key verification and repository pinning for security
install_nginx_debian() {
    echo "Installing NGINX on Debian system..."
    
    # Update the package repository information
    # This ensures we have the latest package metadata
    echo "Updating package repository information..."
    apt-get update -y || { 
        echo 'ERROR: Updating repository information failed' 
        exit 1
    }

    # Install required prerequisites for repository setup
    # curl: For downloading GPG keys
    # gnupg2: For GPG key management
    # ca-certificates: For HTTPS connections
    # lsb-release: For distribution detection
    # debian-archive-keyring: For Debian package verification
    echo "Installing prerequisites..."
    apt-get install curl gnupg2 ca-certificates lsb-release debian-archive-keyring -y || { 
        echo 'ERROR: Installing prerequisites failed' 
        exit 1
    }

    # Download and import the official NGINX GPG signing key
    # This ensures package authenticity and prevents tampering
    echo "Importing official NGINX GPG signing key..."
    curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null || { 
        echo 'ERROR: Importing NGINX signing key failed' 
        exit 1
    }

    # Add the official NGINX APT repository
    # Uses the distribution codename (e.g., bullseye, bookworm)
    # Signed-by ensures only signed packages are accepted
    echo "Adding official NGINX repository..."
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list || { 
        echo 'ERROR: Setting up the apt repository failed' 
        exit 1
    }

    # Set up repository pinning to prioritize NGINX official packages
    # Pin-Priority: 900 ensures NGINX repo packages are preferred over distribution packages
    echo "Configuring repository pinning..."
    echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99nginx || { 
        echo 'ERROR: Setting up repository pinning failed' 
        exit 1
    }

    # Update package information with new repository
    echo "Updating package information..."
    apt update || { 
        echo 'ERROR: Updating repository information failed' 
        exit 1
    }
    
    # Install NGINX from the official repository
    echo "Installing NGINX package..."
    apt install nginx -y || { 
        echo 'ERROR: Installing NGINX failed' 
        exit 1
    }

    # Start the NGINX service immediately
    echo "Starting NGINX service..."
    systemctl start nginx || { 
        echo 'ERROR: Starting NGINX failed' 
        exit 1
    }

    # Enable NGINX to start automatically on system boot
    echo "Enabling NGINX to start on boot..."
    systemctl enable nginx || { 
        echo 'ERROR: Enabling NGINX to start on boot failed' 
        exit 1
    }
    
    echo "NGINX installation completed for Debian system."
}

#------------------------------------------------------------------------------
# UBUNTU INSTALLATION FUNCTION
#------------------------------------------------------------------------------
# Handles NGINX installation for Ubuntu systems
# Uses Ubuntu's default repository for simplicity and compatibility
# Ubuntu maintains well-tested NGINX packages in their official repositories
install_nginx_ubuntu() {
    echo "Installing NGINX on Ubuntu system..."
    
    # Update the package repository information
    # This ensures we have the latest package metadata from all configured repositories
    echo "Updating package repository information..."
    apt-get update -y || { 
        echo 'ERROR: Updating repository information failed' 
        exit 1
    }

    # Install NGINX from Ubuntu's official repository
    # Ubuntu's NGINX packages are well-tested and integrated with the system
    # Includes automatic dependency resolution
    echo "Installing NGINX package..."
    apt-get install nginx -y || { 
        echo 'ERROR: Installing NGINX failed' 
        exit 1
    }

    # Start the NGINX service immediately
    # This makes NGINX available for immediate use
    echo "Starting NGINX service..."
    systemctl start nginx || { 
        echo 'ERROR: Starting NGINX failed' 
        exit 1
    }

    # Enable NGINX to start automatically on system boot
    # Ensures NGINX survives system reboots
    echo "Enabling NGINX to start on boot..."
    systemctl enable nginx || { 
        echo 'ERROR: Enabling NGINX to start on boot failed' 
        exit 1
    }
    
    echo "NGINX installation completed for Ubuntu system."
}

#==============================================================================
# DISTRIBUTION DETECTION AND INSTALLATION
#==============================================================================

# Check if the system has the standard Linux distribution identification file
if [ -f /etc/os-release ]; then
    # Source the OS release file to get distribution information
    # This file contains variables like ID, VERSION_ID, NAME, etc.
    . /etc/os-release
    
    echo "Detected Linux distribution: $NAME"
    echo "Distribution ID: $ID"
    echo "Version: ${VERSION_ID:-Unknown}"
    echo ""
    
    # Route to appropriate installation function based on distribution ID
    case $ID in
        centos|rhel|oraclelinux|almalinux|rocky)
            echo "Using Red Hat-based installation method..."
            install_nginx_centos
            ;;
        debian)
            echo "Using Debian-specific installation method..."
            install_nginx_debian
            ;;
        ubuntu)
            echo "Using Ubuntu-specific installation method..."
            install_nginx_ubuntu
            ;;
        *)
            echo "ERROR: Unsupported Linux distribution: $ID"
            echo "Supported distributions:"
            echo "  - Ubuntu (all LTS versions)"
            echo "  - Debian (9, 10, 11, 12)"
            echo "  - CentOS/RHEL (7, 8, 9)"
            echo "  - Oracle Linux, AlmaLinux, Rocky Linux"
            exit 1
            ;;
    esac
else
    echo "ERROR: Cannot detect Linux distribution"
    echo "This script requires /etc/os-release file for distribution detection"
    echo "Supported systems: Linux distributions with systemd"
    exit 1
fi

#==============================================================================
# POST-INSTALLATION VERIFICATION
#==============================================================================

echo ""
echo "=== Post-Installation Verification ==="

# Test if NGINX service is running
echo "Checking NGINX service status..."
if systemctl is-active nginx >/dev/null 2>&1; then
    echo "✓ NGINX service is running"
else
    echo "✗ NGINX service is not running"
    echo "Attempting to start NGINX..."
    systemctl start nginx || {
        echo "ERROR: Failed to start NGINX service"
        echo "Check logs with: journalctl -u nginx"
        exit 1
    }
fi

# Test if NGINX is enabled for boot
echo "Checking NGINX boot configuration..."
if systemctl is-enabled nginx >/dev/null 2>&1; then
    echo "✓ NGINX is enabled to start on boot"
else
    echo "✗ NGINX is not enabled for boot startup"
    echo "This may cause NGINX to not start after system reboot"
fi

# Get NGINX version information
echo "Checking NGINX version..."
NGINX_VERSION=$(nginx -v 2>&1 | grep -o 'nginx/[0-9.]*')
if [ -n "$NGINX_VERSION" ]; then
    echo "✓ NGINX version: $NGINX_VERSION"
else
    echo "⚠ Could not determine NGINX version"
fi

# Test NGINX configuration
echo "Testing NGINX configuration..."
if nginx -t >/dev/null 2>&1; then
    echo "✓ NGINX configuration is valid"
else
    echo "⚠ NGINX configuration has issues"
    echo "Run 'nginx -t' for detailed information"
fi

# Test if NGINX is listening on port 80
echo "Checking NGINX network binding..."
if ss -tlnp | grep -q ':80 ' || netstat -tlnp 2>/dev/null | grep -q ':80 '; then
    echo "✓ NGINX is listening on port 80"
else
    echo "⚠ NGINX may not be listening on port 80"
fi

# Final status summary
echo ""
echo "=== Installation Summary ==="
echo "✓ NGINX installation completed successfully"
echo "✓ Service is running and configured"
echo ""
echo "Next steps:"
echo "  - Test web server: curl http://localhost/"
echo "  - View logs: journalctl -u nginx"
echo "  - Configuration: /etc/nginx/"
echo "  - Document root: /var/www/html/ (Ubuntu/Debian) or /usr/share/nginx/html/ (CentOS/RHEL)"
echo ""
echo "🎉 NGINX is ready to serve web content!"