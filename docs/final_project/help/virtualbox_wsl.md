# 🌐 Accessing Your Services: VirtualBox & WSL Guide

## For VirtualBox Users

### 1. Network Setup
```bash
# Check your VM's IP
ip addr show
# or
ifconfig
```

### 2. Port Forwarding in VirtualBox
1. Open VirtualBox Manager
2. Select your VM → Settings → Network
3. Click "Port Forwarding"
4. Add these rules:
```
Name     | Protocol | Host Port | Guest Port
---------|----------|-----------|------------
Flask    | TCP      | 5000      | 5000
Grafana  | TCP      | 3000      | 3000
Kibana   | TCP      | 5601      | 5601
Prom     | TCP      | 9090      | 9090
```

### 3. Access Services
From your host computer, use:
- Flask: http://localhost:5000
- Grafana: http://localhost:3000
- Kibana: http://localhost:5601
- Prometheus: http://localhost:9090

## For WSL Users

### 1. Find WSL IP
```bash
# In WSL terminal
ip addr show eth0
# Look for inet line, like: 172.x.x.x
```

### 2. Service Access
Option 1: Use WSL IP
```bash
# Example URLs using WSL IP
http://172.x.x.x:5000  # Flask
http://172.x.x.x:3000  # Grafana
http://172.x.x.x:5601  # Kibana
http://172.x.x.x:9090  # Prometheus
```

Option 2: Use localhost (Windows 11)
- Windows 11 automatically forwards localhost
- Use same as regular localhost access

### 3. Docker Compose Changes
```yaml
services:
  web:
    ports:
      - "0.0.0.0:5000:5000"  # Important! Add 0.0.0.0
    # ... other config

  grafana:
    ports:
      - "0.0.0.0:3000:3000"  # Important! Add 0.0.0.0
    # ... other config
```

## Common Problems & Solutions

### 🔴 Can't Access Services
1. Check if services are running:
```bash
docker ps
docker-compose ps
```

2. Verify ports are open:
```bash
sudo netstat -tulpn | grep LISTEN
```

3. Check firewall:
```bash
# Ubuntu/Debian
sudo ufw status

# Check Windows Firewall too!
```

### 🔴 Fixed IP Setup (Optional)
For VirtualBox, add to `/etc/netplan/01-netcfg.yaml`:
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
          addresses: [8.8.8.8, 8.8.4.4]
```

### 🔴 Quick Test Script
Save as `test-ports.sh`:
```bash
#!/bin/bash
echo "Testing ports..."

ports=(5000 3000 5601 9090)
for port in "${ports[@]}"; do
    nc -zv localhost $port
done
```

## Remember!
- Always use 0.0.0.0 in port bindings
- Check both host and VM firewalls
- Note down your VM/WSL IP
- Test access from both inside and outside
