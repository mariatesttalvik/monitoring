# Monitoring Lab Manual - Part 1: Installation and Environment Setup

## Introduction

This manual guides you through setting up a complete monitoring environment using Docker containers with Zabbix, Grafana, and Loki. By the end of Part 1, you will have a functioning environment ready for configuration in subsequent parts of the lab.

**Time allocation:** 45 minutes total
- Docker Environment Preparation: 15 minutes
- Certificate Generation: 10 minutes
- Container Deployment: 20 minutes

---

## 1. Docker Environment Preparation (15 min)

### 1.1 Update System Packages

First, ensure your system has the latest package information and install necessary dependencies:

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
```

**Explanation:** 
- `apt-get update` refreshes the package index files so your system knows about the latest available packages
- The installed packages allow secure HTTPS connections and provide tools needed for Docker installation

### 1.2 Install Docker and Docker Compose

Next, install Docker and Docker Compose to run our containerized monitoring services:

```bash
# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add the Docker repository to APT sources
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update package database with Docker packages from the new repository
sudo apt-get update

# Install Docker and Docker Compose
sudo apt-get install -y docker-ce docker-compose

# Add your user to the docker group to run Docker without sudo
sudo usermod -aG docker $USER
```

**Explanation:**
- We add Docker's GPG key to verify package integrity
- We add the official Docker repository to your APT sources
- We install Docker CE (Community Edition) and Docker Compose
- Adding your user to the docker group allows you to run Docker commands without sudo

**Important:** After running these commands, you need to log out and log back in for the group changes to take effect. Alternatively, you can run:

```bash
newgrp docker
```

To verify Docker is installed correctly, run:

```bash
docker --version
docker-compose --version
```

You should see version information for both commands, indicating successful installation.

### 1.3 Create Directory Structure

Create an organized directory structure for your monitoring lab:

```bash
mkdir -p monitoring-lab/{certs,zabbix,grafana,data,web-app}
cd monitoring-lab
```

**Explanation:**
- We create a main directory called `monitoring-lab`
- Inside it, we create subdirectories for:
  - `certs`: Will store SSL certificates
  - `zabbix`: Configuration files for Zabbix
  - `grafana`: Configuration files for Grafana
  - `data`: Persistent data storage
  - `web-app`: Sample web application to monitor

---

## 2. Certificate Generation (10 min)

To secure your monitoring services, you'll generate self-signed SSL certificates:

### 2.1 Generate Root CA Certificate

```bash
cd certs
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 -out ca.crt -subj "/CN=Monitoring Lab CA"
```

**Explanation:**
- We generate a 4096-bit RSA private key for our Certificate Authority (CA)
- We create a self-signed CA certificate valid for 365 days
- The subject is set to "Monitoring Lab CA" for easy identification

### 2.2 Generate Certificates for Services

Now, create certificates for Zabbix and Grafana:

#### Zabbix Server Certificate:

```bash
# Generate private key
openssl genrsa -out zabbix-server.key 2048

# Generate Certificate Signing Request (CSR)
openssl req -new -key zabbix-server.key -out zabbix-server.csr -subj "/CN=zabbix-server"

# Sign CSR with our CA to generate certificate
openssl x509 -req -in zabbix-server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out zabbix-server.crt -days 365 -sha256
```

#### Zabbix Agent Certificate:

```bash
# Generate private key
openssl genrsa -out zabbix-agent.key 2048

# Generate Certificate Signing Request (CSR)
openssl req -new -key zabbix-agent.key -out zabbix-agent.csr -subj "/CN=zabbix-agent"

# Sign CSR with our CA to generate certificate
openssl x509 -req -in zabbix-agent.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out zabbix-agent.crt -days 365 -sha256
```

#### Grafana Certificate:

```bash
# Generate private key
openssl genrsa -out grafana.key 2048

# Generate Certificate Signing Request (CSR)
openssl req -new -key grafana.key -out grafana.csr -subj "/CN=grafana"

# Sign CSR with our CA to generate certificate
openssl x509 -req -in grafana.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out grafana.crt -days 365 -sha256
```

**Explanation:**
- For each service, we:
  1. Generate a 2048-bit RSA private key
  2. Create a Certificate Signing Request (CSR) with the service name as the Common Name (CN)
  3. Sign the CSR with our CA to create a trusted certificate valid for 365 days

**Note:** In a production environment, you would use certificates from a trusted CA. These self-signed certificates are suitable for lab purposes only.

### 2.3 Set Appropriate Permissions

```bash
# Set read-only permissions for certificates
chmod 644 *.crt ca.crt
# Set strict permissions for private keys
chmod 600 *.key ca.key
# Return to main directory
cd ..
```

**Explanation:**
- We set appropriate permissions to protect the private keys while allowing services to read the certificates

---

## 3. Container Deployment (20 min)

### 3.1 Create Docker Compose File

Create a `docker-compose.yml` file in the main directory:

```bash
nano docker-compose.yml
```

Copy and paste the following content:

```yaml
version: '3.8'

services:
  # MySQL for Zabbix
  zabbix-mysql:
    image: mysql:8.0
    container_name: zabbix-mysql
    command: ['mysqld', '--character-set-server=utf8', '--collation-server=utf8_bin', '--default-authentication-plugin=mysql_native_password']
    environment:
      MYSQL_ROOT_PASSWORD: zabbix_pwd
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbix_pwd
    volumes:
      - ./data/mysql:/var/lib/mysql
    restart: unless-stopped
    networks:
      - monitoring-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "zabbix", "-pzabbix_pwd"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  # Zabbix Server
  zabbix-server:
    image: zabbix/zabbix-server-mysql:ubuntu-7.0-latest
    container_name: zabbix-server
    depends_on:
      zabbix-mysql:
        condition: service_healthy
    environment:
      DB_SERVER_HOST: zabbix-mysql
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbix_pwd
      MYSQL_ROOT_PASSWORD: zabbix_pwd
      ZBX_TIMEOUT: 30
    volumes:
      - ./zabbix/alertscripts:/usr/lib/zabbix/alertscripts
      - ./zabbix/externalscripts:/usr/lib/zabbix/externalscripts
      - ./certs/zabbix-server.crt:/etc/ssl/certs/zabbix-server.crt:ro
      - ./certs/zabbix-server.key:/etc/ssl/private/zabbix-server.key:ro
      - ./certs/ca.crt:/etc/ssl/certs/ca.crt:ro
    restart: unless-stopped
    ports:
      - "10051:10051"
    networks:
      - monitoring-network

  # Zabbix Web Interface
  zabbix-web:
    image: zabbix/zabbix-web-nginx-mysql:ubuntu-7.0-latest
    container_name: zabbix-web
    depends_on:
      zabbix-mysql:
        condition: service_healthy
      zabbix-server:
        condition: service_started
    environment:
      DB_SERVER_HOST: zabbix-mysql
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbix_pwd
      ZBX_SERVER_HOST: zabbix-server
      PHP_TZ: Europe/London
    volumes:
      - ./certs/zabbix-server.crt:/etc/ssl/certs/zabbix-server.crt:ro
      - ./certs/zabbix-server.key:/etc/ssl/private/zabbix-server.key:ro
    ports:
      - "8443:8443"
    restart: unless-stopped
    networks:
      - monitoring-network

  # Zabbix Agent
  zabbix-agent:
    image: zabbix/zabbix-agent2:ubuntu-7.0-latest
    container_name: zabbix-agent
    privileged: true
    depends_on:
      - zabbix-server
    environment:
      ZBX_SERVER_HOST: zabbix-server
      ZBX_HOSTNAME: zabbix-agent
      ZBX_SERVER_TLS_PSK_IDENTITY: PSK 001
      ZBX_SERVER_TLS_PSK_FILE: /etc/zabbix/zabbix_agentd.psk
    volumes:
      - ./zabbix/agent.conf:/etc/zabbix/zabbix_agent2.d/zabbix_agent2.conf:ro
      - ./certs/zabbix-agent.crt:/etc/ssl/certs/zabbix-agent.crt:ro
      - ./certs/zabbix-agent.key:/etc/ssl/private/zabbix-agent.key:ro
      - ./certs/ca.crt:/etc/ssl/certs/ca.crt:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /:/hostfs:ro
    restart: unless-stopped
    networks:
      - monitoring-network

  # Grafana
  grafana:
    image: grafana/grafana:9.3.6
    container_name: grafana
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
      GF_INSTALL_PLUGINS: alexanderzobnin-zabbix-app,marcusolsson-treemap-panel
    volumes:
      - ./grafana/data:/var/lib/grafana
      - ./certs/grafana.crt:/etc/grafana/grafana.crt:ro
      - ./certs/grafana.key:/etc/grafana/grafana.key:ro
    ports:
      - "3000:3000"
    restart: unless-stopped
    networks:
      - monitoring-network

  # MySQL (as a service to monitor)
  mysql-service:
    image: mysql:8.0
    container_name: mysql-service
    command: ['mysqld', '--character-set-server=utf8', '--collation-server=utf8_bin', '--default-authentication-plugin=mysql_native_password']
    environment:
      MYSQL_ROOT_PASSWORD: mysql_pwd
      MYSQL_DATABASE: testdb
      MYSQL_USER: testuser
      MYSQL_PASSWORD: test_pwd
    volumes:
      - ./data/mysql-service:/var/lib/mysql
    restart: unless-stopped
    ports:
      - "3306:3306"
    networks:
      - monitoring-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "testuser", "-ptest_pwd"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  # Sample Web Application to monitor
  web-app:
    image: nginx:alpine
    container_name: web-app
    volumes:
      - ./web-app:/usr/share/nginx/html
    ports:
      - "8080:80"
    restart: unless-stopped
    networks:
      - monitoring-network

  # Loki for log aggregation
  loki:
    image: grafana/loki:2.7.3
    container_name: loki
    command: -config.file=/etc/loki/local-config.yaml
    ports:
      - "3100:3100"
    restart: unless-stopped
    networks:
      - monitoring-network

  # Promtail for log collection
  promtail:
    image: grafana/promtail:2.7.3
    container_name: promtail
    volumes:
      - /var/log:/var/log
      - ./data/promtail:/etc/promtail
    command: -config.file=/etc/promtail/config.yml
    depends_on:
      - loki
    restart: unless-stopped
    networks:
      - monitoring-network

networks:
  monitoring-network:
    driver: bridge
```

Save the file by pressing `Ctrl+X`, then `Y`, then `Enter`.

**Explanation:**
- This Docker Compose file defines all the containers needed for our monitoring lab
- Key points:
  - Services are interconnected through a custom bridge network named `monitoring-network`
  - Volumes map our local directories to container directories for persistence
  - SSL certificates are mounted in read-only mode to secure the services
  - Ports are exposed to make services accessible from your host machine

### 3.2 Create Configuration Files and Initialize Databases

Before starting the containers, create the necessary configuration files and database initialization scripts:

#### Zabbix Agent Configuration:

```bash
mkdir -p zabbix
nano zabbix/agent.conf
```

Paste the following content:

```conf
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

Save the file by pressing `Ctrl+X`, then `Y`, then `Enter`.

#### Promtail Configuration:

```bash
mkdir -p data/promtail
nano data/promtail/config.yml
```

Paste the following content:

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

Save the file by pressing `Ctrl+X`, then `Y`, then `Enter`.

#### Note on Database Management:

As a learning exercise, we'll manually connect to and configure the database after container startup. This hands-on approach will help you understand database management in a monitoring environment.

#### Create a Sample Web Page:

```bash
mkdir -p web-app
nano web-app/index.html
```

Paste the following content:

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
            document.getElementById('server-time').textContent = new Date().toLocaleString();
        }
        updateTime();
        setInterval(updateTime, 1000);
    </script>
</body>
</html>
```

Save the file by pressing `Ctrl+X`, then `Y`, then `Enter`.

### 3.3 Start the Containers

Now, start all the containers defined in the Docker Compose file:

```bash
docker-compose up -d
```

**Explanation:**
- `up` tells Docker Compose to create and start the containers
- `-d` runs the containers in detached mode (background)

This process may take several minutes as Docker downloads the required images.

### 3.4 Verify Services are Running

Check that all services are running correctly:

```bash
docker-compose ps
```

You should see all containers listed with a status of "Up" or "(healthy)". If any container shows a different status, check its logs:

Specifically, verify that the MySQL databases are healthy:

```bash
docker-compose ps zabbix-mysql mysql-service
```

The output should show both databases as "(healthy)" which means they've passed the health checks we defined.

```bash
docker-compose logs <container-name>
```

For example, to check the Zabbix server logs:

```bash
docker-compose logs zabbix-server
```

If you need to troubleshoot a specific container, you can access its shell:

```bash
docker-compose exec <container-name> bash
```

For example:

```bash
docker-compose exec zabbix-agent bash
```

### 3.5 Manually Configure the Database for Monitoring

Now that our containers are running, let's manually set up the database that we'll be monitoring. This hands-on approach will help you better understand database configuration for monitoring environments.

1. **Connect to the MySQL service container**:
   ```bash
   docker-compose exec mysql-service mysql -u root -pmysql_pwd
   ```

2. **Create a test table for monitoring**:
   ```sql
   USE testdb;
   
   CREATE TABLE test_data (
     id INT AUTO_INCREMENT PRIMARY KEY,
     name VARCHAR(100) NOT NULL,
     value DECIMAL(10,2) NOT NULL,
     timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   ```

3. **Insert sample data for monitoring**:
   ```sql
   INSERT INTO test_data (name, value) VALUES 
     ('Server CPU', 45.5),
     ('Server Memory', 78.2),
     ('Database Connections', 125),
     ('Active Users', 1250),
     ('Response Time', 0.85);
   ```

4. **Create a dedicated monitoring user** (good security practice):
   ```sql
   CREATE USER 'monitor'@'%' IDENTIFIED BY 'monitor_pwd';
   GRANT SELECT, PROCESS, SHOW DATABASES, REPLICATION CLIENT ON *.* TO 'monitor'@'%';
   FLUSH PRIVILEGES;
   ```

5. **Verify your setup**:
   ```sql
   SELECT * FROM test_data;
   SHOW GRANTS FOR 'monitor'@'%';
   ```

6. **Exit MySQL**:
   ```sql
   EXIT;
   ```

**Learning Point**: By manually setting up the database, you gain experience in:
- Creating appropriate tables for monitoring
- Setting up appropriate security and permissions
- Understanding what data will be monitored
- Database user management best practices for monitoring

### 3.6 Access Web Interfaces

Once all services are running, you can access them through your web browser:

1. **Zabbix Web Interface**: https://your-server-ip:8443
   - Username: Admin
   - Password: zabbix

2. **Grafana Web Interface**: http://your-server-ip:3000
   - Username: admin
   - Password: admin

3. **Sample Web Application**: http://your-server-ip:8080

**Note:** Since we're using self-signed certificates, your browser will show a security warning. For this lab, you can safely proceed by accepting the risk.

---

## Troubleshooting Tips

### Docker Issues
- If `docker-compose up -d` fails with "permission denied", make sure you've logged out and back in after adding your user to the docker group.
- If containers are not starting or exiting with errors, check their logs with `docker-compose logs <container-name>`.

### Certificate Issues
- If services fail due to certificate issues, verify that certificates are correctly mounted and have proper permissions.

### Networking Issues
- If containers can't communicate, ensure they're all on the same `monitoring-network`.
- If you can't access web interfaces, check your firewall settings.

### Volume Permissions
- If services complain about permissions for mounted volumes, use `chmod` and `chown` to set the correct permissions.

---

## Conclusion

You have now completed Part 1 of the Monitoring Lab. You have:
- Set up Docker and Docker Compose
- Generated SSL certificates for secure communication
- Configured and deployed all the necessary services

In Part 2, you will configure Zabbix for basic monitoring of your environment.
