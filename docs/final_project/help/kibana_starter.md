# 📊 Easy Kibana Visualizations Guide

## 1. Error Rate Over Time
1. Click 'Visualize'
2. Choose 'Line'
3. Select your index
4. Set up metrics:
   - Y-axis: Count
   - X-axis: Date Histogram
   - Filter: `log_level: ERROR`

## 2. Log Levels Pie Chart
1. Click 'Visualize'
2. Choose 'Pie'
3. Select your index
4. Split Slices:
   - Field: log_level
   - Size: 5

## 3. Recent Logs Table
1. Click 'Visualize'
2. Choose 'Data Table'
3. Add columns:
   - @timestamp
   - log_level
   - message
4. Sort by timestamp

## 4. Sample Dashboard Layout
```
+-----------------+-----------------+
|   Error Rate    |   Log Levels   |
|   Line Chart    |   Pie Chart    |
+-----------------+-----------------+
|      Recent Logs Table           |
|                                 |
+---------------------------------+
```

## 5. Useful Search Queries
```
# Find errors
log_level:ERROR

# Find specific actions
message:"visited homepage"

# Time-based query
@timestamp > now-1h
```

Remember:
- Start with simple visualizations
- Use filters to focus on important data
- Save your visualizations
- Group them in a dashboard