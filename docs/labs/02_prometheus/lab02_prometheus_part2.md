# Prometheus Lab Part 2: App Instrumentation and Metrics Exploration

This lab is based on your original setup — keeping **the same apps**, **the same file paths**, and **your structure**. Instead of repeating steps, we’ll create one instrumented app that includes **all Prometheus metric types**, then simulate traffic and explore what happens inside Prometheus.

✅ Focus: Build once, explore everything.

---

## 🎯 Goal
- Use the same file: `httpserver_test.py`
- Add all metric types: Counter, Gauge, Histogram, Summary
- Simulate traffic
- Explore metrics in Prometheus
- Bonus: Run the Flask version using Docker (`wsgi_prom.py`, `uwsgi.ini`, `Dockerfile`)

---

## 🧰 Environment Setup
```bash
cd ~/prometheus-monitoring
mkdir -p instrumentation
cd instrumentation
python3 -m venv venv
source venv/bin/activate
pip install prometheus_client
```
> 💡 Keep this terminal open — the app must run inside this environment.

If you open a new terminal later (for Prometheus or `curler.sh`), remember to reactivate:
```bash
cd ~/prometheus-monitoring/instrumentation
source venv/bin/activate
```

---

## 🛠️ One App: All Metrics (httpserver_test.py)
### Path:
```bash
~/prometheus-monitoring/instrumentation/httpserver_test.py
```

Create this file:
```python
import http.server
import random, time
from prometheus_client import start_http_server, Counter, Gauge, Histogram, Summary

print("HTTP Server running on :5000 (web) and :5001 (metrics)")

# METRICS
REQUESTS = Counter('test_requests_total', 'Total GET requests')
USERS = Gauge('active_sessions', 'Simulated number of users')
LATENCY = Histogram('request_latency_seconds', 'Request latency in seconds')
RESPONSETIME = Summary('response_latency_seconds', 'Response time summary')

class myHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        REQUESTS.inc()
        USERS.set(random.randint(1, 20))

        with LATENCY.time():
            with RESPONSETIME.time():
                time.sleep(random.uniform(0.2, 1.2))
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'Hello, world!')

if __name__ == '__main__':
    start_http_server(5001)
    server = http.server.HTTPServer(('0.0.0.0', 5000), myHandler)
    server.serve_forever()
```

### Run it (inside venv):
```bash
python3 httpserver_test.py
```
> App: http://localhost:5000  
> Metrics: http://localhost:5001/metrics

> ⚠️ If you are using a VM, WSL, or remote server, `localhost` refers to that machine — not your host. You must use your **VM's IP address** (e.g., `192.168.122.12`).
> If you want to test it in your browser from your host, set up **port forwarding** for ports `5000`, `5001`, and `9090`.

---

## 🧪 Simulate Real Traffic
### File:
```bash
~/prometheus-monitoring/instrumentation/curler.sh
```
Create script:
```bash
cat > curler.sh << EOF
#!/bin/bash
while :
do
  curl -s http://localhost:5000 > /dev/null
  sleep $((RANDOM % 3 + 1))
done
EOF
chmod +x curler.sh
```

### Run the script:
```bash
./curler.sh &
```
> 💡 You can run `curler.sh` in a new terminal window. Just make sure the Python app is still running in the background.

🛑 **To stop the traffic:**
```bash
ps aux | grep curler.sh
```
Find the process ID (PID) and kill it:
```bash
kill <PID>
```
Or stop all at once:
```bash
pkill -f curler.sh
```
> 💡 This is helpful if you need to edit the script or want to pause traffic generation.

---

## 🐳 Run Flask App in Docker (Optional Extension)
### File Structure:
```
~/prometheus-monitoring/instrumentation/flask_app/
├── Dockerfile
└── app/
    ├── uwsgi.ini
    └── wsgi_prom.py
```

### `wsgi_prom.py`
```python
from flask import Flask, Response
from prometheus_client import Counter, generate_latest

COUNTER = Counter('app_requests_total', 'Flask app requests')
app = Flask(__name__)

@app.route('/')
def hello():
    COUNTER.inc()
    return 'Scrap Me!'

@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype='text/plain')
```

### `uwsgi.ini`
```ini
[uwsgi]
module = wsgi_prom
callable = app
```

### `Dockerfile`
```dockerfile
FROM tiangolo/uwsgi-nginx-flask:python3.8
ENV LISTEN_PORT=5000
EXPOSE 5000
RUN pip install prometheus_client
COPY ./app /app
```

### Build and Run:
```bash
cd ~/prometheus-monitoring/instrumentation/flask_app
sudo docker build -t promcourse/app .
sudo docker run -d --name my_app -p 5002:5000 promcourse/app
```

### Check Logs (Optional):
```bash
docker logs my_app
```
> ✅ Confirm that the app is running and that no errors appear.
> 📍 Logs will show uWSGI startup and whether it's binding to the correct socket/port.

> Visit:
- App: `http://<your-vm-ip>:5002`
- Metrics: `http://<your-vm-ip>:5002/metrics`

...

## 📊 Metric Types Overview

| Metric Type   | Description                           | Use Case                                       |
|---------------|---------------------------------------|------------------------------------------------|
| **Counter**   | Only increases                        | API hits, events, errors                       |
| **Gauge**     | Can increase or decrease              | Memory usage, queue size, users                |
| **Histogram** | Measures distribution with buckets    | Request durations, response sizes              |
| **Summary**   | Quantiles (e.g., p95) + count/sum     | Percentile-based latency tracking              |

Check types by visiting `/metrics`:

```text
# TYPE test_requests_total counter
```

---

## 🧠 Metric Design Tips

| Tip                      | Why It Matters                                         |
|--------------------------|--------------------------------------------------------|
| Use `snake_case`         | Matches Prometheus style                              |
| Include a unit           | Avoids ambiguity (`_seconds`, `_bytes`)               |
| Avoid high cardinality   | Too many label values can degrade performance         |
| Stick to lowercase       | Keeps things clean and queryable                      |
| Avoid special characters | Prometheus doesn't support symbols like `!`, `-`, etc |

✅ Good: `http_response_duration_seconds_bucket`  
❌ Bad: `HttpResponseTime!`

---

## ✅ Summary

You now:

- ✅ Instrumented a basic Python server with Prometheus
- ✅ Generated and scraped custom metrics
- ✅ Containerized a Flask app with metrics
- ✅ Integrated everything into Prometheus
- ✅ Fixed VM networking and live reloading
- ✅ Identified metric types correctly in Prometheus and understood how to use them

> 🚀 Ready for Part 3? Let’s monitor **ephemeral and batch jobs** next!
