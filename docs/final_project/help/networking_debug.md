# 🔧 Network Troubleshooting Guide

## Quick Fixes

### 1. Can't Access From Host
```bash
# 1. Check if service is running
docker ps

# 2. Check actual port binding
docker port [container_name]

# 3. Test locally in VM/WSL
curl localhost:5000

# 4. Check Docker network
docker network ls
docker network inspect [network_name]
```

### 2. Common Solutions
```yaml
# In docker-compose.yml
services:
  web:
    ports:
      - "0.0.0.0:5000:5000"  # Add 0.0.0.0!
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

### 3. Test Commands
```bash
# Test if port is open
nc -zv localhost 5000

# Check what's using ports
sudo lsof -i :5000

# See all listening ports
sudo ss -tulpn
```

## Easy Commands to Remember

### In VM/WSL:
```bash
# Get your IP
ip addr show

# Test web server
curl localhost:5000

# Check Docker containers
docker ps
```

### On Windows Host:
```powershell
# Test connection
Test-NetConnection -ComputerName localhost -Port 5000

# Find VM/WSL IP
ipconfig
```

## Common Problems

1. "Connection refused"
   - Check if service is running
   - Verify port forwarding
   - Check firewall

2. "Can't connect to docker daemon"
   - Start docker service:
   ```bash
   sudo service docker start
   ```

3. "Port already in use"
   - Find and stop process:
   ```bash
   sudo lsof -i :5000
   sudo kill [PID]
   ```