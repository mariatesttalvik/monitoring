# Prometheus Lab Part 4: Service Discovery, Pushing Metrics, and Labeling

## Pushing Metrics to Prometheus

### The Push Gateway

The Prometheus Pushgateway allows you to push metrics to Prometheus from batch jobs or from systems that cannot be scraped. Let's add the Push Gateway to our monitoring stack:

```bash
# Add Push Gateway to our docker-compose.yml
cat >> docker-compose/prometheus/docker-compose.yml << EOF

  pushgateway:
    image: prom/pushgateway:v1.1.0
    container_name: pushgateway
    restart: unless-stopped
    ports:
      - "9091:9091"
EOF

# Start the Push Gateway
cd docker-compose/prometheus/
docker-compose up -d
```

![Push Gateway Architecture](images/image8.png)

Now, let's add the Push Gateway to our Prometheus configuration:

```bash
# Edit the Prometheus configuration
cat >> prom-config << EOF

  - job_name: 'push-gateway'
    honor_labels: true
    static_configs:
      - targets:
        - localhost:9091
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

Let's create a script to push metrics to the Push Gateway:

```bash
# Create a directory for Push Gateway scripts
mkdir -p instrumentation/push-gw

# Create a Python script to push metrics
cat > instrumentation/push-gw/push_register.py << EOF
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
registry = CollectorRegistry()
g = Gauge('mktemp_last_success_unixtime', 'Last time a batch job successfully finished', registry=registry)
g.set_to_current_time()
push_to_gateway('localhost:9091', job='mkTemp', registry=registry)
EOF
```

We can also push metrics manually using curl:

```bash
# Push a metric to the Push Gateway
echo "mktemp_last_success_unixtime $(date +%s)" | curl --data-binary @- http://localhost:9091/metrics/job/mkTemp
```

Let's also create a cron job that pushes metrics:

```bash
# Edit the crontab
crontab -e

# Add this line to run our script every 30 minutes
*/30 * * * * /bin/mktemp /tmp/push-XXXX && /usr/bin/python3 /home/$(whoami)/instrumentation/push-gw/push_register.py > /dev/null 2>&1
```

For more immediate testing, we can run a more explicit curl command:

```bash
echo -e "# TYPE mktemp_last_success_unixtime gauge\nmktemp_last_success_unixtime $(date +%s)" | curl --data-binary @- http://localhost:9091/metrics/job/mkTemp
```

![Push Gateway UI](images/image9.png)

Now we can query the metric in Prometheus:

```
mktemp_last_success_unixtime
```

![Push Gateway Metrics](images/image10.png)

### The Textfile Collector

The Node Exporter includes a textfile collector that can read metrics from text files in a directory. This allows you to expose metrics from scripts and other sources.

Let's update our Node Exporter configuration to enable the textfile collector:

```bash
# Edit the docker-compose.yml to add the textfile collector to Node Exporter
cat > docker-compose/prometheus/docker-compose.yml << EOF
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
      - '--collector.textfile.directory=/tmp'
    ports:
      - "9100:9100"
    restart: unless-stopped
EOF

# Restart the Node Exporter
cd docker-compose/prometheus/
docker-compose up -d nodeexporter
```

![Textfile Collector](images/image11.png)

Now, let's create a script that writes metrics to a file for the textfile collector:

```bash
# Create a script for the textfile collector
cat > instrumentation/file_counter.sh << EOF
#!/bin/bash

DIR=/tmp
RESULT=\$(ls \${DIR}/push-???? | wc -l)
END="\$(date +%s)"

cat <<END_OF_FILE > "\$DIR/pushfiles.prom.\$\$"
node_pushfiles_total \$RESULT
node_pushfiles_last_run_seconds \$END
END_OF_FILE

mv "\$DIR/pushfiles.prom.\$\$" "\$DIR/pushfiles.prom"
EOF

# Make the script executable
chmod 755 instrumentation/file_counter.sh

# Run the script
./instrumentation/file_counter.sh
```

![Textfile Collector Output](images/image12.png)

We can add this script to cron to run periodically:

```bash
# Edit the crontab
crontab -e

# Add this line to run our script every 30 minutes
*/30 * * * * /home/$(whoami)/instrumentation/file_counter.sh
```

Now we can query the metrics in Prometheus:

```
node_pushfiles_total
node_pushfiles_last_run_seconds
```

## Service Discovery Techniques

Service discovery helps Prometheus identify targets to monitor. Instead of statically configuring targets, service discovery allows for dynamic discovery of targets.

![Service Discovery](images/image13.png)

There are two main methods of service discovery:
1. **Top-Down**: A central system knows what services are running (e.g., EC2, Kubernetes)
2. **Bottom-Up**: Services register themselves with a registry (e.g., Consul)

### File-based Service Discovery

Let's implement file-based service discovery for our Push Gateway:

```bash
# Create a directory for service discovery files
mkdir -p docker-compose/prometheus/config/file-sd

# Create a JSON file for the Push Gateway
cat > docker-compose/prometheus/config/file-sd/push-gw.json << EOF
[
  {
    "targets": ["localhost:9091"],
    "labels": {
      "city": "tallinn"
    }
  }
]
EOF
```

Now, let's update our Prometheus configuration to use file-based service discovery:

```bash
# Edit the Prometheus configuration to use file-based service discovery
cat > prom-config << EOF
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
  
  - job_name: 'my_app'
    static_configs:
      - targets: ['localhost:5000']
  
  - job_name: 'docker-engine'
    static_configs:
      - targets: ['localhost:9323']
  
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
  
  - job_name: 'blackbox'
    static_configs:
      - targets: ['localhost:9115']
  
  - job_name: 'blackbox_targets'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - https://prometheus.io
        - https://grafana.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: localhost:9115
  
  - job_name: 'push-gateway'
    honor_labels: true
    file_sd_configs:
      - files:
        - file-sd/push-gw.json
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

![File-based Service Discovery](images/image15.png)

## Labeling

Labeling is a crucial aspect of Prometheus, allowing you to organize and filter your metrics.

![Labeling](images/image1.png)

Target source labels are labels that Prometheus automatically picks up from your targets. Special metadata labels, such as `__address__`, are used for internal purposes.

### Dropping Targets Based on Labels

You can use `relabel_configs` to drop or keep targets based on labels:

```yaml
relabel_configs:
  - source_labels: [team]
    regex: raptors
    action: drop
```

This would drop all targets with the label `team=raptors`.

### Keeping Specific Targets

Similarly, you can keep only specific targets:

```yaml
relabel_configs:
  - source_labels: [team]
    regex: raptors
    action: keep
```

This would keep only targets with the label `team=raptors`.

### External Labels

External labels provide a way to identify your Prometheus server, especially in multi-region or high availability setups:

```yaml
global:
  external_labels:
    region: "us-west"
    dc: "datacenter-1"
```

![External Labels](images/image2.png)

### Configuring Relabeling for Blackbox Exporter

We've already used relabeling in our Blackbox Exporter configuration:

```yaml
relabel_configs:
  - source_labels: [__address__]
    target_label: __param_target
  - source_labels: [__param_target]
    target_label: instance
  - target_label: __address__
    replacement: localhost:9115
```

This configuration:
1. Takes the original address and sets it as the `target` parameter
2. Sets the original address as the `instance` label
3. Sets the actual address to the Blackbox Exporter

### Understanding Metadata Labels

In Prometheus, metadata labels (often coming from external sources like EC2) are automatically discovered during service discovery. To fully utilize them, you sometimes need to convert or rename these labels.

#### Example 1: Renaming the EC2 Instance ID Label

If you wanted to capture and rename the instance ID for EC2 nodes, you could use this configuration:

```yaml
relabel_configs:
  - source_labels: ['__meta_ec2_instance_id']
    regex: (.*)
    target_label: 'ID'
```

This takes the `__meta_ec2_instance_id` metadata label, captures its value, and assigns it to a new label called `ID`.

#### Example 2: Capturing the EC2 State Label

Here's a simplified version to capture the state metadata label from EC2:

```yaml
relabel_configs:
  - source_labels: ['__meta_ec2_instance_state']
    target_label: 'state'
```

This automatically captures the EC2 state and assigns it to a label named `state`.

#### Example 3: Cleaning Up the Environment Label

If you have a label like `environment: "env-staging-junk"` but only want to keep "staging", you can use:

```yaml
relabel_configs:
  - source_labels: ['environment']
    regex: 'env-(.*?)-junk'
    target_label: 'environment'
    replacement: '$1'
```

This takes the environment label, captures the middle part (staging), and assigns it to the environment label.