# ELK Stack with Docker

!!!!   with ssl ( certs are added)

Basic ELK (Elasticsearch, Logstash, Kibana) stack setup using Docker Compose.

## Setup

1. Clone repository:
```bash
git clone https://github.com/SimonBecker1997/ElasticCourse.git
cd ElasticCourse/01_Create_ELK_Deployment
```

2. Configure environment:
```bash
# Update .env file with:

```bash
ELASTIC_PASSWORD=elastic
KIBANA_PASSWORD=kibana
STACK_VERSION=8.1.0
CLUSTER_NAME=elastic-cluster
LICENSE=basic
ES_PORT=9200
KIBANA_PORT=5601
MEM_LIMIT=1073741824
```

3. Start services:
```bash
docker-compose up -d
```
```bash
# Docker permission error fix:
sudo usermod -aG docker $USER

Log Out and Back In After adding your user to the docker group, log out and log back in to apply the group changes.
```

## Access

- Elasticsearch: http://localhost:9200
- Kibana: http://localhost:5601

Default credentials:
- Username: elastic
- Password: changeme

## Common Issues

If Elasticsearch fails to start:
```bash
sysctl -w vm.max_map_count=262144
```