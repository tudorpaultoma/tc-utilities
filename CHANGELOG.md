# Changelog

All notable changes to the Tencent Cloud Utilities project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2024-11-05

### 🔄 Enhanced CVM Auto-Identifier

#### Changed
- **[CVM Auto-Identifier] Enhanced Header Format** 
  - Added timestamp to X-CVM-Info header
  - New format: `X-CVM-Info: zone | ip | instance-id | timestamp`
  - Timestamp in UTC format: "2024-11-05 14:30:25 UTC"
  - Provides configuration freshness tracking

#### Updated
- **Documentation** - Updated README and testing examples for new header format
- **Testing Script** - Enhanced test-utilities.sh to validate 4-component header format
- **Examples** - Updated all testing commands and examples

#### Benefits
- **Configuration Tracking** - Know when CVM identification was last configured
- **Debugging** - Easier to identify stale configurations
- **Monitoring** - Track configuration deployment times across instances

---

## [1.0.0] - 2024-11-05

### 🎉 Initial Release - Utilities Repository

#### Added
- **Repository Structure** - Established tc-utilities as a collection of Tencent Cloud tools
- **General Documentation** - Comprehensive README for multi-utility repository
- **Contribution Guidelines** - Framework for adding new utilities

#### Utilities Added
- **CVM Auto-Identifier** (`simple-id-cvm.sh`)
  - Automatic detection of CVM IP address, availability zone, and instance ID
  - Single header output format: `X-CVM-Info: zone | ip | instance-id | timestamp`
  - Integration with Tencent Cloud metadata service
  - nginx configuration generation and deployment
  - Comprehensive error handling and logging

- **NGINX Auto-Installer** (`install-nginx.sh`)
  - Multi-distribution support (Ubuntu, Debian, CentOS/RHEL, Rocky/Alma Linux)
  - Automatic Linux distribution detection and appropriate installation method
  - Official repository setup for latest stable NGINX versions
  - GPG key verification and secure package installation
  - Automatic service startup and boot configuration
  - Comprehensive post-installation verification and testing
  - Interactive user confirmation and detailed logging

#### Features
- **Metadata Service Integration**
  - Queries `http://metadata.tencentyun.com/latest/meta-data/` for instance information
  - No authentication required - uses built-in CVM metadata access
  - Automatic fallback mechanisms if metadata service is unavailable

- **nginx Configuration**
  - Creates `/etc/nginx/conf.d/auto-instance.conf` with CVM identification
  - Adds `X-CVM-Info` header to all HTTP responses
  - Provides `/` and `/health` endpoints
  - Automatic cleanup of conflicting configuration files

- **Robust Detection Logic**
  - **IP Address Detection**: Metadata service → hostname command → fallback
  - **Availability Zone**: Metadata zone → region+suffix → unknown-zone
  - **Instance ID**: Metadata service → unknown-instance fallback

- **Load Balancer Support**
  - Single header design perfect for testing tools
  - Health check endpoint at `/health`
  - Consistent header format across all responses

#### Documentation
- **Comprehensive README.md**
  - Quick start guide
  - Technical details and architecture
  - Troubleshooting section
  - Integration examples
  - Security considerations

- **Detailed Code Comments**
  - Function-level documentation
  - Inline explanations of complex logic
  - Error handling descriptions
  - Configuration file generation details

#### Technical Specifications
- **Requirements**: 
  - Tencent Cloud CVM instance
  - nginx web server
  - Root/sudo access
  - curl command (for metadata queries)

- **Compatibility**:
  - All Tencent Cloud regions
  - Ubuntu/Debian systems (primary)
  - CentOS/RHEL systems (compatible)

- **Performance**:
  - 10-second timeout on metadata queries
  - Minimal resource usage
  - Fast configuration deployment
  - No ongoing background processes

#### Security
- **No Stored Credentials**: Uses metadata service (no API keys required)
- **Local Configuration Only**: Script only modifies local nginx files
- **Root Access Required**: For nginx configuration file modifications
- **Metadata Service Security**: Only accessible from within CVM instance

### 📋 Migration Notes

This is the initial release. If you were using manual CVM identification scripts:

1. **Backup existing nginx configurations**
2. **Run the new script**: `sudo ./simple-id-cvm.sh`
3. **Update testing tools** to look for `X-CVM-Info` header
4. **Verify load balancer integration** with new header format

### 🔄 Breaking Changes

N/A - Initial release

### 🐛 Known Issues

- **Metadata Service Dependency**: Script relies on Tencent Cloud metadata service availability
- **nginx Requirement**: nginx must be installed and running
- **Root Access**: Script must run with sudo/root privileges

### 🚀 Future Roadmap

#### Planned for v1.1.0 - Infrastructure Utilities
- [ ] **CVM Batch Manager** - Start/stop/restart multiple instances
- [ ] **Instance Health Checker** - Comprehensive health monitoring
- [ ] **VPC Subnet Calculator** - IP range planning and validation
- [ ] **Security Group Auditor** - Analyze and optimize security rules

#### Planned for v1.2.0 - Storage & Monitoring 
- [ ] **COS Sync Utility** - Efficient object storage synchronization
- [ ] **Snapshot Manager** - Automated backup scheduling and cleanup
- [ ] **Custom Metrics Collector** - Application-specific monitoring
- [ ] **Log Aggregator** - Centralized logging setup

#### Planned for v1.3.0 - DevOps Integration
- [ ] **CI/CD Helpers** - Deployment automation scripts
- [ ] **Configuration Templater** - Infrastructure as code utilities
- [ ] **Environment Manager** - Multi-environment deployment tools
- [ ] **Alert Manager** - Custom alerting rules and notifications

#### CVM Auto-Identifier Enhancements
- [ ] Support for custom header names and formats
- [ ] JSON output format option
- [ ] Support for multiple web servers (Apache, Caddy)
- [ ] Systemd service integration
- [ ] Configuration validation checks

### 📊 Repository Statistics

- **Total Utilities**: 2 (CVM Auto-Identifier, NGINX Auto-Installer)
- **Lines of Code**: ~400 total (~200 CVM identifier, ~200 NGINX installer)
- **Documentation**: 4,000+ words across README and CHANGELOG
- **Supported Regions**: All Tencent Cloud regions (CVM identifier)
- **Target Platforms**: Ubuntu/Debian, CentOS/RHEL, Rocky/Alma Linux

### 🎯 Utility Breakdown

#### CVM Auto-Identifier
- **Functions**: 5 main functions
- **Dependencies**: curl, nginx
- **Test Coverage**: Manual testing on multiple CVM instances
- **Use Cases**: Load balancing, debugging, monitoring

#### NGINX Auto-Installer
- **Functions**: 4 main functions (3 distribution-specific installers + main)
- **Dependencies**: curl, gpg, systemctl
- **Supported Distributions**: Ubuntu, Debian, CentOS/RHEL, Rocky/Alma Linux
- **Use Cases**: Server setup automation, development environment preparation

### 🙏 Acknowledgments

- **Tencent Cloud** for providing reliable metadata service and comprehensive APIs
- **nginx Community** for excellent documentation and stable software
- **Open Source Community** for best practices and conventions
- **Contributors** who will help expand this utilities collection

### 📞 Support

For support with this release:
- Check the README.md troubleshooting section
- Review utility-specific documentation
- Verify Tencent Cloud connectivity and permissions
- Open GitHub issues for bugs or feature requests

---

## Version History Summary

| Version | Date | Major Changes |
|---------|------|---------------|
| 1.0.0 | 2024-11-05 | Initial repository with CVM Auto-Identifier utility |

---

## Changelog Format

This changelog follows the [Keep a Changelog](https://keepachangelog.com/) format. Each version includes:

- **Added** for new features and utilities
- **Changed** for changes in existing functionality  
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes

### Utility-Specific Changes

When utilities are updated, changes will be documented with the utility name:
- **[Utility Name] Added**: New features for specific utility
- **[Utility Name] Fixed**: Bug fixes for specific utility
- **[Utility Name] Changed**: Modifications to existing utility functionality