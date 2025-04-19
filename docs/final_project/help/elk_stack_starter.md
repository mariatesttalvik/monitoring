# 📚 ELK Stack - Easy Setup Guide

## 1. Basic Setup in docker-compose.yml
```yaml
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
    environment:
      - discovery.type=single-node      # Important! For single node setup
      - ES_JAVA_OPTS=-Xms512m -Xmx512m # Reduce memory usage for testing
    ports:
      - "9200:9200"
    volumes:
      - es_data:/usr/share/elasticsearch/data

  logstash:
    image: docker.elastic.co/logstash/logstash:7.17.0
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
      - ./logs:/logs               # Mount your logs directory
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:7.17.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch

volumes:
  es_data:
```

## 2. Simple Logstash Pipeline
```conf
# logstash/pipeline/simple.conf
input {
  file {
    path => "/logs/flask-app.log"
    type => "flask-logs"
    start_position => "beginning"
  }
}

# Easy filter for Flask logs
filter {
  grok {
    match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} - %{LOGLEVEL:log_level} - %{GREEDYDATA:message}" }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "flask-logs-%{+YYYY.MM}"
  }
}
```

## 3. Flask Logging Setup
```python
# In your Flask app
import logging

# Setup logging
logging.basicConfig(
    filename='logs/flask-app.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Example usage
@app.route('/')
def home():
    logging.info('Someone visited the homepage!')
    return "Hello!"

@app.route('/buy')
def buy():
    try:
        # Your code here
        logging.info('New purchase made!')
    except Exception as e:
        logging.error(f'Error during purchase: {str(e)}')
```

## 4. Quick Tests to Check Everything Works

### Check Elasticsearch:
```bash
# Should return 'green' or 'yellow'
curl localhost:9200/_cat/health

# See your indices
curl localhost:9200/_cat/indices
```

### Check Kibana:
1. Open http://localhost:5601
2. Go to "Stack Management" → "Index Patterns"
3. Create pattern: `flask-logs-*`

## 5. Common Problems & Solutions

### 🔴 Elasticsearch Won't Start
```bash
# Problem: Usually memory issues
# Solution: Add to docker-compose.yml
environment:
  - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
```

### 🔴 Can't See Logs
1. Check log file exists:
```bash
docker-compose exec logstash ls /logs
```

2. Check Logstash config:
```bash
docker-compose logs logstash
```

### 🔴 Kibana Shows No Data
1. Make sure index pattern matches your logs
2. Check timestamps in your logs
3. Adjust time range in Kibana

## 6. Cool Things to Try

### Basic Kibana Visualizations:
1. Count of Logs Over Time
   - Create visualization
   - Choose 'Line graph'
   - X-axis: @timestamp
   - Y-axis: Count

2. Logs by Level
   - Create visualization
   - Choose 'Pie chart'
   - Split slices: log_level

### Simple Dashboard:
1. Error Rate
2. Visitor Count
3. Recent Logs Table

## 7. Remember!
- Logs need time to show up
- Check docker-compose logs if stuck
- Start simple, add more later
- Keep log messages clear

## 8. Testing Your Setup

1. Generate some test logs:
```python
# In your Flask app
@app.route('/test-logs')
def test_logs():
    logging.info('Test log - Info message')
    logging.warning('Test log - Warning message')
    logging.error('Test log - Error message')
    return "Logs generated!"
```

2. View in Kibana:
- Go to Discover
- Select your index
- You should see the test logs!
