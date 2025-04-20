# 📘 Prometheus Lab Part 4: Service Discovery, Pushing Metrics, and Labeling

This part of the lab helps you extend Prometheus to handle more dynamic and real-world monitoring setups, including:

- Pushing metrics from short-lived jobs (via Pushgateway)
- Manually exporting metrics from scripts (Textfile Collector)
- Discovering services dynamically (File-based Service Discovery)
- Using labels for filtering, structuring, and managing your targets

---

## 📄 Pushing Metrics to Prometheus

### 🚀 Why Push Metrics?

Prometheus normally **pulls** metrics from targets on a schedule. But what if your job is short-lived and might finish before Prometheus scrapes it?

That’s where the **Pushgateway** comes in.

It acts as a temporary store where jobs **push** their metrics, and Prometheus scrapes the Pushgateway.

---

### 🔌 The Push Gateway

#### ✅ Add Pushgateway to Docker Compose

From your project directory:

```bash
cd /home/ubuntu/prometheus-monitoring/docker-compose/prometheus
```

Add Pushgateway service to your `docker-compose.yml`:

```yaml
  pushgateway:
    image: prom/pushgateway:v1.1.0
    container_name: pushgateway
    restart: unless-stopped
    ports:
      - "9091:9091"
```

Then start the updated services:

```bash
docker-compose up -d
```

---

### 🔧 Add Pushgateway to Prometheus Configuration

Edit `/home/ubuntu/prometheus-monitoring/docker-compose/prometheus/config/prometheus.yml`:

```yaml
  - job_name: 'push-gateway'
    honor_labels: true
    static_configs:
      - targets: ['192.168.106.34:9091']
```

> `honor_labels: true` ensures Prometheus keeps original labels from the pushed metrics.

---

### 🔄 Reload Prometheus Configuration

```bash
curl -X POST http://localhost:9090/-/reload
```

---

### 🌐 View the Pushgateway UI

Visit:

```
http://192.168.106.34:9091/
```

---

## 🐍 Pushing a Metric to Pushgateway with Python

### 🗂️ 1. Create the Script

From your project root:

```bash
cd /home/ubuntu/prometheus-monitoring
mkdir -p instrumentation/push-gw
```

Create the Python script:

```bash
cat > instrumentation/push-gw/push_register.py << EOF
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

registry = CollectorRegistry()
g = Gauge(
    'mktemp_last_success_unixtime',
    'Last time a batch job successfully finished',
    registry=registry
)
g.set_to_current_time()
push_to_gateway('localhost:9091', job='mkTemp', registry=registry)
EOF
```

---

### 🩰 2. Create a Virtual Environment (named `venv-push`)

```bash
python3 -m venv venv-push
source venv-push/bin/activate
```

---

### 📆 3. Install Python Dependencies

```bash
pip install prometheus-client
```

---

### 🚀 4. Run the Script

```bash
python3 instrumentation/push-gw/push_register.py
```

---

### 🔍 Query in Prometheus

```
mktemp_last_success_unixtime
```

Or:

```
mktemp_last_success_unixtime{job="mkTemp"}
```

---

### 🛠️ Manual Push with Curl (Optional)

```bash
# Simple value only:
echo "mktemp_last_success_unixtime $(date +%s)" | \
curl --data-binary @- http://localhost:9091/metrics/job/mkTemp

# With metric type:
echo -e "# TYPE mktemp_last_success_unixtime gauge\nmktemp_last_success_unixtime $(date +%s)" | \
curl --data-binary @- http://localhost:9091/metrics/job/mkTemp
```

---

## 📄 The Textfile Collector

### 🧠 What is it?

It allows **Node Exporter** to expose custom metrics by reading `.prom` files written by scripts.

Useful for:
- Bash/Cron jobs
- Legacy scripts
- When HTTP endpoints aren't an option

---

### 🔧 Enable Textfile Collector (Docker Compose)

1. Go to new terminal. Edit Node Exporter config in:

```bash
/home/ubuntu/prometheus-monitoring/docker-compose/prometheus/docker-compose.yml
```

Replace the `nodeexporter` service with:

```yaml
  nodeexporter:
    image: prom/node-exporter
    container_name: nodeexporterthat
    ports:
      - "9100:9100"
    volumes:
      - /tmp:/tmp
    command:
      - '--collector.textfile.directory=/tmp'
    restart: unless-stopped
```

2. Restart Node Exporter:

```bash
cd /home/ubuntu/prometheus-monitoring/docker-compose/prometheus
docker-compose up -d nodeexporter
```

3. Confirm at:
```
http://192.168.106.34:9100/metrics
```
Search for: `node_textfile_scrape_error`

---

### 🖊️ Create a Metric Export Script

```bash
#Go back to prometheus-monitoring directory

cat > instrumentation/file_counter.sh << EOF
#!/bin/bash

DIR=/tmp
RESULT=\$(ls \${DIR}/push-???? | wc -l)
END=\"\$(date +%s)\"

cat <<END_OF_FILE > \"\$DIR/pushfiles.prom.\$\$\"
node_pushfiles_total \$RESULT
node_pushfiles_last_run_seconds \$END
END_OF_FILE

mv \"\$DIR/pushfiles.prom.\$\$\" \"\$DIR/pushfiles.prom\"
EOF

chmod +x instrumentation/file_counter.sh
./instrumentation/file_counter.sh
```

Query:
```
node_pushfiles_total
```
> ✅ Great job! You've now instrumented your app, generated traffic, and verified metrics in Prometheus.  
> 👉 Let's level up with **Part 5**, where you'll write powerful **PromQL queries**, set up **Slack alerts**, and build your first **Grafana dashboards**.