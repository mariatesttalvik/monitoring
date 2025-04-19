# Lab 7: Monitoring and Alerting with Elasticsearch

Practice setting up monitoring and alerting for an Elasticsearch cluster using the tools discussed.

## **Part 1: Set Up Monitoring API**
1. Install Elasticsearch if not already installed:
   ```bash
   sudo apt-get update
   sudo apt-get install -y elasticsearch
   ```
2. Enable the Monitoring plugin:
   ```bash
   ./bin/elasticsearch-plugin install x-pack
   ```
3. Update the `elasticsearch.yml` file:
   ```yaml
   xpack.monitoring.enabled: true
   xpack.security.enabled: true
   ```
4. Restart the Elasticsearch service:
   ```bash
   sudo systemctl restart elasticsearch
   ```

## **Part 2: Configure Prometheus**
1. Download and install Prometheus:
   ```bash
   wget https://github.com/prometheus/prometheus/releases/download/v2.43.0/prometheus-2.43.0.linux-amd64.tar.gz
   tar -xvzf prometheus-2.43.0.linux-amd64.tar.gz
   cd prometheus-2.43.0.linux-amd64
   ```
2. Create a Prometheus configuration file (`prometheus.yml`):
   ```yaml
   global:
     scrape_interval: 15s

   scrape_configs:
     - job_name: 'elasticsearch'
       static_configs:
         - targets: ['localhost:9200']
   ```
3. Start Prometheus using the configuration file:
   ```bash
   ./prometheus --config.file=prometheus.yml
   ```
4. Verify Prometheus is running by visiting `http://<your_server_ip>:9090`.

## **Part 3: Configure Grafana**
1. Install Grafana:
   ```bash
   sudo apt-get install -y grafana
   ```
2. Start and enable the Grafana service:
   ```bash
   sudo systemctl start grafana-server
   sudo systemctl enable grafana-server
   ```
3. Open Grafana in your browser: `http://<your_server_ip>:3000`.
4. Log in with default credentials (user: `admin`, password: `admin`).
5. Add Prometheus as a data source in Grafana:
   - Navigate to **Configuration > Data Sources**.
   - Click **Add data source** and select **Prometheus**.
   - Enter `http://localhost:9090` and click **Save & Test**.
6. Import or create a dashboard:
   - Navigate to **Dashboards > Import**.
   - Use an existing ID or upload a JSON file.

## **Part 4: Define Alerting Rules**
1. Add an alerting rule in Prometheus to monitor CPU usage:
   ```yaml
   alerting:
     alert: HighCPUUsage
     expr: process_cpu_seconds_total > 0.8
     for: 2m
   ```
2. Save and reload the Prometheus configuration.
3. Set up notification channels in Grafana (email or Slack):
   - Go to **Alerting > Notification Channels**.
   - Click **New Channel** and configure the channel with required details.

## **Exercises**

1. **Cluster Health Check**
   - Open a terminal on the server running Elasticsearch.
   - Run the following command to check cluster health:
     ```bash
     curl -X GET 'http://localhost:9200/_cluster/health?pretty'
     ```
   - Look for the `status` field in the output:
     - `green`: All is well.
     - `yellow`: Replica shards are not fully allocated (not critical but requires attention).
     - `red`: Some primary shards are unallocated (critical, requires immediate action).
   - If `yellow` or `red`, troubleshoot the issue:
     - Check for unassigned shards:
       ```bash
       curl -X GET 'http://localhost:9200/_cat/shards?v'
       ```
     - Reallocate shards if needed:
       ```bash
       curl -X POST 'http://localhost:9200/_cluster/reroute?pretty' -H 'Content-Type: application/json' -d'
       {
         "commands": [
           {
             "allocate_stale_primary": {
               "index": "<index_name>",
               "shard": <shard_number>,
               "node": "<node_name>",
               "accept_data_loss": true
             }
           }
         ]
       }'
       ```

2. **Monitor Index Performance**
   - Open a terminal on the server running Elasticsearch.
   - Query all indices and their metrics:
     ```bash
     curl -X GET 'http://localhost:9200/_cat/indices?v'
     ```
   - Analyze key metrics in the output:
     - `docs.count`: Number of documents in the index.
     - `store.size`: Disk space used by the index.
     - `health`: Should be `green`. If not, investigate.
   - If performance issues are noted:
     - Optimize the index:
       ```bash
       curl -X POST 'http://localhost:9200/<index_name>/_forcemerge?max_num_segments=1'
       ```
     - Check for high latency or slow queries using the slow logs in Elasticsearch.

3. **Create a Custom Dashboard in Grafana**
   - Log in to Grafana (`http://<your_server_ip>:3000`).
   - Navigate to **Dashboards > New Dashboard**.
   - Add a panel for JVM Heap Usage:
     - Choose **Prometheus** as the data source.
     - Query:
       ```promql
       jvm_memory_used_bytes{area="heap"}
       ```
     - Set visualization to a graph.
   - Add a panel for Search Latency:
     - Query:
       ```promql
       elasticsearch_search_latency_milliseconds
       ```
     - Set thresholds (e.g., warning at 100ms, critical at 300ms).
   - Save the dashboard for future monitoring.

4. **Trigger and Resolve Alerts**
   - Simulate high CPU usage using `stress-ng` (ensure the `stress-ng` tool is installed):
     ```bash
     sudo apt-get install -y stress-ng
     stress-ng --cpu 4 --timeout 60
     ```
   - Open Prometheus and Grafana to verify the alert is triggered.
   - Respond to the alert:
     - Identify the root cause (check CPU, memory, and logs).
     - Restart the affected Elasticsearch node if necessary:
       ```bash
       sudo systemctl restart elasticsearch
       ```
   - Document the resolution steps for future reference.
