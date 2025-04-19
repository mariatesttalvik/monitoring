# Prometheus Lab Part 1: Introduction and Setup

## Course Introduction and the Status of Prometheus

### Introduction
Welcome to the Prometheus Monitoring Lab! In this lab, you will learn how to set up and configure Prometheus, a powerful open-source monitoring and alerting toolkit. Prometheus has become the industry standard for monitoring cloud-native applications and microservices.

### Prometheus Origins
Prometheus was originally developed at SoundCloud in 2012 before becoming open source. It was inspired by Google's internal monitoring system called Borgmon.

## Setting up our Test Workspace

For this lab, we'll be using:
- Ubuntu Linux environment
- Docker and Docker Compose for containerization
- Visual Studio Code (optional) for editing configuration files

### Installing the Docker Engine

First, let's install Docker and Docker Compose:

```bash
# Download the Docker installation script
curl -fsSL https://get.docker.com -o install-docker.sh

# Verify the script content (optional but recommended)
cat install-docker.sh

# Run the installation script
sudo sh install-docker.sh

# Add your user to the docker group (to run Docker without sudo)
sudo usermod -aG docker ${USER}

# Apply the new group membership without logging out
newgrp docker
```

Install Docker Compose:

```bash
# Install Docker Compose
sudo curl -SL https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installations
docker --version
docker-compose --version
```

## Principles in Monitoring and How Prometheus Works

### The DevOps Lifecycle and Stages of Monitoring

In the DevOps lifecycle, monitoring plays a crucial role in ensuring the health and performance of systems. The key stages of monitoring include:

1. **Collection**: Gathering metrics from various sources
2. **Storage**: Storing metrics in time-series databases
3. **Analysis**: Analyzing metrics to identify patterns and anomalies
4. **Alerting**: Triggering alerts based on predefined conditions
5. **Visualization**: Displaying metrics in dashboards for better understanding

### Anti-Patterns to Avoid

- **"Cargo Culting"**: Blindly copying monitoring setups without understanding them
- **"Tool Obsession"**: Focusing too much on tools rather than the problems they solve
- **"Unnecessary Toil"**: Manually adding targets instead of using service discovery

### Design Patterns

- **Continual Improvement**: Regularly refine your monitoring setup
- **Composability**: Build a monitoring stack from independent components
- **The User Perspective**: Monitor what matters to users, not just system metrics
- **Buy or Build?**: Know when to use existing solutions vs. building custom ones

### The Relationship Between Logs and Metrics

Logs and metrics serve different purposes in monitoring:

- **Logs**: Detailed text records of events (high cardinality, low frequency)
- **Metrics**: Numerical measurements over time (low cardinality, high frequency)

Methods to connect logs and metrics:
1. Extracting metrics from logs
2. Adding context to metrics
3. Using distributed tracing
4. Correlating logs and metrics using timestamps

### Push vs Pull

Prometheus uses a **pull-based model**, where it scrapes metrics from monitored targets:

- **Pull Advantages**: Better control, detection of down targets, consistent collection intervals
- **Push Advantages**: Works for ephemeral jobs, can work through firewalls, scales more easily

### Breaking down the Data Shard Anatomy: Dimensional Data Model

Prometheus uses a dimensional data model where each time series is uniquely identified by:
- A **metric name** (what's being measured)
- A set of **key-value pairs** called **labels** (dimensions of the measurement)

For example: `http_requests_total{method="GET", endpoint="/api/users", status="200"}`

### A Closer Look at the Prometheus Server Architecture

Prometheus has a relatively simple architecture with these main components:

1. **Retrieval**: Pulls metrics from monitored targets
2. **Storage**: Time-series database (TSDB)
3. **HTTP Server**: Provides API and web interface
4. **PromQL Engine**: Evaluates queries
5. **Alertmanager**: Handles alert notifications

![Prometheus Architecture](images/image55.png)

## Installing and Setting up the Prometheus Server

### Running Prometheus in the Terminal

First, we'll run Prometheus directly in the terminal to understand its basic operation:

```bash
# Create a directory for our Prometheus project
mkdir -p prometheus-monitoring
cd prometheus-monitoring

# Create directories for our configuration
mkdir -p prometheus/config
```

Now, let's create a basic Prometheus configuration file:

```bash
# Create a basic prometheus.yml file
cat > prometheus/config/prometheus.yml << EOF
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF
```

Now, let's start Prometheus using Docker:

```bash
docker run -d --name prometheus \
  -p 9090:9090 \
  -v $(pwd)/prometheus/config:/etc/prometheus \
  prom/prometheus
```

Once Prometheus is running, you can access the web interface at http://localhost:9090

Check the different tabs: Alerts, Graph, Status

Run your first query by typing "up" in the query box and clicking "Execute". You should see a result like:

`up{instance="localhost:9090", job="prometheus"}`

This confirms that Prometheus is monitoring itself.

### Overview of the Prometheus Service Package

Prometheus includes several components:
- `console_libraries`: Libraries for web consoles
- `consoles`: Web console templates
- `data`: Where time-series data is stored
- `prometheus`: The main binary
- `prometheus.yml`: Configuration file
- `promtool`: Utility tool

### Running the Node Exporter

Now, let's add the Node Exporter to monitor system metrics:

```bash
# Run Node Exporter
docker run -d --name nodeexporter \
  -p 9100:9100 \
  -v "/proc:/host/proc:ro" \
  -v "/sys:/host/sys:ro" \
  -v "/:/rootfs:ro" \
  --net="host" \
  prom/node-exporter \
  --path.procfs=/host/proc \
  --path.sysfs=/host/sys
```

Let's update our Prometheus configuration to monitor Node Exporter:

```bash
# Update the prometheus.yml file
cat > prometheus/config/prometheus.yml << EOF
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Restart Prometheus to apply the new configuration
docker restart prometheus
```

Now, you can query Node Exporter metrics in Prometheus, such as:
- `rate(node_cpu_seconds_total[5m])`: CPU usage rate
- `node_uname_info`: System information

### The Prometheus Metrics Format

Access the raw metrics by visiting:
- Prometheus metrics: http://localhost:9090/metrics
- Node Exporter metrics: http://localhost:9100/metrics

You'll see different types of metrics:
- Gauge: Values that can go up and down (e.g., memory usage)
- Counter: Values that only increase (e.g., total requests)
- Histogram: Observations bucketed by value ranges (e.g., request durations)

### Installing Prometheus as a Docker Service

Let's set up a more complete monitoring stack using Docker Compose:

```bash
# Create a directory for Docker Compose
mkdir -p docker-compose/prometheus
cd docker-compose/prometheus
```

Create a `docker-compose.yml` file:

```yaml
version: '3.7'

volumes:
  data: {}

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./config:/etc/prometheus
      - data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.enable-lifecycle'
      - '--storage.tsdb.retention.time=7d'
    ports:
      - "9090:9090"
    restart: unless-stopped

  nodeexporter:
    image: prom/node-exporter
    container_name: nodeexporter
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
      - /tmp:/tmp:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc|rootfs/var/lib/docker/containers|rootfs/var/lib/docker/overlay2|rootfs/run/docker/netns|rootfs/var/lib/docker/aufs)($$|/)'
    ports:
      - "9100:9100"
    restart: unless-stopped
```

Create a config directory and prometheus.yml file:

```bash
# Create config directory
mkdir -p config

# Create prometheus.yml
cat > config/prometheus.yml << EOF
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'node'
    static_configs:
      - targets: ['nodeexporter:9100']
EOF
```

Start the Docker Compose stack:

```bash
docker-compose up -d
```

Check if the services are running:

```bash
docker-compose ps
```

You should see both Prometheus and Node Exporter running.

![Prometheus services](images/image59.png)