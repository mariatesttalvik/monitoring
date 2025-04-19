# # Lab 9: Elasticsearch Backup and Restore Operations

## Prerequisites
- Elasticsearch 8.x installed
- Basic understanding of Elasticsearch concepts
- Access to terminal/command line
- Minimum 4GB free disk space

## Lab Tasks

### Task 1: Setting Up File System Repository
```bash
# Step 1: Create a directory for backups
sudo mkdir -p /mnt/backups
sudo chown elasticsearch:elasticsearch /mnt/backups

# Step 2: Configure the path in elasticsearch.yml
echo "path.repo: [\"/mnt/backups\"]" | sudo tee -a /etc/elasticsearch/elasticsearch.yml

# Step 3: Restart Elasticsearch
sudo systemctl restart elasticsearch

# Step 4: Register the repository
curl -X PUT "localhost:9200/_snapshot/my_backup" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/mnt/backups/my_backup",
    "compress": true
  }
}'

# Step 5: Verify repository
curl -X POST "localhost:9200/_snapshot/my_backup/_verify"
```

### Task 2: Creating Sample Data
```bash
# Create test index
curl -X PUT "localhost:9200/customer_data" -H 'Content-Type: application/json' -d'
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 1
  }
}'

# Add sample documents
curl -X POST "localhost:9200/customer_data/_doc" -H 'Content-Type: application/json' -d'
{
  "name": "John Doe",
  "email": "john@example.com",
  "registration_date": "2024-01-13"
}'

curl -X POST "localhost:9200/customer_data/_doc" -H 'Content-Type: application/json' -d'
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "registration_date": "2024-01-14"
}'
```

### Task 3: Creating Snapshots
```bash
# Create snapshot of all indices
curl -X PUT "localhost:9200/_snapshot/my_backup/snapshot_1" -H 'Content-Type: application/json' -d'
{
  "indices": "*",
  "ignore_unavailable": true,
  "include_global_state": false
}'

# Monitor snapshot progress
curl -X GET "localhost:9200/_snapshot/my_backup/snapshot_1/_status"

# List all snapshots
curl -X GET "localhost:9200/_snapshot/my_backup/_all"
```

### Task 4: Simulating Data Loss and Recovery
```bash
# Delete the test index
curl -X DELETE "localhost:9200/customer_data"

# Verify index is gone
curl -X GET "localhost:9200/customer_data"

# Restore from snapshot
curl -X POST "localhost:9200/_snapshot/my_backup/snapshot_1/_restore" -H 'Content-Type: application/json' -d'
{
  "indices": "customer_data",
  "ignore_unavailable": true,
  "include_global_state": false
}'

# Verify restoration
curl -X GET "localhost:9200/customer_data/_search"
```

### Task 5: Implementing Automated Backup Policy
```bash
# Create snapshot lifecycle policy
curl -X PUT "localhost:9200/_slm/policy/daily_backup" -H 'Content-Type: application/json' -d'
{
  "schedule": "0 30 1 * * ?",
  "name": "<daily-snap-{now/d}>",
  "repository": "my_backup",
  "config": {
    "indices": ["*"],
    "ignore_unavailable": true,
    "include_global_state": false
  },
  "retention": {
    "expire_after": "30d",
    "min_count": 5,
    "max_count": 50
  }
}'

# Execute policy manually
curl -X POST "localhost:9200/_slm/policy/daily_backup/_execute"

# Check policy execution status
curl -X GET "localhost:9200/_slm/policy/daily_backup"
```

### Task 6: Repository Maintenance
```bash
# Clean up old snapshots
curl -X POST "localhost:9200/_snapshot/my_backup/_cleanup"

# Check repository status
curl -X POST "localhost:9200/_snapshot/my_backup/_verify"
```

## Troubleshooting Tips

### Common Issues and Solutions

1. **Repository Access Issues**
   ```bash
   # Check permissions
   ls -l /mnt/backups
   
   # Verify elasticsearch user ownership
   sudo chown -R elasticsearch:elasticsearch /mnt/backups
   ```

2. **Failed Snapshots**
   ```bash
   # Check cluster health
   curl -X GET "localhost:9200/_cluster/health"
   
   # Check snapshot status
   curl -X GET "localhost:9200/_snapshot/_status"
   ```

3. **Restore Failures**
   ```bash
   # Check available space
   df -h
   
   # Monitor restore progress
   curl -X GET "localhost:9200/_recovery"
   ```

## Additional Resources
- [Elasticsearch Snapshot and Restore Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html)
- [Snapshot Lifecycle Management](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-lifecycle-management.html)
- [Repository Plugins](https://www.elastic.co/guide/en/elasticsearch/plugins/current/repository.html)
