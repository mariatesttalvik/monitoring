# Part 3: Grafana Configuration and Log Monitoring

## Introduction

In this final part of the lab, you'll configure Grafana for advanced data visualization and set up Loki for centralized log monitoring. By the end of this section, you'll have a complete monitoring ecosystem that combines metrics, synthetic monitoring, and logs in powerful dashboards.

**Time allocation:** 1 hour total
- Grafana Basic Setup: 15 minutes
- Advanced Grafana Dashboards: 20 minutes
- Loki and Log Monitoring: 25 minutes

---

## 1. Grafana Basic Setup (15 min)

### 1.1 Access Grafana Web Interface

1. Open your web browser and navigate to:
   ```
   http://your-server-ip:3000
   ```

2. Log in with the default credentials:
   - Username: **admin**
   - Password: **admin**

3. When prompted to change the password, enter a new secure password and click **Submit**.

### 1.2 Add Loki as a Data Source

Next, let's add Loki for log monitoring:

1. Navigate to **Configuration** → **Data Sources** in the left sidebar.

2. Click **Add data source**.

3. Search for "Loki" and select it from the list.

4. Enter the following settings:
   - Name: **Loki**
   - URL: **http://loki:3100**
   - Access: **Server (default)**

5. Click **Save & Test**.

   You should see a green message indicating a successful connection to Loki.

### 1.3 Viewing Logs with Loki

After successfully connecting to Loki, follow these steps to view your system logs:

1. Click on the **Explore** icon (compass) in the left sidebar.

2. Select **Loki** from the data source dropdown at the top of the page.

3. You will see the Log browser interface with a query field.

4. Enter a basic query to see logs:
   ```
   {job="varlogs"}
   ```
   This will show logs from system log files defined in your Promtail configuration.

5. For Docker container logs, use:
   ```
   {job="docker"}
   ```

6. Click **Run query** to execute and view the logs.

7. You can refine your search by adding more labels or text search terms:
   ```
   {job="docker"} |= "error"
   ```
   This will show only Docker logs containing the word "error".

8. Use the time range selector at the top right to adjust the time period for which logs are displayed.

**Note:** It may take a few minutes for logs to be collected by Promtail and sent to Loki. If you don't see logs immediately, wait a few minutes and try again.

### 1.4 Add Zabbix as a Data Source

You should find  it the same as Loki.

If you cant find Zabbix as datasource, install it
 ```bash
 docker exec -it grafana sh
 docker exec -it grafana grafana-cli plugins install alexanderzobnin-zabbix-app
 docker ps | grep grafana
 docker-compose restart grafana
 ```
 - Configure the Zabbix data source:
   For the URL field in Image: http://zabbix-web:8080/api_jsonrpc.php
 - Username: Admin
 - Password: zabbix

```bash
Maybe you need to add Mysql DB (ZabbixDB)

Configuration → Data Sources
Click "Add data source"
Select "MySQL" as the data source type
Configure the MySQL connection:

Name: ZabbixDB (or any name you prefer)
Host: zabbix-mysql
Database: zabbix
User: zabbix
Password: zabbix_pwd

Click "Save & Test" to verify the connection works
```
---

## 2. Creating Your First Log Dashboard (10 min)

Now let's create a simple dashboard to monitor logs:

1. From the left sidebar, navigate to **Dashboards** → **+ New Dashboard**.

2. Click **Add visualization**.

3. In the query editor, select **Loki** as the data source.

4. Add another panel with system logs by clicking **Add panel** again and using the query:
   ```
   {job="varlogs"}
   ```
5. Save your dashboard by clicking the disk icon in the top right corner and give it a name, e.g., "System Monitoring".

---

## 2. Advanced Grafana Dashboards (20 min)

### 2.1 Import a System Monitoring Dashboard

Let's start by importing a pre-built dashboard for system monitoring:

1. In the Grafana interface, navigate to **Dashboards** → **Import** (from the "+" icon in the sidebar).

2. You can either:
   - Enter the dashboard ID (pick one)
   - Or upload a dashboard JSON file provided by your instructor

3. Click **Load**.

4. On the next screen:
   - Name: **System Monitoring Dashboard**
   - Folder: **General**
   - Zabbix Data Source: Select **Zabbix** from the dropdown
   - Click **Import**.

5. Examine the imported dashboard. It should show various system metrics from Zabbix:
   - CPU usage
   - Memory usage
   - Disk I/O
   - Network traffic
   - And more

6. Take a few minutes to explore the panels and understand the visualizations.

### 2.2 Create a Database Monitoring Dashboard

Try  to add any Datasource, import Template and create the Dashboard.

## 3. Loki and Log Monitoring (25 min)

### 3.1 Configure Promtail for Log Collection

Promtail is the agent that collects logs and sends them to Loki. Let's configure it properly:

1. First, check if Promtail is running:
   ```bash
   docker-compose ps promtail
   ```

2. Let's create a more comprehensive configuration. Create a new file for Promtail configuration:
   ```bash
   nano data/promtail/config.yml
   ```

3. Replace the content with the following:
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

     - job_name: containers
       static_configs:
         - targets:
             - localhost
           labels:
             job: containerlogs
             __path__: /var/lib/docker/containers/*/*.log

     - job_name: zabbix
       static_configs:
         - targets:
             - localhost
           labels:
             job: zabbix
             __path__: /var/log/zabbix/*.log

     - job_name: nginx
       static_configs:
         - targets:
             - localhost
           labels:
             job: nginx
             __path__: /var/log/nginx/*.log

     - job_name: mysql
       static_configs:
         - targets:
             - localhost
           labels:
             job: mysql
             __path__: /var/log/mysql/*.log
   ```

4. Save the file and restart Promtail:
   ```bash
   docker-compose restart promtail
   ```

5. Verify Promtail is running:
   ```bash
   docker-compose logs promtail | tail
   ```
   Look for any error messages in the output.

### 3.2 Set Up a Log Generator

Let's generate some sample logs to have data for our monitoring:

1. Generate system logs:
   ```bash
   docker-compose exec zabbix-agent bash -c 'for i in {1..20}; do logger "INFO: System check completed successfully at $(date)"; sleep 1; done'
   ```

2. Generate some error logs:
   ```bash
   docker-compose exec zabbix-agent bash -c 'for i in {1..5}; do logger "ERROR: Database connection timeout at $(date)"; sleep 1; done'
   ```

3. Generate web server logs by making HTTP requests:
   ```bash
   for i in {1..10}; do curl http://localhost:8080/ >/dev/null 2>&1; curl http://localhost:8080/login.php >/dev/null 2>&1; sleep 1; done
   ```

### 3.3 Create a Log Analysis Dashboard in Grafana

Now, let's create a dashboard for log analysis:

1. Navigate to **Dashboards** → **New Dashboard**.

2. Click **Add new panel**.

3. Select **Loki** as the data source.

4. Enter a LogQL query to view system logs:
   ```
   {job="varlogs"}
   ```

5. Configure the panel:
   - Title: **System Logs**
   - Visualization: Select **Logs**
   - Click **Apply**

6. Add a panel for error logs:
   - Click **Add new panel**
   - Select **Loki** as the data source
   - Enter this LogQL query:
     ```
     {job="varlogs"} |= "ERROR"
     ```
   - Title: **Error Logs**
   - Visualization: Select **Logs**
   - Click **Apply**

7. Add a panel for log volume over time:
   - Click **Add new panel**
   - Select **Loki** as the data source
   - Enter this LogQL query:
     ```
     sum(count_over_time({job="varlogs"}[5m])) by (job)
     ```
   - Title: **Log Volume (5m intervals)**
   - Visualization: Select **Time series**
   - Click **Apply**

8. Add a panel for error rate:
   - Click **Add new panel**
   - Select **Loki** as the data source
   - Enter two queries:
     - A: `sum(count_over_time({job="varlogs"} |= "ERROR"[5m]))`
     - B: `sum(count_over_time({job="varlogs"}[5m]))`
   - In the Transform tab, add a "Reduce" transformation:
     - Mode: **Binary operation**
     - Operation: **A/B** (division)
     - Multiply by: **100** (to get percentage)
   - Title: **Error Rate (%)**
   - Visualization: Select **Gauge**
   - Click **Apply**

9. Save the dashboard:
   - Click the save icon (💾) in the top right
   - Name: **Log Analysis**
   - Folder: **Application Monitoring**
   - Click **Save**

### 3.4 Create LogQL Queries for Specific Patterns

LogQL is Loki's query language. Let's practice creating some advanced queries:

1. Add a new panel to your Log Analysis dashboard.

2. Select **Loki** as the data source.

3. Try the following LogQL queries:

   a. Filter by specific text patterns:
   ```
   {job="varlogs"} |= "connection" |= "timeout"
   ```

   b. Count occurrences of errors by time:
   ```
   count_over_time({job="varlogs"} |= "ERROR"[1h])
   ```

   c. Extract and count by error type using a regex pattern:
   ```
   sum by (error_type) (count_over_time({job="varlogs"} |~ "ERROR: ([a-zA-Z ]+)" [1h]))
   ```

4. Configure the panel:
   - Title: **Error Patterns**
   - Choose appropriate visualization based on the query
   - Click **Apply**

5. Save the dashboard.

### 3.5 Connect Logs to Metrics

The real power of a unified monitoring stack is connecting logs with metrics. Let's create a dashboard that shows this:

1. Navigate to **Dashboards** → **New Dashboard**.

2. Click **Add new panel**.

3. Create a layout with multiple panels:
   - CPU usage graph (from Zabbix)
   - System logs (from Loki)
   - Web response time (from Zabbix)
   - Web access logs (from Loki)

4. Use template variables to allow filtering by host:
   - Click the gear icon in the top right to access dashboard settings
   - Go to "Variables" and click "Add variable"
   - Name: **host**
   - Type: **Query**
   - Data source: **Zabbix**
   - Query type: **Host**
   - Click **Update**

5. Make your panels use the host variable by selecting it in the host dropdown.

6. Save the dashboard:
   - Name: **Unified Monitoring**
   - Folder: **Infrastructure Monitoring**
   - Click **Save**

---

## 4. Final Tasks and Verification (10 min)

### 4.1 Set Up Dashboard Rotation

For a NOC (Network Operations Center) display, you can set up automatic dashboard rotation:

1. Install the Dashboard Carousel plugin:
   ```bash
   docker-compose exec grafana grafana-cli plugins install smartmakers-trafficlight-panel
   docker-compose restart grafana
   ```

2. Navigate to **Dashboards** → **Playlists**.

3. Click **New playlist**.

4. Enter details:
   - Name: **Monitoring Overview**
   - Interval: **1m** (1 minute)
   - Select your dashboards to include
   - Click **Save**

5. To start the playlist, click the playlist and then click **Start playlist**.

### 4.2 Set Up Dashboard Sharing

Let's configure dashboard sharing for team access:

1. Navigate to **Configuration** → **Users**.

2. Click **Invite** to add a new viewer user.

3. Enter an email address and select the **Viewer** role.

4. Click **Submit**.

### 4.3 Verify the Complete Monitoring Stack

Let's make sure all components are working together:

1. Navigate through all your dashboards to verify they show data.

2. Generate some test events:
   ```bash
   # Generate CPU load
   docker-compose exec zabbix-agent stress --cpu 2 --timeout 60
   
   # Generate log events
   docker-compose exec zabbix-agent bash -c 'for i in {1..10}; do logger "WARNING: High CPU detected at $(date)"; sleep 1; done'
   ```

3. Verify that:
   - Metrics in Grafana show the spike in CPU
   - Logs in Loki show the warning messages
   - The unified dashboard shows both together

4. Try filtering data using dashboard variables.

### 4.4 Take Required Screenshots for Submission

As mentioned in the original lab plan, capture the following screenshots:

1. The Zabbix Host Configuration screen with items and triggers
2. Your System Monitoring Dashboard in Grafana
3. The Log Analysis Dashboard showing patterns and correlations