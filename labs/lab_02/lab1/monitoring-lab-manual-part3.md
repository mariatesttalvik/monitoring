# Monitoring Lab Manual - Part 3: Grafana Configuration and Log Monitoring

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

### 1.2 Installing Required Plugins

Grafana's functionality can be extended with plugins. Let's install the plugins we need:

1. In the Grafana interface, navigate to the left sidebar and click the gear icon (⚙️) to open the **Configuration** menu.

2. Select **Plugins**.

3. In the search box, type "Zabbix" and press Enter.

4. Find the "Zabbix" plugin in the search results and click on it.

5. Click the **Install** button.

6. After installation completes, click **Restart Grafana** when prompted.

7. After Grafana restarts, log in again and return to **Configuration** → **Plugins**.

8. Search for and install these additional plugins one by one:
   - "Treemap Panel" (by Marcus Olsson)
   - "Pie Chart" (if not already included)
   - "Stat" (if not already included)

9. Alternatively, you can install plugins via CLI in the Docker container:
   ```bash
   docker-compose exec grafana grafana-cli plugins install marcusolsson-treemap-panel
   docker-compose restart grafana
   ```

### 1.3 Add Zabbix as a Data Source

Now, let's connect Grafana to our Zabbix monitoring system:

1. In the Grafana interface, navigate to **Configuration** → **Data Sources**.

2. Click **Add data source**.

3. Search for "Zabbix" and select it from the list.

4. Enter the following settings:
   - Name: **Zabbix**
   - URL: **http://zabbix-web:8080/api_jsonrpc.php**
   - Access: **Server (default)**
   - Zabbix API details:
     - Username: **Admin**
     - Password: *[The password you set in Part 2]*
   - Direct DB Connection: **Disable**
   - Trends: **Enable**
   - Cache TTL: **1h**
   - Timeout: **30**

5. Click **Save & Test**.

   You should see a green message indicating a successful connection to the Zabbix API.

### 1.4 Add Loki as a Data Source

Next, let's add Loki for log monitoring:

1. Navigate to **Configuration** → **Data Sources** again.

2. Click **Add data source**.

3. Search for "Loki" and select it from the list.

4. Enter the following settings:
   - Name: **Loki**
   - URL: **http://loki:3100**
   - Access: **Server (default)**

5. Under **Additional settings**:
   - Maximum lines: **1000**
   - Derived fields: Leave empty for now

6. Click **Save & Test**.

   You should see a green message indicating a successful connection to Loki.

---

## 2. Advanced Grafana Dashboards (20 min)

### 2.1 Import a System Monitoring Dashboard

Let's start by importing a pre-built dashboard for system monitoring:

1. In the Grafana interface, navigate to **Dashboards** → **Import** (from the "+" icon in the sidebar).

2. You can either:
   - Enter the dashboard ID **10047** (a popular Zabbix Linux server dashboard)
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

Now, let's create a custom dashboard for monitoring our MySQL database:

1. Navigate to **Dashboards** → **New Dashboard** (from the "+" icon in the sidebar).

2. Click **Add new panel**.

3. In the query editor:
   - Select **Zabbix** as the data source
   - Group: Select your database host group
   - Host: Select your MySQL database host
   - Application: Select **MySQL**
   - Item: Select **MySQL connections**
   - Click **Apply**

4. Configure the panel:
   - Title: **MySQL Connections**
   - Visualization: Select **Time series**
   - In the right sidebar, scroll to **Standard options**:
     - Unit: **short (1)**
     - Min: **0**
     - Decimals: **0**
   - Click **Apply**

5. Add another panel for MySQL queries:
   - Click the **Add panel** button in the top right
   - Click **Add new panel**
   - Select **Zabbix** as the data source
   - Configure similar to before, but select **MySQL queries** as the item
   - Title: **MySQL Queries Per Second**
   - Click **Apply**

6. Add a Treemap panel for database size visualization:
   - Click **Add new panel** again
   - Select **Zabbix** as the data source
   - Group: Select your database host group
   - Host: Select your MySQL database host
   - Application: Select **MySQL**
   - Item: Select multiple items related to database size (use Ctrl+click to select multiple)
   - On the right side, change the visualization to **Treemap**
   - Title: **Database Size Breakdown**
   - Click **Apply**

7. Save the dashboard:
   - Click the save icon (💾) in the top right
   - Name: **MySQL Monitoring**
   - Click **Save**

### 2.3 Create a Web Monitoring Dashboard

Now, let's create a dashboard for our synthetic web monitoring:

1. Navigate to **Dashboards** → **New Dashboard**.

2. Click **Add new panel**.

3. In the query editor:
   - Select **Zabbix** as the data source
   - Group: Select your web host group
   - Host: Select your web server host
   - Application: Select **Web monitoring**
   - Item: Select **Response time** for your user journey
   - Click **Apply**

4. Configure the panel:
   - Title: **User Journey Response Time**
   - Visualization: Select **Time series**
   - In the right sidebar, scroll to **Standard options**:
     - Unit: **s (seconds)**
     - Min: **0**
   - Click **Apply**

5. Add a panel for step-by-step response times:
   - Click **Add new panel**
   - Configure similar to before, but select response times for individual steps
   - Use the **Multiple queries** option to add all steps to one graph
   - Title: **Step-by-Step Response Times**
   - Click **Apply**

6. Add a status panel:
   - Click **Add new panel**
   - Configure similar to before, but select the web check failure item
   - Change visualization to **Stat**
   - Title: **Web Availability**
   - In Thresholds settings, set:
     - 0 = Green
     - 1 = Red
   - Click **Apply**

7. Save the dashboard:
   - Click the save icon (💾) in the top right
   - Name: **Web Monitoring**
   - Click **Save**

### 2.4 Organize Dashboards

Let's create a folder structure for our dashboards:

1. Navigate to **Dashboards** → **Manage**.

2. Click **New Folder**.

3. Name it **Infrastructure Monitoring** and click **Create**.

4. Create another folder named **Application Monitoring**.

5. Move your dashboards to the appropriate folders:
   - System Monitoring Dashboard → Infrastructure Monitoring
   - MySQL Monitoring → Infrastructure Monitoring
   - Web Monitoring → Application Monitoring

6. Create a simple home dashboard:
   - Navigate to **Dashboards** → **New Dashboard**
   - Click **Add new row**
   - Name it **Monitoring Overview**
   - Add text panels with links to your other dashboards
   - Save it as **Home** and star it (click the star icon)

---

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
3. The Treemap Visualization of System Resources
4. The Log Analysis Dashboard showing patterns and correlations

---

## Troubleshooting Tips

### Grafana Issues
- If panels show "No data", check the data source configuration and test connections
- Verify time ranges are set appropriately (top-right corner of dashboards)
- Check that the Zabbix plugin is installed and configured correctly

### Loki/Promtail Issues
- If logs aren't appearing, check Promtail's configuration and permissions
- Verify Promtail can access the log files you're trying to monitor
- Check Loki's status with `docker-compose logs loki | tail`

### Dashboard Import Issues
- If dashboard import fails, make sure you're using a compatible version
- Some dashboards may require specific plugins or data sources
- Verify that all required variables are set correctly

---

## Conclusion

Congratulations! You have completed the entire Monitoring Lab. You now have a comprehensive monitoring stack that includes:

- Zabbix for infrastructure and application monitoring
- Synthetic monitoring for end-user experience
- Grafana for powerful visualization and dashboarding
- Loki and Promtail for centralized log management

This multi-layered approach gives you complete visibility into your infrastructure and applications, allowing you to:
- Detect issues before they impact users
- Quickly diagnose problems when they occur
- Understand long-term trends and performance patterns
- Create meaningful visualizations for different stakeholders

In a production environment, you would continue to:
- Refine your dashboards for specific needs
- Set up alerting and notification channels
- Implement high availability for the monitoring stack
- Expand monitoring to cover more systems and applications

The skills you've learned in this lab provide a foundation for implementing comprehensive monitoring solutions in real-world environments.
