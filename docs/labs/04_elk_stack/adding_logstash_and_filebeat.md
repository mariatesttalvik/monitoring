# Adding Logstash and Filebeat to Docker-based Elastic Stack

This guide assumes you already have Elasticsearch and Kibana running in Docker containers on the `elastic` network, with security disabled for testing purposes.

## Prerequisites
- Docker and Docker Compose installed
- Elasticsearch container running (named `es01`)
- Kibana container running (named `kib01`)
- Docker network `elastic` created

## 1. Setting Up Logstash

### 1.1. Create Configuration Directory
```bash
# Create directory for Logstash configs
mkdir -p ~/elk/logstash/config
cd ~/elk/logstash/config
```

### 1.2. Create Logstash Configuration Files

#### Create pipeline configuration file
```bash
# Create logstash.yml
cat << EOF > logstash.yml
http.host: "0.0.0.0"
xpack.monitoring.enabled: true
xpack.monitoring.elasticsearch.hosts: ["http://es01:9200"]
EOF
```

#### Create input configuration
```bash
# Create 02-beats-input.conf
cat << EOF > 02-beats-input.conf
input {
  beats {
    port => 5044
    host => "0.0.0.0"
  }
}
EOF
```

#### Create filter configuration
```bash
# Create 10-syslog-filter.conf
cat << EOF > 10-syslog-filter.conf
filter {
  if [container][name] {
    mutate {
      add_field => {
        "container_name" => "%{[container][name]}"
      }
    }
  }
  
  if [message] {
    grok {
      match => { "message" => "%{GREEDYDATA:log_message}" }
    }
  }
}
EOF
```

#### Create output configuration
```bash
# Create 30-elasticsearch-output.conf
cat << EOF > 30-elasticsearch-output.conf
output {
  elasticsearch {
    hosts => ["http://es01:9200"]
    index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
  }
}
EOF
```

### 1.3. Start Logstash Container
```bash
docker run -d \
  --name logstash01 \
  --net elastic \
  -v ~/elk/logstash/config/logstash.yml:/usr/share/logstash/config/logstash.yml \
  -v ~/elk/logstash/config:/usr/share/logstash/pipeline/ \
  -p 5044:5044 \
  docker.elastic.co/logstash/logstash:8.17.0
```

### 1.4. Verify Logstash is Running
```bash
# Check container status
docker ps | grep logstash01

# Check logs for any errors
docker logs logstash01
```

## 2. Setting Up Filebeat

### 2.1. Create Configuration Directory
```bash
# Create directory for Filebeat configs
mkdir -p ~/elk/filebeat/config
cd ~/elk/filebeat/config
```

### 2.2. Create Filebeat Configuration
```bash
# Create filebeat.yml
cat << EOF > filebeat.yml
filebeat.inputs:
- type: container
  paths: 
    - '/var/lib/docker/containers/*/*.log'

processors:
  - add_docker_metadata:
      host: "unix:///var/run/docker.sock"

filebeat.config.modules:
  path: \${path.config}/modules.d/*.yml
  reload.enabled: false
  
output.logstash:
  hosts: ["logstash01:5044"]
  
logging.json: true
logging.metrics.enabled: false
EOF
```

### 2.3. Start Filebeat Container
```bash
docker run -d \
  --name filebeat01 \
  --net elastic \
  --user root \
  --volume="/var/lib/docker/containers:/var/lib/docker/containers:ro" \
  --volume="/var/run/docker.sock:/var/run/docker.sock:ro" \
  --volume="~/elk/filebeat/config/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro" \
  docker.elastic.co/beats/filebeat:8.17.0
```

### 2.4. Verify Filebeat is Running
```bash
# Check container status
docker ps | grep filebeat01

# Check logs for any errors
docker logs filebeat01
```

## 3. Verifying the Setup

### 3.1. Check Data Flow
1. Wait a few minutes for data to flow through the pipeline
2. Access Kibana at `http://localhost:5601`
3. Go to Stack Management → Index Management
4. You should see indices with pattern `filebeat-*`

### 3.2. Create Index Pattern in Kibana
1. Go to Stack Management → Index Patterns
2. Click "Create index pattern"
3. Enter `filebeat-*` as the pattern
4. Select `@timestamp` as the timestamp field
5. Click "Create index pattern"

### 3.3. View Data in Kibana
1. Go to Discover in Kibana
2. Select your `filebeat-*` index pattern
3. You should see container logs appearing

## 4. Useful Docker Commands

### View Container Logs
```bash
# View Logstash logs
docker logs logstash01

# View Filebeat logs
docker logs filebeat01
```

### Container Management
```bash
# Stop containers
docker stop logstash01 filebeat01

# Start containers
docker start logstash01 filebeat01

# Restart containers
docker restart logstash01 filebeat01

# Remove containers
docker rm -f logstash01 filebeat01
```

### Check Container Status
```bash
# View all running containers
docker ps

# View all containers including stopped ones
docker ps -a
```

## 5. Troubleshooting

### Common Issues and Solutions

1. **Logstash not starting:**
   - Check logs: `docker logs logstash01`
   - Verify config syntax: 
     ```bash
     docker exec logstash01 logstash -t
     ```

2. **Filebeat not sending data:**
   - Check connection to Logstash:
     ```bash
     docker exec filebeat01 filebeat test output
     ```
   - Verify file permissions on mounted volumes

3. **No data in Elasticsearch:**
   - Check Logstash output config
   - Verify Elasticsearch is running: `curl localhost:9200`

### Resetting the Setup
If you need to start fresh:

```bash
# Stop and remove containers
docker stop logstash01 filebeat01
docker rm logstash01 filebeat01

# Remove old config directories
rm -rf ~/elk/logstash/config/*
rm -rf ~/elk/filebeat/config/*

# Follow setup steps again from beginning
```

## 6. Additional Configuration Options

### Enable Specific Filebeat Modules
To enable system module for collecting system logs:

```bash
# Access Filebeat container
docker exec -it filebeat01 bash

# Enable system module
filebeat modules enable system

# Restart Filebeat
exit
docker restart filebeat01
```

### Add Custom Logstash Filters
To add custom processing, modify `10-syslog-filter.conf` with additional filters:

```conf
filter {
  if [container][name] {
    mutate {
      add_field => {
        "container_name" => "%{[container][name]}"
      }
    }
  }
  
  # Add custom filters here
  if [log_message] =~ "error" {
    mutate {
      add_tag => ["error_log"]
    }
  }
}
```

Remember to restart Logstash after config changes:
```bash
docker restart logstash01
```
