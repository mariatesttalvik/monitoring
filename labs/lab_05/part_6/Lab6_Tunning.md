# Lab 6: Elasticsearch Performance Tuning

## Prerequisites
- Sample dataset loaded

## Lab 1: Monitoring and Bottleneck Identification

### Exercise 1.1: Check Cluster Health
```bash
# Check overall health
GET /_cluster/health

# Get detailed node information
GET /_cat/nodes?v

# Check shard allocation
GET /_cat/shards?v
```

### Exercise 1.2: Configure and Analyze Slow Logs
1. Enable slow logs:
```bash
PUT /my_index/_settings
{
  "index.search.slowlog.threshold.query.warn": "1s",
  "index.search.slowlog.threshold.fetch.warn": "500ms",
  "index.indexing.slowlog.threshold.index.warn": "1s"
}
```

2. Run some queries and check logs:
```bash
# Search with a complex query
POST /my_index/_search
{
  "query": {
    "match_phrase": {
      "description": "high performance computing"
    }
  },
  "sort": [
    { "date": "desc" }
  ]
}
```

## Lab 2: Query Optimization

### Exercise 2.1: Query Profiling
```bash
# Profile a search query
POST /my_index/_search
{
  "profile": true,
  "query": {
    "match": {
      "description": "elasticsearch performance"
    }
  }
}
```

### Exercise 2.2: Filter Optimization
```bash
# Before optimization
POST /my_index/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "status": "active" } }
      ]
    }
  }
}

# After optimization (using filter)
POST /my_index/_search
{
  "query": {
    "bool": {
      "filter": [
        { "term": { "status": "active" } }
      ]
    }
  }
}
```

## Lab 3: Indexing Performance

### Exercise 3.1: Bulk Indexing
```bash
# Bulk index example
POST /_bulk
{ "index": { "_index": "performance_test", "_id": "1" }}
{ "field1": "value1", "timestamp": "2024-01-12" }
{ "index": { "_index": "performance_test", "_id": "2" }}
{ "field1": "value2", "timestamp": "2024-01-12" }
```

### Exercise 3.2: Optimize Index Settings
```bash
# Adjust index settings
PUT /performance_test/_settings
{
  "index": {
    "refresh_interval": "30s",
    "number_of_replicas": 1
  }
}
```

## Lab 4: Cluster Configuration

### Exercise 4.1: Shard Management
```bash
# Create index with custom sharding
PUT /scaled_index
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1,
    "index": {
      "routing.allocation.total_shards_per_node": 2
    }
  }
}
```

### Exercise 4.2: Memory Management
```bash
# Check memory usage
GET /_cat/nodes?v&h=heap.percent,ram.percent,cpu,load_1m

# Review field data usage
GET /_stats/fielddata?fields=*
```

## Lab 5: Performance Testing

### Exercise 5.1: Basic Load Test
Use the following Python script to generate load:

```python
from elasticsearch import Elasticsearch
import time
import random

es = Elasticsearch(['http://localhost:9200'])

def run_load_test(queries=1000, concurrent=10):
    start_time = time.time()
    for i in range(queries):
        es.search(index='performance_test',
                 body={
                     "query": {
                         "match_all": {}
                     }
                 })
        if i % 100 == 0:
            print(f"Completed {i} queries")
    
    end_time = time.time()
    print(f"Total time: {end_time - start_time} seconds")
```

### Exercise 5.2: Monitor Impact
While running load tests, monitor:
1. CPU usage
2. Memory consumption
3. Query latency
4. Thread pool stats

```bash
# Monitor thread pools
GET /_cat/thread_pool?v

# Check node stats
GET /_nodes/stats
```

## Practice Scenarios

### Scenario 1: High-Volume Logging
Optimize for ingesting 10,000 log events per second:

1. Configure bulk indexing
```bash
PUT /logs_index
{
  "settings": {
    "index": {
      "refresh_interval": "30s",
      "number_of_shards": 5,
      "number_of_replicas": 1,
      "translog": {
        "durability": "async",
        "sync_interval": "5s"
      }
    }
  }
}
```

2. Implement bulk processing
3. Monitor throughput

### Scenario 2: Search Optimization
Optimize a slow-running search query:

1. Profile the query
2. Add appropriate filters
3. Review and optimize mappings
4. Test improved query

### Scenario 3: Memory Issues
Resolve a high memory usage situation:

1. Check fielddata usage
2. Review heap usage
3. Optimize mappings
4. Monitor improvement

## Monitoring Checklist

During all exercises, monitor:
- [ ] Cluster health
- [ ] Node stats
- [ ] Search latency
- [ ] Indexing throughput
- [ ] Memory usage
- [ ] CPU utilization