# Prometheus Lab Part 3: Infrastructure Monitoring

## The Node Exporter

The Node Exporter is a Prometheus exporter that collects a wide variety of hardware and OS metrics from the Linux kernel. It's particularly useful for monitoring the health and performance of your hosts.

Let's explore some useful Node Exporter metrics:

```bash
# Visit the Node Exporter metrics endpoint
curl http://localhost:9100/metrics
```

Look for these metrics in the output:
- `node_cpu_seconds_total`: How many seconds the CPU spent in each mode
- `node_memory_MemTotal_bytes`: Total memory
- `node_filesystem_free_bytes`: Free disk space
- `node_network_transmit_bytes_total`: Network traffic

Let's query some of these metrics in Prometheus:

1. CPU idle time: 
```
sum without(cpu)(node_cpu_seconds_total{mode="idle"})
```

2. CPU idle rate:
```
sum without(cpu)(rate(node_cpu_seconds_total{mode="idle"}[5m]))
```

![Node CPU Metrics](images/image70.png)

3. Total memory in megabytes:
```
node_memory_MemTotal_bytes / 1e6
```

4. Free disk space:
```
node_filesystem_free_bytes / 1024 / 1024
```

5. Disk write rate:
```
rate(node_disk_written_bytes_total[5m])
```

6. Network information:
```
node_network_info
```

![Node Memory Metrics](images/image72.png)

![Network Information](images/image73.png)

7. System boot time:
```
node_boot_time_seconds
```
(You can convert this epoch time at https://www.epochconverter.com/ to see when the system was started)

8. System version information:
```
node_uname_info
```

## The WMI Exporter: Monitoring Windows Systems

For Windows systems, you can use the WMI (Windows Management Instrumentation) Exporter. While we won't set it up in this lab, you can download it from the official GitHub repository:
https://github.com/prometheus-community/windows_exporter/releases

## Docker Engine Metrics

Let's enable metrics for the Docker Engine itself:

```bash
# Create a daemon.json file for Docker
cat > daemon.json << EOF
{
  "metrics-addr": "0.0.0.0:9323",
  "experimental": true
}
EOF

# Move it to the Docker configuration directory
sudo mv daemon.json /etc/docker/

# Restart Docker to apply the changes
sudo systemctl restart docker

# Verify metrics are being exposed
curl http://localhost:9323/metrics
```

Now, let's add Docker Engine to our Prometheus configuration:

```bash
# Edit the Prometheus configuration
cat >> prom-config << EOF

  - job_name: 'docker-engine'
    static_configs:
      - targets:
        - localhost:9323
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

![Docker Engine Metrics](images/image74.png)

You can now query Docker Engine metrics in Prometheus. Try this query to see the number of containers:

```
engine_daemon_container_states_containers
```

![Container Count](images/image45.png)

## cAdvisor Metrics

cAdvisor (Container Advisor) provides container users with resource usage information. Let's add it to our monitoring stack:

```bash
# Add cAdvisor to our docker-compose.yml
cat >> docker-compose/prometheus/docker-compose.yml << EOF

  cadvisor:
    image: gcr.io/cadvisor/cadvisor
    container_name: cadvisor
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /var/run/docker.sock:/var/run/docker.sock:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    restart: unless-stopped
    expose:
      - "8080"
    ports:
      - "8080:8080"
EOF

# Start cAdvisor
cd docker-compose/prometheus/
docker-compose up -d
```

Now, let's add cAdvisor to our Prometheus configuration:

```bash
# Edit the Prometheus configuration
cat >> prom-config << EOF

  - job_name: 'cadvisor'
    static_configs:
      - targets:
        - localhost:8080
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

![cAdvisor Metrics](images/image46.png)

Now you can query container metrics in Prometheus. Try these queries:

1. Container CPU usage:
```
container_cpu_usage_seconds_total
```

2. Sum of Docker container CPU usage:
```
sum without(cpu, container_label_maintainer)(container_cpu_usage_seconds_total{id=~"/docker/.*"})
```

![Container CPU Metrics](images/image47.png)

![Container Metrics Overview](images/image48.png)

## The Blackbox Exporter

The Blackbox Exporter allows Prometheus to probe endpoints over HTTP, HTTPS, DNS, TCP, and ICMP. It's useful for monitoring website availability, SSL certificate expiration, and network connectivity.

Let's add the Blackbox Exporter to our monitoring stack:

```bash
# Download the default blackbox.yml configuration
curl -o docker-compose/prometheus/config/blackbox.yml https://raw.githubusercontent.com/prometheus/blackbox_exporter/master/blackbox.yml

# Add Blackbox Exporter to our docker-compose.yml
cat >> docker-compose/prometheus/docker-compose.yml << EOF

  blackbox:
    image: prom/blackbox-exporter
    container_name: blackbox
    volumes:
      - ./config:/config
    command:
      - '--config.file=/config/blackbox.yml'
      - '--history.limit=50'
    ports:
      - "9115:9115"
    restart: unless-stopped
EOF

# Start the Blackbox Exporter
cd docker-compose/prometheus/
docker-compose up -d
```

![Blackbox Exporter](images/image49.png)

Now, let's add the Blackbox Exporter to our Prometheus configuration:

```bash
# Edit the Prometheus configuration
cat >> prom-config << EOF

  - job_name: 'blackbox'
    static_configs:
      - targets:
        - localhost:9115
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

Let's test the Blackbox Exporter by probing some endpoints:

```bash
# Probe a website using HTTP
curl "http://localhost:9115/probe?target=prometheus.io&module=http_2xx"

# Probe with debugging information
curl "http://localhost:9115/probe?target=prometheus.io&module=http_2xx&debug=true"

# Probe YouTube
curl "http://localhost:9115/probe?target=youtube.com&module=http_2xx&debug=true"

# Ping a host using ICMP
curl "http://localhost:9115/probe?module=icmp&target=localhost"

# Ping Google DNS
curl "http://localhost:9115/probe?module=icmp&target=8.8.8.8"

# Test TCP connection to our Flask app
curl "http://localhost:9115/probe?target=localhost:5000&module=tcp_connect"
```

![Blackbox UI](images/image50.png)

Let's update our Blackbox Exporter configuration to add more modules:

```bash
# Add DNS module to blackbox.yml
cat >> docker-compose/prometheus/config/blackbox.yml << EOF

dns_google:
  prober: dns
  dns:
    transport_protocol: "tcp"
    query_name: "google.com"
EOF

# Reload the Blackbox Exporter configuration
curl -X POST http://localhost:9115/-/reload

# Test the DNS module
curl "http://localhost:9115/probe?target=8.8.8.8&module=dns_google"
```

Now, let's configure Prometheus to actively probe targets using the Blackbox Exporter:

```bash
# Edit the Prometheus configuration
cat >> prom-config << EOF

  - job_name: 'blackbox_targets'
    metrics_path: /probe
    params:
      module: [dns_google]
    static_configs:
      - targets:
        - 8.8.8.8
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

Let's add another job for TCP connectivity checks:

```bash
# Edit the Prometheus configuration
cat >> prom-config << EOF

  - job_name: 'blackbox-tcp'
    metrics_path: /probe
    params:
      module: [tcp_connect]
    static_configs:
      - targets:
        - "localhost:5000"
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

Finally, let's add a job to check if a specific word appears on a website:

```bash
# Add a custom module to blackbox.yml
cat >> docker-compose/prometheus/config/blackbox.yml << EOF

http_smartid:
  prober: http
  http:
    preferred_ip_protocol: "ip4"
    fail_if_body_not_matches_regexp:
      - "Help"
EOF

# Reload the Blackbox Exporter configuration
curl -X POST http://localhost:9115/-/reload

# Add a job to Prometheus
cat >> prom-config << EOF

  - job_name: 'smart-id-sign-status'
    metrics_path: /probe
    params:
      module: [http_smartid]
    static_configs:
      - targets:
        - "https://www.smart-id.com/"
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: localhost:9115
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

![Blackbox Results](images/image51.png)

## The MySQL Exporter

While we won't set it up fully in this lab, you can also monitor MySQL databases using the MySQL Exporter:

```bash
# Install MySQL
sudo apt-get install mysql-server
sudo systemctl start mysql

# Create a user for the exporter
sudo mysql -u root -p
CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'exporter' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
exit

# Download and install the MySQL Exporter
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.1/mysqld_exporter-0.15.1.linux-amd64.tar.gz
tar xvf mysqld_exporter-0.15.1.linux-amd64.tar.gz
cd mysqld_exporter-0.15.1.linux-amd64/

# Create configuration file
cat > .my.cnf << EOF
[client]
user=exporter
password=exporter
EOF

# Run the exporter
./mysqld_exporter --config.my-cnf=./.my.cnf &
```

Add MySQL Exporter to Prometheus:

```bash
# Edit the Prometheus configuration
cat >> prom-config << EOF

  - job_name: 'mysql-exporter'
    static_configs:
      - targets:
        - "localhost:9104"
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

![MySQL Exporter Metrics](images/image52.png)

You can now query MySQL metrics in Prometheus, such as:
- `mysql_version_info`: MySQL version information
- `mysql_global_status_connections`: Connection statistics