```mermaid
graph TD
    A[Flask App] -->|sends metrics| B[Prometheus]
    A -->|sends logs| C[ELK Stack]
    B -->|visualizes| D[Grafana]
    C -->|visualizes| E[Kibana]
    F[Zabbix] -->|monitors| A
    
    style A fill:#90EE90
    style B fill:#FFB6C1
    style C fill:#ADD8E6
    style D fill:#DDA0DD
    style E fill:#F0E68C
    style F fill:#FFA07A
```