# Lab 2: Zabbix 7.0 Configuration

## Lab Overview

In this lab, you will configure the Zabbix 7.0 monitoring system that was deployed in Lab 1. You'll set up comprehensive monitoring for system resources, web applications, and databases, leveraging Zabbix 7.0's advanced features.

**Lab Time:** 1 hour

## Prerequisites

- Completed Lab 1 with all containers running
- Basic understanding of monitoring concepts
- Access to the Zabbix web interface

## Lab Tasks

1. Configure Zabbix initial settings
2. Set up system monitoring
3. Configure web application monitoring
4. Implement database monitoring
5. Explore Zabbix 7.0 specific features

---

## Task 1: Initial Zabbix Configuration

### Initial Setup
1. Access Zabbix at `https://your-server-ip:8443` (credentials: `Admin`/`zabbix`)
2. Change default admin password via Profile settings
3. Configure UI: Administration → General → GUI
   - Set Dark theme and working hours (09:00-18:00)

### User Management
1. Create Administrator group:
   - Path: Administration → User groups
   - Permissions: Grant full system access
   
2. Create admin user:
   - Path: Administration → Users
   - Assign Admin role and add to Administrators group
   - Use strong password with complexity requirements

---

## Task 2: System Monitoring Configuration

### Host Configuration
1. Get agent IP: `docker inspect zabbix-agent | grep IPAddress`

> **Critical requirement**: Set host names EXACTLY matching container names

2. Configure Host Monitoring:

   #### Zabbix Server Host
   - Navigate to Data Collection → Hosts → zabbix-server
   - Update the Interface field with the correct Agent IP: [Agent IP]:10050
   - Templates are already applied - no need to modify


   #### Zabbix Agent Host
   - Navigate to Data Collection → Hosts → Create host
   - Host name: zabbix-agent (must match container name exactly)
   - Interface: [Agent IP]:10050
   - Template: "Linux by Zabbix agent active"
   - Configure certificate-based security:
     - Host connections: Certificate
     - From host: Both "No encryption" and "Certificate"
     - Set TLSConnect=cert and TLSAccept=cert

   #### MySQL Service Host
   - Navigate to Data Collection → Hosts → Create host
   - Configure:
     - Host name: mysql-service
     - Interface: [Agent IP]:10050
     - Templates: MySQL by Zabbix agent 2
     - Macros:
       - {$MYSQL.DSN}: tcp://mysql-service:3306
       - {$MYSQL.USER}: monitor
       - {$MYSQL.PASSWORD}: monitor_pwd
   - Click Add

3. Verify Host Connectivity:
   - Navigate to Monitoring → Problems
   - Wait a few minutes for connections to establish
   - Check Monitoring → Latest data for incoming metrics

---

## Task 3: Web Application Monitoring

Check the documentation for web monitoring in Zabbix:

https://www.zabbix.com/documentation/current/en/manual/web_monitoring

1. Configure a Web Monitoring Host:
   - Navigate to Monitoring → Hosts → Create host
   - Configure:
     - Host name: web-app
     - Interface: [Agent IP]:10050
     - Templates: Website by Browser, Website certificate by Zabbix agent 2
   - Click Add

2. Create a Web Scenario:
   - Go to the web-app host → Web tab
   - Click Create web scenario
   - Name: Web App Availability
   - Application: Web monitoring
   - Agent: Zabbix
   - Steps:
     - Step name: Homepage
     - URL: http://your-server-ip:8080/
     - Required status codes: 200
     - Follow redirects: Yes
   - Click Add

3. Check Web Monitoring Results:
   - Wait a few minutes for data collection
   - Navigate to Monitoring → Latest data
   - Filter by host: web-app
   - Verify web monitoring metrics are being collected

Press couple times to Web Test page, metrics will start running

---

## Task 4: Database Monitoring

Check the documentation for dashboard in Zabbix:

https://www.zabbix.com/documentation/7.2/en/manual/web_interface/frontend_sections/dashboards?hl=Dashboard%2Cdashboard

Repo for  Mysql:
https://github.com/zabbix/zabbix/tree/master/templates/db/mysql_agent

1. Verify MySQL Monitoring:
   - Navigate to Monitoring → Latest data
   - Filter by host: mysql-service
   - Review the MySQL metrics being collected

2. Create a MySQL Performance Dashboard:
   - Navigate to Dashboards-> All Dashboards
   - Click Create dashboard
   - Name: MySQL Performance
   - Add a Graph widget:
     - Title: MySQL Connections
     - Data source: Time series
     - Add  you mysql-service as data co
   - Add additional widgets for:
     - MySQL Query Rate
     - MySQL Buffer Pool Usage
     - MySQL Slow Queries
   - Click Apply to save

3. Try to add a Custom SQL Query:

Some instructions here:
https://sbcode.net/zabbix/setup_mysql_database_monitoring/

- **If you change some configs in Docker**, don't forget to restart the container.
- We already have monitoring for the user.
- Refer to the section about `template_db_mysql.conf` for more details.
---

## Troubleshooting

If you encounter issues during this lab:

### Host Connection Problems:
- Verify the agent IP address is correct
- Check that hostnames match exactly between Zabbix and agent config
- Temporarily disable encryption to test connectivity
- Review logs: `docker logs zabbix-agent` or `docker logs zabbix-server`

### No Data Collection:
- Verify templates are properly linked
- Check item configuration details
- Ensure the agent can access the services it's monitoring
- Check for network connectivity between containers

### MySQL Monitoring Issues:
- Verify the monitor user exists: `SELECT User FROM mysql.user WHERE User='monitor';`
- Check permissions: `SHOW GRANTS FOR 'monitor'@'%';`
- Confirm DSN and credential macros are correct
- Test MySQL connectivity