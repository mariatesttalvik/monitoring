# ELK Stack with Docker

!!!!   with ssl ( certs are added)

**Prerequisites**

For full cluster resources:
4 CPUs (-c 4)
8 GB RAM (-m 8G)
50 GB Disk (-d 50G)

Basic ELK (Elasticsearch, Logstash, Kibana) stack setup using Docker Compose.

## Setup

1. Clone repository:
```bash
git clone https://github.com/SimonBecker1997/ElasticCourse.git
cd ElasticCourse/01_Create_ELK_Deployment
```

2. Configure environment in .env, if needed.


3. Start services:
```bash
docker compose up -d
```
```bash
# Docker permission error fix:
sudo usermod -aG docker $USER

Log Out and Back In After adding your user to the docker group, log out and log back in to apply the group changes.
```

## Access

- Elasticsearch: http://localhost:9200
- Kibana: http://localhost:5601

Default credentials ( from .env file):
- Username: elastic
- Password: elastic

## Common Issues

If Elasticsearch fails to start:
```bash
sysctl -w vm.max_map_count=262144
```