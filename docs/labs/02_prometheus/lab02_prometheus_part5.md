# Prometheus Lab Part 5: PromQL, Alerting, and Visualization with Grafana

## PromQL

PromQL (Prometheus Query Language) is the query language used to retrieve and process metrics in Prometheus.

### Aggregating Metrics

You can aggregate metrics using operators like `sum`, `avg`, `min`, `max`, and `count`:

```
sum(up)
avg(node_cpu_seconds_total) by (instance)
```

### Matchers

Matchers allow you to filter metrics:

- Exact match: `node_cpu_seconds_total{mode="idle"}`
- Negative match: `node_cpu_seconds_total{mode!="idle"}`
- Regex match: `node_filesystem_size_bytes{device=~"/dev/sd.*"}`
- Negative regex match: `node_filesystem_size_bytes{device!~"/dev/sd.*"}`

You can also combine matchers with OR:

```
node_filesystem_size_bytes{device=~"sd1|sd2"}
```

### Rate and Averages

The `rate` function calculates the per-second average rate of increase of a counter:

```
rate(http_requests_total[5m])
```

The `irate` function calculates the instant rate of increase:

```
irate(http_requests_total[5m])
```

The `avg_over_time` function calculates the average over a time range:

```
avg_over_time(up[30s])
```

### Exploring the Prometheus API

You can access the Prometheus API directly in your browser:

```
http://<your-prometheus-server>/api/v1/query?query=up
```

Or using curl:

```bash
curl "http://localhost:9090/api/v1/query?query=up" | json_pp
```

For more complex queries, you can use:

```bash
curl -G --data-urlencode "query=up{environment='test'}" "http://localhost:9090/api/v1/query"
```

## Alerting

Alerting in Prometheus is divided into two main components:
1. **Alerting rules** in Prometheus define conditions for when alerts should fire
2. **Alertmanager** handles the routing, grouping, and notification of alerts

### Setting Up Alerting Rules

Let's start by creating alert rules in Prometheus:

```bash
# Create a directory for rules
mkdir -p docker-compose/prometheus/config/rules

# Create a file for alert rules
cat > docker-compose/prometheus/config/rules/example-alerts.yml << EOF
groups:
- name: example.rules
  rules:
  - record: job:node_cpu_seconds:usage
    expr: (1 - avg by(instance)(irate(node_cpu_seconds_total{mode="idle"}[5m]))) * 100
  
  - alert: CPUUsageWarn
    expr: job:node_cpu_seconds:usage > 20 and job:node_cpu_seconds:usage < 60
    for: 1m
    labels:
      severity: warn
      team: Raptors
    annotations:
      summary: "Moderate CPU usage detected"
      description: "CPU usage on {{ \$labels.instance }} has reached 20%."
      dashboard: "http://grafana:3000/d/cpu?instance={{ \$labels.instance }}"
  
  - alert: CPUUsageCritical
    expr: job:node_cpu_seconds:usage >= 60
    for: 1m
    labels:
      severity: urgent
      team: Raptors, Leafs
    annotations:
      summary: "Critical CPU usage detected"
      description: "CPU usage on {{ \$labels.instance }} has reached {{ \$value }}%."
      dashboard: "http://grafana:3000/d/cpu?instance={{ \$labels.instance }}"
  
  - alert: CPUUsageBusinessHours
    expr: job:node_cpu_seconds:usage > 20 and on() (hour() >= 9 and hour() <= 17)
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "High CPU usage during business hours"
      description: "CPU usage is above 20% during business hours (9 AM - 5 PM) on {{ \$labels.instance }}."
  
  - alert: InstanceDown
    expr: up == 0
    for: 2m
    labels:
      severity: error
    annotations:
      summary: "Instance {{ \$labels.instance }} down"
      description: "{{ \$labels.instance }} has been down for more than 2 minutes."
EOF
```

This file defines:
- A recording rule for CPU usage
- Warning and critical alerts for CPU usage
- An alert that only fires during business hours
- An alert for when instances are down

Now, let's update our Prometheus configuration to include this rules file:

```bash
# Edit the Prometheus configuration
cat >> prom-config << EOF
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

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
  
  # ... (other job configurations remain the same)
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

Now you can visit the Alerts tab in Prometheus (http://localhost:9090/alerts) to see your alert rules. However, to receive notifications, we need to set up Alertmanager.

### Installing Alertmanager with Docker

Let's add Alertmanager to our monitoring stack:

```bash
# Create a directory for Alertmanager
mkdir -p alertmanager

# Create Alertmanager configuration
cat > alertmanager/alertmanager.yml << EOF
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'team']
  group_wait: 10s
  group_interval: 15s
  repeat_interval: 6h
  receiver: 'email-logs'
  routes:
    - match_re:
        team: 'raptors|leafs'
      receiver: 'email-logs'
      continue: true
      routes:
        - match:
            severity: error
          receiver: 'email-logs'

inhibit_rules:
  - source_match:
      severity: urgent
    target_match:
      severity: warn
    equal: ['alertname', 'instance']

receivers:
  - name: 'email-logs'
    email_configs:
      - to: 'your-email@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.example.com:587'
        auth_username: 'your-username'
        auth_password: 'your-password'
        require_tls: true
EOF

# Add Alertmanager to docker-compose.yml
cat >> docker-compose/prometheus/docker-compose.yml << EOF

  alertmanager:
    image: prom/alertmanager
    container_name: alertmanager
    volumes:
      - ../../alertmanager:/etc/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    ports:
      - "9093:9093"
    restart: unless-stopped
EOF

# Start Alertmanager
cd docker-compose/prometheus/
docker-compose up -d
```

Now, let's update our Prometheus configuration to use Alertmanager:

```bash
# Edit the Prometheus configuration
cat > prom-config << EOF
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

scrape_configs:
  # ... (job configurations remain the same)
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

![Alertmanager Routes](images/image42.png)

### Grouping, Throttling, and Repetition

The Alertmanager configuration allows you to control how alerts are grouped and sent:

- `group_by`: Groups alerts with the same labels together
- `group_wait`: How long to wait to buffer alerts of the same group before sending
- `group_interval`: How long to wait before sending a notification about new alerts that are added to a group
- `repeat_interval`: How long to wait before re-sending a notification

### Inhibitions and Silencing

Inhibitions allow you to suppress certain alerts when others are firing. For example, you can suppress warning alerts when a critical alert is firing for the same instance.

```yaml
inhibit_rules:
  - source_match:
      severity: urgent
    target_match:
      severity: warn
    equal: ['alertname', 'instance']
```

Silencing allows you to manually silence alerts for a period of time, for example, during maintenance windows.

![Silencing Alerts](images/image41.png)

### Email Notifications

To set up email notifications, you need to configure the email receiver in Alertmanager. For Gmail, you'll need to generate an App Password if you have 2-Factor Authentication enabled.

```yaml
receivers:
  - name: 'email-logs'
    email_configs:
      - to: 'your-email@gmail.com'
        from: 'your-email@gmail.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your-email@gmail.com'
        auth_identity: 'your-email@gmail.com'
        auth_password: 'your-app-password'
        require_tls: true
```

![Email Alert](images/image4.png)
![Alert Details](images/image43.png)

### Testing Alerts

You can test alerts by deliberately triggering alert conditions. For example, to test the Prometheus configuration failure alert:

```bash
# Edit the Prometheus configuration to include a syntax error
cat > prom-config << EOF
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
  external_labels:
    region: "us-west"
    dc: "datacenter-1"
  Lklkldfdsdf
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

This will cause a configuration error, which should trigger the alert.

### Slack Notifications

You can also set up Slack notifications by configuring Slack webhooks:

1. Create a Slack workspace and channels (#alert-error, #alert-warn, #alert-urgent)
2. Add the Incoming Webhooks app to your workspace
3. Create webhooks for each channel

![Slack Webhooks](images/image6.png)

Then configure Alertmanager to use these webhooks:

```yaml
receivers:
  - name: 'slack-errors'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#alert-error'
        text: "Error alert triggered for {{ $labels.instance }} - {{ $labels.alertname }}."
        send_resolved: true
```

![Slack Webhook Configuration](images/image5.png)
![Slack Integration](images/image19.png)

## Visualization with Grafana

Let's set up Grafana to visualize our Prometheus metrics:

```bash
# Create directories for Grafana
mkdir -p grafana/dashboards
mkdir -p grafana/datasources

# Add Grafana to docker-compose.yml
cat >> docker-compose/prometheus/docker-compose.yml << EOF

  grafana:
    image: grafana/grafana
    container_name: grafana
    volumes:
      - ../../grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ../../grafana/datasources:/etc/grafana/provisioning/datasources
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    ports:
      - "3000:3000"
    restart: unless-stopped
EOF

# Create Grafana data source configuration
cat > grafana/datasources/prometheus.yml << EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

# Create Grafana dashboard provisioning configuration
cat > grafana/dashboards/dashboard.yaml << EOF
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    updateIntervalSeconds: 10
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

# Start Grafana
cd docker-compose/prometheus/
docker-compose up -d
```

Now, you can access Grafana at http://localhost:3000 and log in with:
- Username: admin
- Password: admin

### Adding Prometheus as a Data Source

Grafana should automatically configure Prometheus as a data source, but you can also do it manually:

1. Go to Configuration > Data Sources
2. Click "Add data source"
3. Select "Prometheus"
4. Set the URL to "http://prometheus:9090"
5. Click "Save & Test"

![Grafana Data Source](images/image25.png)

### Importing Dashboards

You can import dashboards from the Grafana community:

1. Go to Create > Import
2. Enter a dashboard ID, such as:
   - 1860: Node Exporter Full
   - 10180: Linux Hosts Metrics
   - 193: Docker Monitoring
3. Click "Load"
4. Select the Prometheus data source
5. Click "Import"

![Grafana Dashboard Repository](images/image35.png)
![Grafana Dashboard Import](images/image34.png)
![Grafana Dashboard Configuration](images/image33.png)

### Creating Custom Dashboards

You can also create custom dashboards:

1. Go to Create > Dashboard
2. Click "Add new panel"
3. Enter a PromQL query, such as:
   - `count(container_last_seen{name=~".+"})`
   - `avg(container_cpu_usage_seconds_total) by (name)`
   - `avg(container_memory_usage_bytes) by (name)`
4. Configure the visualization (Stat, Gauge, Graph, etc.)
5. Save the dashboard

![Grafana Query](images/image28.png)
![Grafana Visualization](images/image37.png)
![Grafana Dashboard](images/image17.png)

### Adding Grafana to Prometheus

Let's also monitor Grafana itself by adding it to Prometheus:

```bash
# Edit the Prometheus configuration
cat >> prom-config << EOF

  - job_name: 'grafana'
    static_configs:
      - targets:
        - 'grafana:3000'
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

![Grafana Metrics](images/image31.png)

### Provisioning Dashboards with JSON

You can also provision dashboards using JSON configuration files:

1. Export a dashboard as JSON from Grafana
2. Save it to your grafana/dashboards directory
3. Restart Grafana

For example, you can download the Blackbox Exporter dashboard JSON and provision it:

```bash
# Download the dashboard JSON file (example)
curl -o grafana/dashboards/blackbox.json https://raw.githubusercontent.com/prometheus/blackbox_exporter/master/examples/grafana/blackbox.json
```

### Dashboard Layout and Visual Elements

When creating dashboards, you can customize the layout and add visual elements:

1. Use "Add Panel" to add new panels to your dashboard
2. Resize and rearrange panels by dragging them
3. Use the HTML panel type to add custom visual elements, such as:

```html
<p align="center">
<br>
<img src="https://i.postimg.cc/T3PchvCB/Moby-logo.png" height="70" width="70">
</p>
```

![Grafana HTML Panel](images/image36.png)

### Dashboard Links and Variables

You can add links to other dashboards or external resources:

1. Go to Dashboard Settings > Links
2. Click "Add Dashboard Link" or "Add URL Link"
3. Configure the link with a title, URL, and icon

You can also use variables to create dynamic dashboards:

1. Go to Dashboard Settings > Variables
2. Click "Add Variable"
3. Configure the variable with a name, label, and query
4. Use the variable in your panel queries like: `${variable_name}`

### Alerting in Grafana

Grafana also provides its own alerting system:

1. Edit a panel
2. Go to the Alert tab
3. Click "Create Alert"
4. Configure the alert conditions
5. Add notification channels (email, Slack, etc.)

![Grafana Alerts](images/image29.png)

You've now set up a complete monitoring stack with Prometheus and Grafana, allowing you to collect metrics, trigger alerts, and visualize your infrastructure and applications.

### Monitoring Different Types of Systems

Here are some tips for monitoring different types of systems:

1. **Web Applications**:
   - Use the RED method: Request rate, Error rate, Duration
   - Monitor client-side metrics using Browser exporters
   - Use Blackbox Exporter to check site availability

2. **Databases**:
   - Monitor connection pools, query performance, and errors
   - Use specialized exporters for different database types (MySQL, PostgreSQL, etc.)
   - Track disk usage and cache hit rates

3. **Microservices**:
   - Use service discovery for dynamic environments
   - Implement request tracing across services
   - Monitor service dependencies and health

4. **Kubernetes**:
   - Use kube-state-metrics for cluster state
   - Monitor pod resource usage and limits
   - Track control plane and node health

5. **Serverless Functions**:
   - Use Push Gateway for ephemeral workloads
   - Monitor cold starts, execution time, and memory usage
   - Track invocation counts and errors

## Conclusion

In this lab, you've learned how to:
- Set up Prometheus and various exporters
- Instrument applications to expose metrics
- Use PromQL to query metrics
- Configure alerting with Prometheus and Alertmanager
- Visualize metrics with Grafana