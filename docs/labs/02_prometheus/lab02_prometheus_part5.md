# Prometheus Lab Part 5: PromQL, Alerting, and Visualization with Grafana

## PromQL

PromQL (Prometheus Query Language) is used to retrieve and process metrics in Prometheus.

📖 Reference: [Prometheus PromQL Docs](https://prometheus.io/docs/prometheus/latest/querying/basics/)

### Aggregating Metrics
Use operators like `sum`, `avg`, `min`, `max`, and `count`:
```promql
sum(up)
avg(node_cpu_seconds_total) by (instance)
```

These operators help you get an overall view of system state, like total active instances or average CPU usage across nodes.

### Matchers
Filter metrics using matchers:
- Exact match: `node_cpu_seconds_total{mode="idle"}`
- Negative match: `node_cpu_seconds_total{mode!="idle"}`
- Regex: `node_filesystem_size_bytes{device=~"/dev/sd.*"}`
- Negative regex: `node_filesystem_size_bytes{device!~"/dev/sd.*"}`
- OR: `node_filesystem_size_bytes{device=~"sd1|sd2"}`

Use matchers to narrow down your queries to the metrics that matter most.

### Rate and Averages
These functions help you measure how metrics change over time:
```promql
rate(http_requests_total[5m])
irate(http_requests_total[5m])
avg_over_time(up[30s])
```

### Prometheus API
Run queries from the browser:
```
http://<your-prometheus-server>/api/v1/query?query=up
```
Or using `curl` in your terminal:
```bash
curl "http://localhost:9090/api/v1/query?query=up" | json_pp
```
More advanced:
```bash
curl -G --data-urlencode "query=up{environment='test'}" "http://localhost:9090/api/v1/query"
```
📖 Reference: [Prometheus HTTP API](https://prometheus.io/docs/prometheus/latest/querying/api/)

## Simple Alerting Setup

### Step 1: Create a Basic Alert Rule
Create a rules file with an alert that triggers when any target is down:
```bash
mkdir -p docker-compose/prometheus/config/rules
cat > docker-compose/prometheus/config/rules/simple-alerts.yml << EOF
groups:
- name: simple.rules
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Instance down"
      description: "{{ $labels.instance }} is down."
EOF
```

### Step 2: Update Prometheus Config
Edit `prom-config` and add:
```yaml
rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```
Reload Prometheus so it loads the new rules:
```bash
curl -X POST http://localhost:9090/-/reload
```
📖 Reference: [Prometheus Alerting Rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)

## Slack Notifications (Simplified)

### Step 1: Create a Slack Channel
Go to your Slack workspace and create a channel:
```
#prometheus-alerts
```
This is where all your alert messages will appear.

### Step 2: Add an Incoming Webhook to Slack
1. Go to: [Slack API Apps](https://api.slack.com/apps)
2. Click "Create New App" > From scratch
3. Enable **Incoming Webhooks**
4. Click "Add New Webhook to Workspace"
5. Choose your `#prometheus-alerts` channel and allow access
6. Copy the generated URL (e.g., `https://hooks.slack.com/services/T000/B000/XXXX`)

📖 Reference: [Slack Webhook Docs](https://api.slack.com/messaging/webhooks)

### Step 3: Create Alertmanager Config
Create a file `alertmanager.yml`:
```yaml
global:
  resolve_timeout: 5m

route:
  receiver: 'slack-simple'

receivers:
  - name: 'slack-simple'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/T000/B000/XXXX'
        channel: '#prometheus-alerts'
        text: "{{ .CommonAnnotations.summary }}\n{{ .CommonAnnotations.description }}"
        send_resolved: true
```
📖 Reference: [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)

### Step 4: Add Alertmanager to Docker Compose
Edit your `docker-compose.yml`:
```yaml
alertmanager:
  image: prom/alertmanager
  container_name: alertmanager
  volumes:
    - ../../alertmanager:/etc/alertmanager
  command:
    - '--config.file=/etc/alertmanager/alertmanager.yml'
  ports:
    - "9093:9093"
  restart: unless-stopped
```

Then run:
```bash
cd docker-compose/prometheus/
docker-compose up -d
```

### Step 5: Trigger and Test an Alert
Stop one of your monitored services or simulate an alert manually:
```bash
curl -X POST http://localhost:9090/-/reload
```
You should see a notification in Slack within one minute.

## Visualization with Grafana

📖 Reference: [Grafana Docs](https://grafana.com/docs/)

1. Run Grafana via Docker:
```yaml
grafana:
  image: grafana/grafana
  container_name: grafana
  ports:
    - "3000:3000"
  restart: unless-stopped
```
2. Access: [http://localhost:3000](http://localhost:3000)
   - Username: `admin`
   - Password: `admin`
3. Add Prometheus as a data source:
   - Configuration → Data Sources → Add Prometheus → URL: `http://prometheus:9090`
4. Create a dashboard:
   - Click + → Dashboard → Add new panel
   - Example query:
```promql
avg(node_cpu_seconds_total{mode="idle"}) by (instance)
```

You can also set alerts within panels directly.

## Conclusion

In this lab, you:
- Used PromQL to query, filter, and analyze metrics
- Created a simple alert for downed instances
- Integrated Slack for instant notifications using a single channel
- Visualized metrics in Grafana dashboards

> 🎉 Your Prometheus stack is now complete — lean, fast, and ready for action!