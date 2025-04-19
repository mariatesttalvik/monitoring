# Prometheus Lab Part 2: App Instrumentation and Metric Guidelines

## Generating Metrics

Let's instrument a simple Python application to generate Prometheus metrics:

```bash
# Install required packages
sudo apt-get install python3-pip
sudo pip install prometheus_client

# Create instrumentation directory
mkdir -p instrumentation
cd instrumentation
```

Create a test HTTP server with Prometheus metrics:

```bash
# Create a Python file for our test server
cat > httpserver_test.py << EOF
import http.server
from prometheus_client import start_http_server

class myHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'Hello, world!')

if __name__ == '__main__':
    start_http_server(5001)
    server = http.server.HTTPServer(('0.0.0.0', 5000), myHandler)
    server.serve_forever()
EOF
```

Set up a Python virtual environment to run our server:

```bash
# Create and activate a virtual environment
python3 -m venv venv
source venv/bin/activate

# Install prometheus_client in the virtual environment
pip install prometheus_client

# Run the server
python httpserver_test.py
```

You can now access:
- The web server: http://localhost:5000
- The metrics endpoint: http://localhost:5001/metrics

## The Counter

Let's modify our test server to add a counter for requests:

```bash
# Update the Python file to add a counter
cat > httpserver_test.py << EOF
import http.server
from prometheus_client import start_http_server, Counter

REQUESTS = Counter('test_requests_total', 'Total GET requests for our test server.')

class myHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        REQUESTS.inc()
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'Hello, world!')

if __name__ == '__main__':
    start_http_server(5001)
    server = http.server.HTTPServer(('0.0.0.0', 5000), myHandler)
    server.serve_forever()
EOF

# Run the updated server
python httpserver_test.py
```

Now, each time you access http://localhost:5000, the counter will increment. You can see the counter value at http://localhost:5001/metrics.

![Counter metric](images/image58.png)

Let's also create a symlink to the Prometheus configuration for easier access:

```bash
# Create a symlink to prometheus.yml
sudo ln -s $(pwd)/docker-compose/prometheus/config/prometheus.yml prom-config
```

Now, let's add our test server to Prometheus:

```bash
# Edit the Prometheus configuration
cat >> prom-config << EOF

  - job_name: 'test'
    static_configs:
      - targets:
        - localhost:5001
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

Let's run our test server in the background and generate some traffic:

```bash
# Run the server in the background
python instrumentation/httpserver_test.py &

# Create a script to generate traffic
cat > instrumentation/curler.sh << EOF
#!/bin/bash

while :
do
    curl http://localhost:5000/
    sleep \$((RANDOM % 300 ))
done
EOF

# Make the script executable
chmod 770 instrumentation/curler.sh

# Run the script
./instrumentation/curler.sh &
```

Now, you can view the metrics in Prometheus at http://localhost:9090/graph and query:
- `test_requests_total`: To see the total number of requests
- `rate(test_requests_total[5m])`: To see the rate of requests over the last 5 minutes

![Metrics in Prometheus](images/image60.png)

## The 4 Metric Types

Prometheus supports four main metric types:

1. **Counter**: Monotonically increasing value (e.g., request count)
2. **Gauge**: Values that can go up and down (e.g., memory usage)
3. **Summary**: Calculates configurable quantiles over a sliding time window (e.g., request durations)
4. **Histogram**: Samples observations and counts them in configurable buckets (e.g., request durations with bucketing)

![Metric Types](images/image61.png)

## Approaching Instrumentation

When instrumenting applications, consider three main categories:

1. **Online Serving Systems** (e.g., web servers, databases):
   - Monitor using the "RED method": Request rate, Error rate, and Response Duration

2. **Offline Serving Systems** (e.g., batch processing):
   - Monitor using the "USE method": Utilization, Saturation, and Error rate

3. **Batch Jobs**:
   - Monitor using Prometheus Pushgateway
   - Track total run duration, duration per stage, and last successful run time

## Metric Naming Structure

Follow these principles for naming metrics:

- Use a format that includes library, metric name, unit, and suffix
  (e.g., `node_file_system_free_bytes`)
- Use snakecase (words separated by underscores)
- Be specific to avoid confusion
- Use lowercase letters and base units
- Avoid conflicts with existing Prometheus metrics
- Avoid special characters in metric names

## Limitations to Monitoring Metrics

Remember that monitoring has costs:

- **Cardinality**: The total number of time series being monitored
- **Resource Cost**: High cardinality can lead to significant resource consumption
- **Complex Metrics**: Metrics like histograms with multiple labels consume more resources

## Adding Instrumentation to a Docker WebApp

Let's create a dockerized Flask application with Prometheus metrics:

```bash
# Create the directory structure
mkdir -p instrumentation/flask_app/app
```

Create the application files:

1. `instrumentation/flask_app/app/wsgi_prom.py`:
```python
from flask import Flask, request, Response
from prometheus_client import Counter, generate_latest

COUNTER = Counter('app_requests', 'App Requests.')

app = Flask(__name__)

@app.route('/')
def hello():
    COUNTER.inc()
    return 'Scrap Me!'

@app.route("/metrics")
def metrics():
    return Response(generate_latest(), 200, mimetype="text/plain")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

2. `instrumentation/flask_app/app/uwsgi.ini`:
```ini
[uwsgi]
module = wsgi_prom
callable = app
```

3. `instrumentation/flask_app/Dockerfile`:
```dockerfile
FROM tiangolo/uwsgi-nginx-flask:latest
RUN pip install prometheus_client
ENV LISTEN_PORT 5000
EXPOSE 5000
COPY ./app /app
WORKDIR /app
```

Build and run the Docker container:

```bash
# Navigate to the Flask app directory
cd instrumentation/flask_app

# Build the Docker image
docker build -t promcourse/app .

# Run the container
docker run -d --name my_app -p 5000:5000 promcourse/app
```

Now, update the Prometheus configuration to monitor our Flask app:

```bash
# Edit prometheus.yml to replace the test job with my_app
cat > prom-config << EOF
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'node'
    static_configs:
      - targets: ['nodeexporter:9100']
  
  - job_name: 'my_app'
    static_configs:
      - targets: ['localhost:5000']
EOF

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

![Flask App Metrics](images/image65.png)

Generate traffic to the app:

```bash
# Create a script to generate traffic
cat > instrumentation/curler.sh << EOF
#!/bin/bash

while :
do
    curl http://localhost:5000/
    sleep \$((RANDOM % 300 ))
done
EOF

# Make the script executable
chmod 770 instrumentation/curler.sh

# Run the script
./instrumentation/curler.sh &
```

![App Metrics in Prometheus](images/image67.png)

After a while, you should see the app_requests_total metric in Prometheus. You can also create a more advanced query like:

```
rate(app_requests_total[5m])
```

This will show the rate of requests to your app over a 5-minute window.

![App Request Rate](images/image69.png)

You can also calculate the uptime of your application using:

```
time() - app_requests_created
```

This will show the total age of your application in seconds.