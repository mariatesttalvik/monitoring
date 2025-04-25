# 🚀 Part 1: Basic Manual Setup

## Overview

This guide walks you through creating a complete monitoring environment using Docker containers with Zabbix, Grafana, and Loki. You'll establish a self-contained environment for learning modern monitoring practices with secure communications between components.

**Estimated Time:** 45 minutes
- Environment Preparation: 15 minutes
- Certificate Generation: 10 minutes
- Container Deployment: 20 minutes

> **Additional Resources:** 
> - [Zabbix 6.0 Quick Installation Guide](https://www.initmax.com/wiki/zabbix-6-0-instructions-for-installation-in-5-minutes/)

## Environment Preparation

### System Updates and Prerequisites

First, update your system and install the necessary prerequisites:

```bash
# Update package repositories
sudo apt-get update

# Install Docker dependencies
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
```

### Docker Installation

Add Docker's repository and install Docker with Docker Compose:

```bash
# Add Docker's GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add Docker repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update package database
sudo apt-get update

# Install Docker and Docker Compose
sudo apt-get install -y docker-ce docker-compose

# Add your user to the docker group
sudo usermod -aG docker $USER

# Apply group membership
newgrp docker
```

### Verify Installation

Confirm Docker is properly installed:

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker-compose --version
```

### Directory Structure

Create the directory structure for the monitoring environment:

```bash
# Create main project directory
mkdir -p monitoring-lab

# Create subdirectories
mkdir -p monitoring-lab/certs
mkdir -p monitoring-lab/data/{mysql,mysql-service,promtail}
mkdir -p monitoring-lab/grafana/data
mkdir -p monitoring-lab/web-app
mkdir -p monitoring-lab/zabbix/{alertscripts,externalscripts}

# Navigate to project directory
cd monitoring-lab
```

Your project structure will look like this:

```
monitoring-lab/
├── certs/                  # SSL certificates
│   ├── ca.crt
│   ├── grafana.crt
│   ├── grafana.key
│   ├── zabbix-agent.crt
│   ├── zabbix-agent.key
│   ├── zabbix-server.crt
│   └── zabbix-server.key
├── data/
│   ├── mysql/              # Zabbix MySQL data
│   ├── mysql-service/      # Separate MySQL service data
│   └── promtail/
│       └── config.yml      # Promtail configuration
├── grafana/
│   └── data/               # Grafana persistent data
├── web-app/                # NGINX web app files
└── zabbix/
    ├── agent.conf          # Zabbix agent configuration
    ├── alertscripts/       # Zabbix alert scripts
    └── externalscripts/    # Zabbix external scripts
```

## Certificate Generation

Generate self-signed certificates for secure communications between components:

### Certificate Authority

```bash
# Navigate to certs directory
cd certs

# Generate CA private key
openssl genrsa -out ca.key 4096

# Generate self-signed CA certificate
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 -out ca.crt -subj "/CN=Monitoring Lab CA"
```

### Zabbix Server Certificate

```bash
# Generate Zabbix server private key
openssl genrsa -out zabbix-server.key 2048

# Create certificate signing request
openssl req -new -key zabbix-server.key -out zabbix-server.csr -subj "/CN=zabbix-server"

# Sign the certificate with your CA
openssl x509 -req -in zabbix-server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out zabbix-server.crt -days 365 -sha256
```

### Zabbix Agent Certificate

```bash
# Generate Zabbix agent private key
openssl genrsa -out zabbix-agent.key 2048

# Create certificate signing request
openssl req -new -key zabbix-agent.key -out zabbix-agent.csr -subj "/CN=zabbix-agent"

# Sign the certificate with your CA
openssl x509 -req -in zabbix-agent.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out zabbix-agent.crt -days 365 -sha256
```

### Grafana Certificate

```bash
# Generate Grafana private key
openssl genrsa -out grafana.key 2048

# Create certificate signing request
openssl req -new -key grafana.key -out grafana.csr -subj "/CN=grafana"

# Sign the certificate with your CA
openssl x509 -req -in grafana.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out grafana.crt -days 365 -sha256
```

### Certificate Permissions

```bash
# Set certificate permissions
chmod 644 *.crt ca.crt

# Set private key permissions
chmod 600 *.key ca.key

# Return to main directory
cd ..
```

## Configuration Files

### Zabbix Agent Configuration

Create a configuration file for the Zabbix agent:

```bash
# Create and edit Zabbix agent config file
nano zabbix/agent.conf
```

Paste the following configuration:

```
# Zabbix Agent 2 configuration
Server=zabbix-server
ServerActive=zabbix-server
Hostname=zabbix-agent

# TLS parameters
TLSConnect=cert
TLSAccept=cert
TLSCAFile=/etc/ssl/certs/ca.crt
TLSCertFile=/etc/ssl/certs/zabbix-agent.crt
TLSKeyFile=/etc/ssl/private/zabbix-agent.key

# Enable remote commands
EnableRemoteCommands=1
LogRemoteCommands=1

# Enable Docker monitoring
Plugins.Docker.Endpoint=unix:///var/run/docker.sock

# Monitor host filesystem
HostMetadata=linux
HostInterface=0.0.0.0
```

### Promtail Configuration

Create a configuration file for Promtail (log collector):

```bash
# Create and edit Promtail config file
nano data/promtail/config.yml
```

Paste the following configuration:

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /etc/promtail/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*.log

  - job_name: docker
    static_configs:
      - targets:
          - localhost
        labels:
          job: docker
          __path__: /var/lib/docker/containers/*/*.log
```

### Sample Web Application

Create a sample web page to monitor:

```bash
# Create and edit sample web page
nano web-app/index.html
```

Paste the following HTML:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Monitoring Lab Sample Web App</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            line-height: 1.6;
        }
        h1 {
            color: #333;
        }
        .status {
            padding: 20px;
            background-color: #f9f9f9;
            border-radius: 5px;
            border: 1px solid #ddd;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h1>Monitoring Lab Sample Web Application</h1>
    <p>This is a sample web application for monitoring with Zabbix.</p>
    <div class="status">
        <h2>Server Status</h2>
        <p>Server Time: <span id="server-time"></span></p>
        <p>Status: <span style="color: green; font-weight: bold;">ONLINE</span></p>
    </div>
    <script>
        function updateTime() {
            document.getElementById("server-time").textContent = new Date().toLocaleString();
        }
        updateTime();
        setInterval(updateTime, 1000);
    </script>
</body>
</html>
```

### Set Permissions

Set appropriate permissions for Grafana data and verify your certificates:

```bash
# Set Grafana data directory permissions
sudo chown -R 472:472 grafana/data

# Verify SSL certificates
ls -la certs/
chmod 644 certs/*.crt
chmod 600 certs/*.key
```

## Docker Compose Configuration

Create a Docker Compose file to define all services:

```bash
# Create docker-compose.yml
nano docker-compose.yml
```

> For Docker Compose configuration, see the separate docker-compose.yml file in your project repository.

## Deployment and Verification

### Start Services

Launch all the containers:

```bash
# Start all containers
docker-compose up -d
```

This process may take several minutes as Docker downloads the necessary images.

### Verify Deployment

Check that all services are running:

```bash
# Check container status
docker-compose ps
```

If any container shows a status other than "Up" or "(healthy)", check its logs:

```bash
# Check logs of a specific container
docker-compose logs [container-name]
```

## Database Configuration

Set up a test database for monitoring:

```bash
# Configure the test database
docker-compose exec mysql-service mysql -u root -pmysql_pwd -e "
USE testdb;

CREATE TABLE test_data (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  value DECIMAL(10,2) NOT NULL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO test_data (name, value) VALUES 
  ('Server CPU', 45.5),
  ('Server Memory', 78.2),
  ('Database Connections', 125),
  ('Active Users', 1250),
  ('Response Time', 0.85);

CREATE USER 'monitor'@'%' IDENTIFIED BY 'monitor_pwd';
GRANT SELECT, PROCESS, SHOW DATABASES, REPLICATION CLIENT ON *.* TO 'monitor'@'%';
FLUSH PRIVILEGES;"
```

> **Note:** Replace `mysql_pwd` and `monitor_pwd` with secure passwords.

## Accessing Services

Access your monitoring services through a web browser:

- **Zabbix Web Interface**
  - URL: `https://your-server-ip:8443`
  - Username: `Admin`
  - Password: `zabbix`

- **Grafana Web Interface**
  - URL: `http://your-server-ip:3000`
  - Username: `admin`
  - Password: `admin`

- **Sample Web Application**
  - URL: `http://your-server-ip:8080`

> **Note:** Since you're using self-signed certificates, your browser will show a security warning. For this lab environment, you can safely proceed by accepting the risk.

## Architecture Overview

The monitoring environment consists of several interconnected components:

1. **Zabbix Server**: Central monitoring system that collects and processes metrics
2. **Zabbix Agent**: Collects local system metrics from monitored hosts
3. **Grafana**: Visualization platform for metrics and dashboards
4. **Loki**: Log aggregation system that collects and indexes logs
5. **Promtail**: Log collection agent that forwards logs to Loki
6. **MySQL**: Database storage for Zabbix and service metrics

The components are secured using self-signed certificates and communicate over an isolated Docker network.

## Troubleshooting

If you encounter issues during setup:

```bash
# If Docker gives permission errors
newgrp docker

# Check container logs
docker-compose logs [container-name]

# Access a container's shell
docker-compose exec [container-name] bash

# Fix volume permissions if needed
sudo chown -R 1000:1000 ./data
sudo chmod -R 755 ./data
```

## Advanced Configuration

After completing the basic setup, consider these advanced configurations:

- Create custom Zabbix triggers and notifications
- Build Grafana dashboards to visualize metrics
- Configure alert thresholds for key metrics
- Add additional services to monitor
- Set up notification channels (email, Slack, etc.)