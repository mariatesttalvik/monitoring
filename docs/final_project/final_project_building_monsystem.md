# Final Project: My First Monitoring System 🚀

Hey there! Welcome to your final project in monitoring systems. Don't worry - we'll keep it fun and practical!

## What Are We Building? 🛠️

We're going to build a simple monitoring system for a small web application. Think of it like creating a dashboard for your favorite game's stats, but for a website instead!

## Project Goals 🎯

- Learn how different monitoring tools work together
- Set up your first monitoring dashboard
- Understand basic logging and alerting
- Have fun while learning!

## The Story 📖

Imagine you're helping a small online shop called "Cool Tech Store". They sell gadgets and want to know:
- Is their website working?
- How many people are visiting?
- Are there any errors?
- Is the server healthy?

## What You'll Need 🧰

1. Docker and Docker Compose
2. Basic Python knowledge
3. Terminal/Command Prompt
4. A text editor (VS Code recommended!)

## Main Tasks 📋

### 1. Basic Setup (30% of grade)
- [ ] Get the Flask app running
- [ ] Make Docker containers work
- [ ] Connect all services

### 2. Monitoring (30% of grade)
- [ ] Set up Prometheus to collect data
- [ ] Create a simple Grafana dashboard showing:
  - Number of visitors
  - Error count
  - Server health (CPU, Memory)

### 3. Logging (20% of grade)
- [ ] Configure ELK stack
- [ ] Collect application logs
- [ ] View logs in Kibana

### 4. Extras (20% of grade)
- [ ] Add simple alerts
- [ ] Create a nice dashboard
- [ ] Write what you learned

## How We'll Grade 📝

### Main Points (70%)
- Does it work? (30%)
- Can you explain how it works? (20%)
- Is everything connected properly? (20%)

### Extra Points (30%)
- Nice looking dashboard (10%)
- Additional features (10%)
- Good documentation (10%)

## Tips for Success 💡

1. Start Simple!
   - First, make each part work separately
   - Then connect them together
   - Finally, make it look nice

2. Common Problems & Solutions:
   - Docker not starting? Check if ports are free
   - Can't see metrics? Check connections
   - Logs not showing? Check paths

3. Testing Your Work:
   ```bash
   # Check if Flask is working
   curl http://localhost:5000/

   # Check Prometheus
   curl http://localhost:9090/metrics

   # Check logs
   docker-compose logs
   ```

## Need Help? 🆘

- Ask questions in class
- Check the example code
- Look at Docker logs
- Search online (it's okay!)

## Submission ✉️

Submit:
1. Your docker-compose.yml
2. Screenshots of your dashboards
3. A short write-up about what you learned
4. Any problems you faced and how you solved them

## Timeline 📅

- Week 21: Basic setup and add monitoring
- Week 22: Add logging
- Week 23: Make it nice and present!

Good luck! Remember - it's okay if everything isn't perfect. Focus on learning and having fun! 🌟