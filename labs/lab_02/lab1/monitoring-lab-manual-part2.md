# 🚀 Monitoring Lab Manual - Part 2: Zabbix 7.0 and Basic Monitoring Setup

## Introduction

In this part of the lab, you will configure the Zabbix 7.0 monitoring system that you deployed in Part 1. You'll set up various monitoring scenarios including system resources, web applications, and databases. By combining pre-made templates with custom configurations, you'll learn how to efficiently set up a comprehensive monitoring system.

**Time allocation:** 1 hour total
- Zabbix Initial Configuration: 15 minutes
- System Monitoring with Zabbix: 15 minutes
- Web Application Monitoring: 15 minutes
- Database Monitoring Setup: 15 minutes

---

## 1. Zabbix Initial Configuration (15 min)

### 1.1 Access the Zabbix Web Interface

1. Open your web browser and navigate to:
   ```
   https://your-server-ip:8443
   ```

   > **Note:** Since we're using self-signed certificates, you'll see a security warning. Click "Advanced" and then "Accept the Risk and Continue" (or equivalent in your browser).

2. You should see the Zabbix login screen. Use the default credentials:
   - Username: **Admin**
   - Password: **zabbix**

   > **Important:** Zabbix usernames are case-sensitive. Make sure to use "Admin" with a capital A.

### 1.2 Change the Admin Password

1. Once logged in, click on your username in the top-right corner.
2. Select **Profile** from the dropdown menu.
3. Click on the **Change password** button.
4. Enter a new secure password and click **Update**.

   > **Security Note:** Choose a strong password as this account has full administrative access to your monitoring system.

### 1.3 Configure General Settings

1. Go to **Administration** → **General**.
2. Click on the **GUI** section and configure:
   - Default theme: **Dark** (or your preference)
   - Working hours: Set to your typical working hours (e.g., **09:00-18:00**)
   - Click **Update** to save changes.

### 1.4 Create a New User Group and User
Creating separate user accounts with appropriate permissions is a good security practice.

1. Go to **User groups**.
2. Click **Create user group**.
3. Enter:
   - Group name: **Adminnid**
   - Frontend access: **System default**
   - Permissions: Add permissions for host groups you want this group to monitor
   - Click **Add** to save.

4. Go to **Users**.
5. Click **Create user**.
6. In the "User" tab, enter:
   - Username: **admin**
   - Password: Enter a secure password
   - User groups: Select **Adminnid**
   - Choose Permissions - **Admin role**
   - Click **Add** to save.

---

## 2. System Monitoring with Zabbix (15 min)

### 2.1 Review and Configure Zabbix Server

1. **Check the Zabbix Agent IP Address**
   - Run the following command to determine the agent's IP address:
     ```bash
     docker inspect zabbix-agent | grep IPAddress
     ```
   - Note down the IP address (e.g., 172.21.0.10)

2. Add and configure Zabbix Agent, Zabbix Server(you already have), MySQL Database. 

Use this table as a guide to properly configure all your hosts:

| Host | Host Name | Interface | Encryption | Templates | Macros | Purpose |
|------|-----------|-----------|------------|-----------|--------|---------|
| **Zabbix Server** | zabbix-server | 172.21.0.10:10050 | No encryption | • Linux by Zabbix agent<br>• Zabbix server health | None needed | Monitors the Zabbix server itself |
| **Zabbix Agent** | zabbix-agent | 172.21.0.10:10050 | Connections from host<br>•Certificate Issuer: TLSConnect=cert<br>•Subject: TLSAccept=cert<br>•No encryption for both directions| • Linux by Zabbix agent active | None needed | Monitors the agent system |
| **MySQL Database** | mysql-service | 172.21.0.10:10050 | No encryption | • MySQL by Zabbix agent 2 | • {$MYSQL.DSN}: tcp://mysql-service:3306<br>• {$MYSQL.USER}: monitor<br>• {$MYSQL.PASSWORD}: monitor_pwd | Monitors MySQL metrics |

**Important Notes:**
- The host name in Zabbix must match exactly what's in the agent configuration file (e.g., Hostname=zabbix-agent)
- All hosts use the same agent IP address because the single agent collects data for all containers
- For secure communication, use Certificate-based encryption with the certificates created in Part 1
- Configure encryption settings as follows:
  - Connections to host: Certificate only (select only Certificate)
  - Connections from host: Both No encryption and Certificate checked
  - Issuer: TLSConnect=cert
  - Subject: TLSAccept=cert


3. **Verify Connection Status. Mysql data can take time!!!!!!**
   - Navigate to **Monitoring → Problems**
   - The agent availability problem should resolve within a few minutes
   - Go to **Monitoring → Latest data** and filter by host to see incoming data

## 3. Web Application Monitoring (15 min)

### 3.1 Configure Web Scenario (Optional)
   Visible name: Web App -> Host Name: web-app -> Interface: 172.21.0.10:10050 -> Templates: Website by Browser

https://bestmonitoringtools.com/zabbix-web-monitoring-create-web-scenarios-with-examples/

## 4. Database Monitoring Setup (15 min)


### 4.1 Verify MySQL Monitoring

1. Go to **Monitoring → Latest data**
2. Filter by Host: "mysql-service"
3. You should see various MySQL metrics being collected
4. If no data is visible, check:
   - That the monitor user exists in MySQL with proper permissions
   - That the macros are configured correctly
   - That the agent has access to the MySQL container

### 4.2 Create a MySQL Dashboard

1. Go to **Monitoring → Dashboards**
2. Click **Create dashboard**
3. Enter a name: **MySQL Performance**
4. Click **Add** → **Graph widget**
5. Configure:
   - Title: **MySQL Connections**
   - Data set: Select appropriate MySQL connection items
6. Click **Add** to add the widget
7. Add additional widgets for other metrics like:
   - MySQL Query Rate
   - MySQL Buffer Pool Usage
   - MySQL Slow Queries
8. Click **Apply** to save the dashboard

---

## 5. Troubleshooting Common Issues (10 min)

### 5.1 Host Unavailable Issues

If a host shows as unavailable:
1. Verify the agent's IP address with `docker inspect zabbix-agent | grep IPAddress`
2. Make sure the IP address and port are correctly configured in Zabbix
3. Check that "No encryption" is selected if you're having issues with certificate-based encryption
4. Verify the host name matches exactly what's in the agent configuration

### 5.2 No Data Collected

If items show "no data":
1. Check that the correct templates are linked to the host
2. Verify that the agent is accessible (navigate to **Monitoring → Hosts** and check the "Availability" column)
3. Check the agent logs: `docker logs zabbix-agent`
4. Verify that item keys are correct and supported by the agent

### 5.3 MySQL Monitoring Issues

If MySQL monitoring isn't working:
1. Verify the DSN, username, and password macros
2. Check that the monitor user exists in MySQL:
   ```sql
   SELECT User FROM mysql.user WHERE User='monitor';
   ```
3. Verify the monitor user has the necessary permissions:
   ```sql
   SHOW GRANTS FOR 'monitor'@'%';
   ```

---

## Conclusion

You have now completed Part 2 of the Monitoring Lab. You have:
- Configured Zabbix 7.0 with appropriate security settings
- Set up system monitoring with custom and template items
- Created web application monitoring scenarios
- Configured MySQL database monitoring
- Created basic dashboards and troubleshooting approaches

In Part 3, you will integrate Grafana with Zabbix for advanced visualizations and set up Loki for log management.