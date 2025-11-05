# Tencent Cloud Utilities

A collection of practical utilities and scripts for Tencent Cloud infrastructure management, automation, and operations. This repository contains tools to simplify common tasks, improve operational efficiency, and solve real-world problems in Tencent Cloud environments.

## 🎯 Purpose

This repository provides ready-to-use utilities for:
- **Infrastructure Automation** - Scripts to automate common cloud operations
- **Monitoring & Debugging** - Tools for troubleshooting and system visibility
- **Configuration Management** - Utilities to standardize and manage configurations
- **Operational Efficiency** - Scripts that save time on repetitive tasks

## 📦 Repository Structure

```
tc-utilities/
├── simple-id-cvm.sh    # CVM identification utility
├── README.md           # This documentation
├── CHANGELOG.md        # Version history
└── LICENSE            # MIT license
```

## 🛠️ Available Utilities

### 1. CVM Auto-Identifier (`simple-id-cvm.sh`)

**Purpose**: Automatically identifies CVM instances and configures nginx with identification headers.

**Features**:
- Single header output: `X-CVM-Info: zone | ip | instance-id`
- Automatic detection via metadata service
- Load balancer friendly for backend identification
- Health check endpoint included

**Usage**:
```bash
sudo ./simple-id-cvm.sh
curl -I http://localhost/  # Test the header
```

**Use Cases**: Load balancer debugging, traffic analysis, instance monitoring

---

### 🔮 Coming Soon

- **CVM Batch Operations** - Scripts for managing multiple instances
- **CLB Configuration Tools** - Load balancer automation utilities  
- **VPC Network Utilities** - Network configuration and diagnostics
- **COS Management Scripts** - Object storage automation tools
- **Monitoring Integrations** - Custom metrics and alerting scripts
- **Security Automation** - Security group and access management tools

## 🚀 Quick Start

### Prerequisites

- Tencent Cloud account and CVM instances
- Appropriate permissions for the utilities you want to use
- Basic command-line knowledge

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/tc-utilities.git
   cd tc-utilities
   ```

2. **Make scripts executable**:
   ```bash
   chmod +x *.sh
   ```

3. **Run any utility**:
   ```bash
   # Example: CVM identifier
   sudo ./simple-id-cvm.sh
   ```

## 📋 Utility Details

### CVM Auto-Identifier

<details>
<summary><strong>Click to expand detailed documentation</strong></summary>

#### Output Format
Creates a single header: `X-CVM-Info: availability-zone | ip-address | instance-id`

**Example**: `X-CVM-Info: ap-singapore-1 | 10.0.0.100 | ins-abc123def`

#### How It Works
1. Queries Tencent Cloud metadata service
2. Retrieves availability zone, IP address, and instance ID  
3. Generates nginx configuration with identification header
4. Validates and deploys the configuration

#### Endpoints Created
| Endpoint | Purpose | Response |
|----------|---------|----------|
| `/` | Main endpoint | Plain text with CVM info |
| `/health` | Health check | Simple "OK" response |

#### Testing
```bash
# View headers
curl -I http://localhost/

# View response
curl http://localhost/

# Health check  
curl http://localhost/health

# Load balancer test
for i in {1..5}; do curl -s -I http://your-lb-url/ | grep X-CVM-Info; done
```

#### Requirements
- Tencent Cloud CVM instance
- nginx installed (`apt-get install nginx`)
- Root/sudo access

</details>

## 🔍 General Troubleshooting

### Common Issues Across Utilities

**Permission Denied**
```bash
# Most utilities require sudo/root access
sudo ./script-name.sh
```

**Dependencies Missing**
```bash
# Install common dependencies
sudo apt-get update
sudo apt-get install curl nginx jq
```

**Tencent Cloud Connectivity**
```bash
# Test metadata service (from CVM)
curl http://metadata.tencentyun.com/latest/meta-data/instance-id

# Test API connectivity
ping tencentcloudapi.com
```

### Logging and Debugging

Most utilities provide detailed logging with timestamps. Look for:
- `Starting...` - Script initialization
- `SUCCESS:` - Successful operations  
- `ERROR:` - Problems that need attention
- `WARNING:` - Non-critical issues

## 🔐 Security & Best Practices

### General Security
- **Principle of Least Privilege**: Only grant minimum required permissions
- **Review Scripts**: Always review scripts before running with sudo
- **Backup Configurations**: Backup important configs before modifications
- **Test in Development**: Test utilities in non-production environments first

### Tencent Cloud Security
- **CAM Roles**: Use CAM roles instead of hardcoded credentials when possible
- **Network Security**: Ensure proper security group configurations
- **Audit Logging**: Enable CloudAudit for API call tracking
- **Regular Updates**: Keep utilities updated with the latest versions

## 🚀 Integration Examples

### CI/CD Pipelines
```bash
# Example: Integrate CVM identifier in deployment pipeline
./simple-id-cvm.sh
# Verify deployment with header check
curl -s -I http://localhost/ | grep X-CVM-Info
```

### Monitoring & Alerting
```bash
# Example: Monitor utility execution
./utility-script.sh 2>&1 | tee -a /var/log/tc-utilities.log
```

### Load Balancer Integration
- Configure health checks to use utility-provided endpoints
- Parse custom headers for traffic analysis
- Implement zone-aware routing based on utility outputs

## 🛣️ Roadmap

### Upcoming Utilities

**Infrastructure Management**
- [ ] **CVM Batch Manager** - Start/stop/restart multiple instances
- [ ] **Auto-scaling Helper** - Custom scaling policies and triggers
- [ ] **Instance Health Checker** - Comprehensive health monitoring

**Network & Security**
- [ ] **VPC Subnet Calculator** - IP range planning and validation
- [ ] **Security Group Auditor** - Analyze and optimize security rules
- [ ] **Network Diagnostics** - Connectivity testing and troubleshooting

**Storage & Backup**
- [ ] **COS Sync Utility** - Efficient object storage synchronization
- [ ] **Snapshot Manager** - Automated backup scheduling and cleanup
- [ ] **Disk Usage Analyzer** - Storage optimization recommendations

**Monitoring & Logging** 
- [ ] **Custom Metrics Collector** - Application-specific monitoring
- [ ] **Log Aggregator** - Centralized logging setup
- [ ] **Alert Manager** - Custom alerting rules and notifications

**DevOps Integration**
- [ ] **CI/CD Helpers** - Deployment automation scripts
- [ ] **Configuration Templater** - Infrastructure as code utilities
- [ ] **Environment Manager** - Multi-environment deployment tools

## 🤝 Contributing

We welcome contributions! Here's how to get involved:

### Adding New Utilities

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b utility/new-feature`
3. **Follow naming convention**: `descriptive-name.sh`
4. **Add comprehensive comments** (see `simple-id-cvm.sh` as example)
5. **Update README.md** with utility documentation
6. **Update CHANGELOG.md** with your additions
7. **Test thoroughly** in your Tencent Cloud environment
8. **Submit a pull request**

### Contribution Guidelines

- **Code Style**: Follow existing script formatting and comment style
- **Documentation**: Include detailed comments and usage examples
- **Testing**: Test scripts in multiple scenarios before submitting
- **Security**: Never include hardcoded credentials or sensitive data
- **Compatibility**: Ensure scripts work across common Linux distributions

### Utility Requirements

Each utility should include:
- Clear purpose and use case description
- Comprehensive error handling and logging
- Fallback mechanisms where appropriate
- Usage examples and testing instructions
- Security considerations documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Getting Help

1. **Check Documentation**: Review utility-specific documentation above
2. **Common Issues**: Check the [Troubleshooting](#-general-troubleshooting) section
3. **Recent Changes**: Review [CHANGELOG.md](CHANGELOG.md) for updates
4. **Community Support**: Open a GitHub issue with detailed information

### Issue Reporting

When reporting issues, please include:
- **Utility Name**: Which script you're using
- **Environment**: CVM region, OS version, relevant software versions
- **Error Messages**: Complete error logs and output
- **Steps to Reproduce**: Clear steps to recreate the issue
- **Expected vs Actual**: What you expected vs what happened

### Feature Requests

We welcome feature requests! Please:
- Check existing issues to avoid duplicates
- Describe the use case and problem you're solving
- Provide examples of how the utility would be used
- Consider contributing the implementation yourself

## 📚 Additional Resources

### Tencent Cloud Documentation
- [CVM Documentation](https://cloud.tencent.com/document/product/213)
- [CLB Documentation](https://cloud.tencent.com/document/product/214)
- [VPC Documentation](https://cloud.tencent.com/document/product/215)
- [COS Documentation](https://cloud.tencent.com/document/product/436)
- [API Documentation](https://cloud.tencent.com/document/api)

### Tools & Resources
- [Tencent Cloud CLI](https://cloud.tencent.com/document/product/440)
- [Terraform Tencent Cloud Provider](https://registry.terraform.io/providers/tencentcloudstack/tencentcloud/latest)
- [Ansible Tencent Cloud Modules](https://docs.ansible.com/ansible/latest/collections/community/general/index.html)

---

**⭐ Star this repository if you find these utilities helpful!**

**🔔 Watch for updates** to get notified about new utilities and improvements.