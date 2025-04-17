# InfluxDB Local Lab (TICK Stack)

## Documentation Requirements
- Include screenshots for each major step

### Ecample of Required Screenshots
1. Initial Setup
2. Stack Deployment:
   - Docker containers running successfully
3. Component Access:
   - Working dashboards
4. Data and Monitoring:
   - Sample data being generated

## Lab Steps

## Prerequisites
- Docker and Docker Compose
- Git
- 4GB+ RAM available
- 10GB+ disk space

## Lab Setup Steps

### 1. Create Lab Directory Structure
```bash
mkdir influxdb-local-lab
cd influxdb-local-lab

# Create directories for persistent storage
mkdir -p {influxdb,telegraf,chronograf,kapacitor}/data
```

### 2. Docker Compose Configuration
Create `docker-compose.yml`:
```yaml
version: '3'
services:
  # InfluxDB
  influxdb:
    image: influxdb:latest
    ports:
      - "8086:8086"
    volumes:
      - ./influxdb/data:/var/lib/influxdb2
      - ./influxdb/config:/etc/influxdb2
    environment:
      - DOCKER_INFLUXDB_INIT_MODE=setup
      - DOCKER_INFLUXDB_INIT_USERNAME=admin
      - DOCKER_INFLUXDB_INIT_PASSWORD=adminpassword
      - DOCKER_INFLUXDB_INIT_ORG=myorg
      - DOCKER_INFLUXDB_INIT_BUCKET=default
      - DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=my-super-secret-auth-token

  # Telegraf
  telegraf:
    image: telegraf:latest
    volumes:
      - ./telegraf/telegraf.conf:/etc/telegraf/telegraf.conf:ro
    depends_on:
      - influxdb

  # Chronograf
  chronograf:
    image: chronograf:latest
    ports:
      - "8888:8888"
    volumes:
      - ./chronograf/data:/var/lib/chronograf
    depends_on:
      - influxdb
    environment:
      - INFLUXDB_URL=http://influxdb:8086
      - INFLUXDB_TOKEN=my-super-secret-auth-token
      - INFLUXDB_ORG=myorg

  # Kapacitor
  kapacitor:
    image: kapacitor:latest
    ports:
      - "9092:9092"
    volumes:
      - ./kapacitor/data:/var/lib/kapacitor
    depends_on:
      - influxdb
    environment:
      - KAPACITOR_INFLUXDB_0_URLS_0=http://influxdb:8086
```

### 3. Telegraf Configuration
Create `telegraf/telegraf.conf`:
```toml
[agent]
  interval = "10s"
  round_interval = true
  metric_buffer_limit = 10000
  flush_interval = "10s"
  flush_jitter = "0s"

[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "my-super-secret-auth-token"
  organization = "myorg"
  bucket = "default"

[[inputs.cpu]]
  percpu = true
  totalcpu = true

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs"]

[[inputs.mem]]

[[inputs.system]]
```

### 4. Start the Stack
```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps
```

### 5. Access Points
- InfluxDB UI: http://localhost:8086
  - Username: admin
  - Password: adminpassword
- Chronograf: http://localhost:8888
- Kapacitor: http://localhost:9092

### 6. Initial Setup Tasks

1. Create Additional Buckets:
   - Open InfluxDB UI
   - Go to "Data" → "Buckets"
   - Create buckets for different data types

2. Configure Chronograf:
   - Open Chronograf UI
   - Add InfluxDB connection
   - Create initial dashboards

3. Setup Kapacitor Alerts:
   - Configure alert endpoints
   - Create basic alert rules

### 7. Sample Data Generation
```bash
# Create sample data script
cat << EOF > generate_data.sh
#!/bin/bash
while true; do
  value=\$((RANDOM % 100))
  curl --request POST \
    "http://localhost:8086/api/v2/write?org=myorg&bucket=default" \
    --header "Authorization: Token my-super-secret-auth-token" \
    --data-raw "random_metric value=\${value}"
  sleep 5
done
EOF

chmod +x generate_data.sh
./generate_data.sh
```

### 8. Monitoring Setup

1. Create Basic Dashboard:
   - Open Chronograf
   - Create new dashboard
   - Add CPU, Memory, and Disk panels

2. Create Alert:
   - Go to Kapacitor
   - Create alert for high CPU usage
   - Configure notification channel

## Cleanup
```bash
# Stop services
docker-compose down

# Remove volumes
docker volume prune

# Remove data directories
rm -rf {influxdb,telegraf,chronograf,kapacitor}/data
```

## Troubleshooting

1. Check Services:
```bash
docker-compose ps
docker-compose logs
```

2. Verify Data Writing:
```bash
curl -v "http://localhost:8086/api/v2/write?org=myorg&bucket=default" \
  -H "Authorization: Token my-super-secret-auth-token" \
  -d "test,host=server01 value=42"
```

3. Reset Installation:
```bash
docker-compose down -v
rm -rf {influxdb,telegraf,chronograf,kapacitor}/data
docker-compose up -d
```