## Prometheus Lab Part 3: Infrastructure Monitoring

---

### 🖥️ The Node Exporter

The Node Exporter collects system-level metrics from Linux (via `/proc`, `/sys`, etc.).

📍 **Metrics endpoint:**

```
http://192.168.0.12:9100/metrics
```

---

### 📍 Where to Run PromQL Queries

Open the **Prometheus Web UI**:

```
http://localhost:9090
```

Or if you're in a VM:

```
http://192.168.0.12:9090
```

Once open:

1. Click the **“Graph”** tab  
2. Enter a query into the **Expression** bar  
3. Click **Execute**  
4. Toggle to the **Graph** view to visualize results

---

### 📊 PromQL Queries to Explore

| Description                        | Query |
|------------------------------------|-------|
| Total CPU time per mode            | `node_cpu_seconds_total` |
| CPU idle (raw)                     | `sum without(cpu)(node_cpu_seconds_total{mode="idle"})` |
| CPU idle (rate over time)          | `sum without(cpu)(rate(node_cpu_seconds_total{mode="idle"}[5m]))` |
| Guest time on VMs                  | `node_cpu_guest_seconds_total` |
| Total memory (MB)                  | `node_memory_MemTotal_bytes / 1e6` |
| Free disk space (MB)               | `node_filesystem_free_bytes / 1024 / 1024` |
| Disk write rate                    | `rate(node_disk_written_bytes_total[5m])` |
| Network interfaces info            | `node_network_info` |
| System boot time (epoch)           | `node_boot_time_seconds` *(convert with [epochconverter.com](https://epochconverter.com))* |
| System kernel/version info         | `node_uname_info` |

💡 `1e6` is scientific notation = **1,000,000** → converts bytes to megabytes

---

### 🐳 Docker Engine Metrics

Docker can expose internal metrics such as container counts and image stats.

---

### 📍 Where to Place `daemon.json`

You must configure Docker **on the host system**, **outside of your Prometheus project**.

✅ Create `daemon.json` like this:

```bash
cat > daemon.json << EOF
{
  "metrics-addr": "0.0.0.0:9323",
  "experimental": true
}
EOF
```

✅ Move it to the correct system path:

```bash
sudo mv daemon.json /etc/docker/daemon.json
sudo systemctl restart docker
```
Start-up my_app container again, if it failed.

🔍 Test it:

```bash
curl http://localhost:9323/metrics
```

---

### ➕ Add to Prometheus config (`prometheus.yml`) as usual (your host IP)

```yaml
  - job_name: 'docker-engine'
    static_configs:
      - targets: ['192.168.106.34:9323']
```

♻️ Reload Prometheus:

```bash
curl -X POST http://localhost:9090/-/reload
```
Prometheus Targets must show now "docker-engine" with status UP.

---

### 🔍 Docker PromQL Example

Try to test query, you will see 3 running containers.

```promql
engine_daemon_container_states_containers
```

Shows number of containers by state (running, paused, etc.).

---

### 🦉 cAdvisor: Container-Level Metrics

**cAdvisor** gives detailed per-container stats like CPU, memory, and filesystem usage.

---

### 🧱 Add to `docker-compose/prometheus/docker-compose.yml`

```yaml
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
    ports:
      - "8080:8080"
    restart: unless-stopped
```

---

### 🚀 Restart the service

```bash
cd prometheus-monitoring/docker-compose/prometheus/
docker-compose up -d
```

---

### ➕ Add job to Prometheus

```yaml
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['192.168.106.34:8080']
```

♻️ Reload Prometheus:

```bash
curl -X POST http://localhost:9090/-/reload
```

---

### 📊 cAdvisor PromQL Examples

- Container CPU usage:
  ```promql
  container_cpu_usage_seconds_total
  ```

- Sum CPU usage across all Docker containers:
  ```promql
  sum without(cpu, container_label_maintainer)(container_cpu_usage_seconds_total{id=~"/docker/.*"})
  ```

🌐 Visit cAdvisor web UI at:
```
http://192.168.106.34:8080
```

---

### ✅ Summary

| Tool           | Metrics Provided                   |
|----------------|------------------------------------|
| Node Exporter  | Host: CPU, RAM, disk, boot time    |
| Docker Engine  | Docker: container states, events   |
| cAdvisor       | Containers: CPU, memory, FS usage  |

View all metrics and graphs at:

```
http://http://192.168.106.34:9090
```

Use the "Graph" tab to test your PromQL skills.

---

> 🚀 Ready for Part 4? Let’s monitor **ephemeral and batch jobs** using Pushgateway and custom instrumentation!