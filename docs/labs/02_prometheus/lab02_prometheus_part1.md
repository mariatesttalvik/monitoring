# Prometheus Lab Part 1: Introduction and Setup

## 🚀 What You'll Build

In this lab series, you're building a real-world Prometheus monitoring stack — including a dashboard, app instrumentation, alerting system, and service discovery — **all containerized** with Docker.

Here's a sneak peek of your project structure:

```
prometheus-monitoring/
├── instrumentation/            # Apps & scripts we instrument
│   ├── httpserver_test.py      # Barebones Python HTTP server
│   ├── curler.sh               # Traffic generator
│   ├── file_counter.sh         # Textfile exporter sample
│   ├── push-gw/
│   │   └── push_register.py    # PushGateway metric script
│   └── flask_app/
│       ├── Dockerfile
│       └── app/
│           ├── wsgi_prom.py    # Flask app with Prometheus client
│           └── uwsgi.ini
├── grafana/
│   ├── dashboards/
│   └── datasources/
├── alertmanager/
├── docker-compose/
│   └── prometheus/
│       ├── docker-compose.yml
│       └── config/
│           ├── prometheus.yml
│           ├── blackbox.yml
│           ├── file-sd/
│           └── rules/
└── prom-config → symlink to ./docker-compose/prometheus/config/prometheus.yml
```
---

## 🧰 Setting up Your Environment

| Component          | Description                     |
| ------------------ | ------------------------------- |
| Ubuntu Linux       | Base OS or VM                   |
| Docker             | Run services in containers      |
| Docker Compose     | Orchestrate multi-service setup |
| VS Code (optional) | Edit configs and Python code    |

### 1. Install Docker and Docker Compose

```bash
curl -fsSL https://get.docker.com -o install-docker.sh
sudo sh install-docker.sh
sudo usermod -aG docker ${USER}
newgrp docker
```

```bash
# Choose architecture
# For x86_64:
sudo curl -SL https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose

# For ARM64:
sudo curl -SL https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-linux-aarch64 -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

> ✅ Run `docker --version` and `docker-compose --version` to verify.

---

### 2. What's My Server IP?

You'll access Prometheus via browser, so get your server IP:

```bash
hostname -I
```

> Example: If output is `192.168.56.10`, Prometheus runs at `http://192.168.56.10:9090`

---

## 🧹 Clean Up Old Containers

Before running services with Docker Compose, stop and remove any old containers that may cause conflicts:

```bash
docker stop prometheus nodeexporter 2>/dev/null || true
docker rm prometheus nodeexporter 2>/dev/null || true
```

This prevents name conflicts when you spin up the Docker Compose version.

---

## 🔧 First Contact with Prometheus

We’ll now create the configuration directly in the right folder used by Docker Compose:

```bash
# Be in the root of your project directory, e.g. ~/prometheus-lab
mkdir -p prometheus-monitoring/docker-compose/prometheus/config
cd prometheus-monitoring/docker-compose/prometheus
```

Create the Prometheus configuration file:

```bash
# You should still be inside: prometheus-monitoring/docker-compose/prometheus
cat > config/prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF
```

Run Prometheus manually to verify everything is working:

```bash
# Run from inside: prometheus-monitoring/docker-compose/prometheus
docker run -d --name prometheus \
  -p 9090:9090 \
  -v $(pwd)/config:/etc/prometheus \
  prom/prometheus
```

Access Prometheus: `http://YOUR_SERVER_IP:9090`

Try the query `up` to verify Prometheus is alive.

---

## 🧪 Add Node Exporter (System Metrics)

```bash
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

Update config:

```bash
# Still inside: prometheus-monitoring/docker-compose/prometheus
cat > config/prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
EOF

docker restart prometheus  # Ensure it reads the updated config from the correct path
```

Now visit `http://YOUR_IP:9090/targets` — both `prometheus` and `node` should show **UP**.

---

## 🐳 Using Docker Compose (Recommended)

Now let’s set up services the *real* way — using Docker Compose:

```bash
# From the root (~/prometheus-lab), create your Docker Compose setup
mkdir -p prometheus-monitoring/docker-compose/prometheus/config
cd prometheus-monitoring/docker-compose/prometheus
```

### `docker-compose.yml`

```yaml
volumes:
  data: {}

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./config:/etc/prometheus
      - data:/prometheus
    ports:
      - "9090:9090"
    restart: unless-stopped

  nodeexporter:
    image: prom/node-exporter
    container_name: nodeexporter
    ports:
      - "9100:9100"
    restart: unless-stopped
```

### `config/prometheus.yml`

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['prometheus:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['nodeexporter:9100']
```

> ⚠️ **Troubleshooting Tip – Config Not Found?**
>
> If Prometheus logs show: `Error loading config (--config.file=/etc/prometheus/prometheus.yml): no such file or directory`
>
> This usually means the `config` folder wasn’t mounted properly.
>
> ✅ Ensure the file **exists** before running `docker compose up`:
>
> ```bash
> ls -l prometheus-monitoring/docker-compose/prometheus/config/prometheus.yml
> ```
>
> 🧹 If you've run the container before and it cached a broken volume, clean it up:
>
> ```bash
> docker compose down -v
> ```

Before running, stop and clean up any old containers (e.g. from manual runs):

```bash
docker stop prometheus nodeexporter 2>/dev/null || true
docker rm prometheus nodeexporter 2>/dev/null || true
```

Now start everything:

```bash
docker compose up -d
```

## ✅ TASK: Explore Prometheus Internals

### 🔎 Check if Targets Are Up

> ⚠️ **Note:** You can't access Node Exporter via `http://nodeexporter:9100/metrics` from your browser because `nodeexporter` is a container name, not a valid hostname from your local network or browser. That's why you might see a DNS error like:
> 
> `Hmmm… can't reach this page`
>
> But internally, Prometheus *can* reach it thanks to Docker Compose networking. To check if Node Exporter is truly running:

```bash
docker logs nodeexporter
```

Or access it by replacing the name with your **server IP address** if ports are published:

```text
http://localhost:9100/metrics
http://<your-server-ip>:9100/metrics
```

Then, proceed to check targets from the Prometheus UI:

To make sure your Node Exporter and Prometheus are being scraped correctly:

1. Go to [http://localhost:9090](http://localhost:9090)
2. Click on the **Status** menu (top bar) → **Targets**
3. You should see something like this:

```
job = prometheus
  • instance = prometheus:9090  ✓ UP

job = node
  • instance = nodeexporter:9100 ✓ UP
```

If any are marked **DOWN**, double-check that the container is running and the port is correct in `prometheus.yml`.

### 🧪 Run Your First Queries

You can also view metrics being scraped directly from container logs.

To view raw metric output from Node Exporter:

```bash
docker logs nodeexporter
```

This shows what Prometheus would see at [http://localhost:9100/metrics](http://localhost:9100/metrics).

To inspect Prometheus metrics:

```bash
docker logs prometheus
```

These logs may also include startup and scrape status messages.

In Prometheus's **Graph** tab:

1. Type `up` and press **Execute** — this shows which targets are being scraped
2. Try simpler metric queries first:

```text
node_cpu_seconds_total
```

Then try more detailed queries:

```text
rate(node_cpu_seconds_total[5m])
node_uname_info
```

> 💡 Tip: Prometheus has autocomplete! Start typing a metric and suggestions will appear.

Now, you can query Node Exporter metrics in Prometheus, such as:

- `rate(node_cpu_seconds_total[5m])`: CPU usage rate
- `node_uname_info`: System information

### 🔍 The Prometheus Metrics Format

Access the raw metrics by visiting:

- Prometheus metrics: [http://localhost:9090/metrics](http://localhost:9090/metrics)
- Node Exporter metrics: [http://localhost:9100/metrics](http://localhost:9100/metrics)

Types of metrics:

- **Gauge**: Values that can go up and down (e.g., memory usage)
- **Counter**: Values that only increase (e.g., total requests)
- **Histogram**: Bucketed distributions (e.g., request durations)

### 🧬 Breaking Down Prometheus' Dimensional Model

Every time series in Prometheus is identified by:

- A **metric name** (e.g., `http_requests_total`)
- A set of **labels** (e.g., `method="GET"`, `status="200"`)

Example:

```text
http_requests_total{method="GET", endpoint="/api/users", status="200"}
```

### 📊 Prometheus UI Deep Dive

Open Prometheus at: [http://localhost:9090](http://localhost:9090)

Explore tabs:

- **Status** → **Target Health**: Verify which endpoints are up or down
- **Targets**: Active scrape targets
- **Graph**: Run and visualize queries
- **Alerts**: Triggered alert rules (once configured)

Try the query:

```text
up
```

If you see:

```text
up{instance="localhost:9090", job="prometheus"} 1
```

That means Prometheus is monitoring itself successfully!

### 🔁 Reloading Prometheus Configuration

Whenever you update your `prometheus.yml` file, you can tell Prometheus to reload the config **without restarting the container**:

```bash
curl -X POST http://localhost:9090/-/reload
```

> 💡 This only works if Prometheus is started with `--web.enable-lifecycle` flag, which is already included in your Docker Compose setup.

This makes applying changes (like adding new targets or alerts) fast and seamless.

---

### 🧱 Components Inside the Prometheus Container

Understanding the internal layout of Prometheus helps when you're troubleshooting, checking where metrics are stored, or validating configurations.

| Component           | Description                              |
| ------------------- | ---------------------------------------- |
| `console_libraries` | Web UI console helpers                   |
| `consoles`          | UI dashboards                            |
| `data`              | TSDB: time-series data (metrics go here) |
| `prometheus`        | Main Prometheus binary                   |
| `prometheus.yml`    | Your config file (you mount this!)       |
| `promtool`          | Validate configs & debug queries         |

For example, if you want to check what config Prometheus is actually using, or why it won't start, you can run:

```bash
docker exec -it prometheus cat /etc/prometheus/prometheus.yml
```

You can also explore the `/data` folder inside the container to understand where metrics are written. Validate configs & debug queries |

---

## 💡 Summary

You now have a working Prometheus stack with:

- A real-time dashboard
- Host system metrics
- Configured using best practices and Docker Compose

**Next:** We’ll add an instrumented Python app and make Prometheus collect custom metrics from it.

👉 Head to **Lab Part 2: App Instrumentation**. Validate configs & debug queries