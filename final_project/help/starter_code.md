# app.py - A simple Flask app to monitor
from flask import Flask, jsonify
import random
import time

app = Flask(__name__)

# Simple counter to track visitors
visitors = 0

@app.route('/')
def home():
    global visitors
    visitors += 1
    # Simulate some random processing time
    time.sleep(random.random())
    return jsonify({
        "message": "Hello from Cool Tech Store!",
        "visitors": visitors
    })

@app.route('/products')
def products():
    # List of cool tech products
    products = [
        {"name": "Cool Laptop", "price": 999},
        {"name": "Awesome Phone", "price": 599},
        {"name": "Magic Headphones", "price": 199}
    ]
    return jsonify(products)

@app.route('/health')
def health():
    # Simple health check
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

# docker-compose.yml - Basic setup to start with
version: '3'
services:
  web:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - .:/app

  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"

# prometheus.yml - Basic Prometheus config
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'flask-app'
    static_configs:
      - targets: ['web:5000']