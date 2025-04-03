# InfluxDB Cloud Observability Lab

Source: [Gain Better Observability with OpenTelemetry and InfluxDB (PDF)](https://get.influxdata.com/rs/972-GDU-533/images/Gain-Better-Observability-with-OpenTelemetry-and-InfluxDB.pdf?version=0)

## Documentation Requirements
- Include screenshots for each major step

### Required Screenshots
1. InfluxDB Cloud Setup:
   - Account creation confirmation
2. Demo Application Setup:
   - Docker containers running
3. Application Access:
   - InfluxDB Cloud interface

## Prerequisites
- Docker and Docker Compose
- Git
- Web browser
- Terminal/Command prompt

## Lab Setup Steps

### 1. InfluxDB Cloud Account Setup
1. Sign up at www.influxdata.com/cloud
   - Choose Free Tier
   - Or use cloud marketplace (AWS, GCP, Azure)
   - Complete email verification

2. Create Buckets:
   ```
   Bucket 1:
   - Name: otel
   - Retention: 30 days (free tier default)

   Bucket 2:
   - Name: otel-archival
   - Retention: Maximum allowed in your tier
   ```

3. Get Access Credentials:
   - Go to "Load Data" → "API Tokens"
   - Create new API token with read/write access
   - Save the token securely
   - Note your Organization ID from Settings

### 2. Demo Application Setup
```bash
# Clone repository
git clone https://github.com/InfluxCommunity/influxdb-observability
cd influxdb-observability

# Create and edit .env file
cp .env.example .env

# Add your cloud credentials:
INFLUXDB_ADDR=your-region.cloud2.influxdata.com
INFLUXDB_TOKEN=your_token_here
INFLUXDB_ORG=your_org_here
INFLUXDB_BUCKET=otel
INFLUXDB_BUCKET_ARCHIVE=otel-archival
```

### 3. Docker Components
```bash
# Start the demo stack
docker-compose --file demo/docker-compose.yml --project-directory . up -d

# Verify containers
docker ps
```

### 4. Access Points
- HotRod App: http://localhost:8080
- Grafana: http://localhost:3000 (admin/admin)
- Jaeger UI: http://localhost:16686
- InfluxDB Cloud: Your cloud URL

### 5. Generate & View Data
1. Create traces:
   - Open HotRod application
   - Click on customer entries
   - Perform different actions

2. View in Grafana:
   - Import dashboard from demo/grafana/dashboards/
   - Configure InfluxDB data source
   - View metrics and traces

3. Analyze in Jaeger:
   - Open Jaeger UI
   - Search for traces
   - View service dependencies

## Cleanup
```bash
# Stop containers
docker-compose down

# Remove volumes (optional)
docker volume prune
```