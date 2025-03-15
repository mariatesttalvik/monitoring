# Monitoring Lab Manual - Part 2: Zabbix 7.0 and Basic Monitoring Setup

## Introduction

In this part of the lab, you will configure the Zabbix 7.0 monitoring system that you deployed in Part 1. You'll set up various monitoring scenarios including system resources, web applications, and databases. By combining pre-made templates with custom configurations, you'll learn how to efficiently set up a comprehensive monitoring system.

**Time allocation:** 1 hour total
- Zabbix Initial Configuration: 15 minutes
- System Monitoring with Zabbix: 15 minutes
- Web Application Monitoring: 15 minutes
- Database Monitoring Setup: 15 minutes

**Lab Strategy:**
This lab uses a blend of approaches to maximize both learning and efficiency:
- We'll import public templates for common monitoring tasks
- We'll create custom items and triggers for specific requirements
- We'll explore both approaches so you understand when to use each

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

3. Click on the **Problem display** section:
   - Problem display: **All**
   - Display OK triggers for: **15m** (15 minutes)
   - On status change triggers blink for: **5m** (5 minutes)
   - Click **Update** to save changes.

4. Click on the **Other** section:
   - Default language: Set to your preferred language
   - Click **Update** to save changes.

### 1.4 Create a New User Group and User (Optional)

Creating separate user accounts with appropriate permissions is a good security practice.

1. Go to **Administration** → **User groups**.
2. Click **Create user group**.
3. Enter:
   - Group name: **Operators**
   - Frontend access: **System default**
   - Permissions: Add permissions for host groups you want this group to monitor
   - Click **Add** to save.

4. Go to **Administration** → **Users**.
5. Click **Create user**.
6. In the "User" tab, enter:
   - Username: **operator**
   - Password: Enter a secure password
   - User groups: Select **Operators**
   - Click **Add** to save.

---

## 2. System Monitoring with Zabbix (15 min)

### 2.1 Configure Host for Zabbix Agent

1. Go to **Configuration** → **Hosts**.
2. Click **Create host** (top-right corner).
3. Enter the following information:
   - Host name: **zabbix-agent**
   - Visible name: **Lab Server**
   - Groups: Click **Select** and choose or create a group (e.g., **Lab Servers**)
   - Interfaces: Click **Add** under Agent interfaces and enter:
     - IP address: **zabbix-agent** (Docker service name)
     - Port: **10050**
     - Check **Use PSK** under "Connections"
     - PSK identity: **PSK 001** (as defined in our docker-compose.yml)
     - PSK: Enter a pre-shared key (e.g., **1a2b3c4d5e6f7g8h9i0j**)
     - Click **Add** to save the interface

4. Switch to the **Templates** tab.
5. Click **Select** next to "Link new templates".
6. Search for and select **Linux by Zabbix agent** (compatible with Zabbix 7.0).
7. Click **Select** and then **Add**.

8. Switch to the **Encryption** tab and set:
   - Connections to host: **TLS with PSK**
   - Connections from host: **TLS with PSK**

9. Click **Add** at the bottom of the page to create the host.

### 2.2 Import Public Templates and Create Custom Items

Let's use a mix of public templates for efficiency and custom items for learning purposes:

#### 2.2.1 Import Public Templates

1. Go to **Configuration** → **Templates**.
2. Click **Import** (top-right corner).
3. Download a template from the Zabbix Share website:
   - Open a new browser tab and go to [Zabbix Share](https://share.zabbix.com/)
   - Search for "Linux Monitoring" or "Docker Monitoring"
   - Download a template that interests you (look for one compatible with Zabbix 7.0)
4. Back in the Zabbix interface, click **Choose File** and select the downloaded template.
5. Keep the default import settings and click **Import**.

#### 2.2.2 Create a Custom Item - Number of Logged-in Users

Let's create one custom item to understand the process:

1. Go to **Configuration** → **Hosts**.
2. Click on **Items** next to your host "Lab Server".
3. Click **Create item** (top-right corner).
4. Enter:
   - Name: **Number of logged-in users**
   - Type: **Zabbix agent**
   - Key: **system.run[who | wc -l]**
   - Type of information: **Numeric (unsigned)**
   - Units: **users**
   - Update interval: **1m** (1 minute)
   - Applications: Click **Select** and choose or create "System"
   - Click **Add** to save.

> **Note:** Once you understand how to create a custom item, you can leverage templates for most standard monitoring needs, saving time while still gaining the knowledge of how Zabbix items work.

### 2.3 Configure Triggers

Triggers allow Zabbix to alert you when certain conditions are met. Let's create some triggers for our items:

#### 2.3 Create and Import Triggers

Most of the templates you imported will already include sensible triggers. Let's create one custom trigger to understand the process and then learn how to import additional triggers.

#### 2.3.1 Create a Custom Trigger - High User Count

1. Go to **Configuration** → **Hosts**.
2. Click on **Triggers** next to your host "Lab Server".
3. Click **Create trigger** (top-right corner).
4. Enter:
   - Name: **High number of logged-in users**
   - Severity: **Info**
   - Expression: Click on **Add** and use the expression constructor:
     - Select item: **Number of logged-in users** (the custom item we created)
     - Function: **last()**
     - Condition: **>**
     - Value: **5** (more than 5 users logged in)
   - Click **Add** to save.

#### 2.3.2 Import Trigger Template (Optional)

For more advanced triggers, you can import pre-configured templates:

1. Go to **Configuration** → **Templates**.
2. Click **Import** (top-right corner).
3. Download a trigger template from Zabbix Share or use a sample from your instructor.
4. Click **Choose File** and select the downloaded template.
5. Keep the default import settings and click **Import**.

> **Note:** While importing templates saves time, it's important to understand how triggers work. Review the imported triggers to learn how they're constructed.

---

## 3. Web Application Monitoring with Synthetic Testing (15 min)

In this section, you'll set up both basic web monitoring and more advanced synthetic end-user monitoring, which simulates how real users interact with your application.

### 3.1 What is Synthetic End-User Web Monitoring?

Synthetic monitoring is a proactive approach that simulates user interactions with your web applications or services. Unlike server-side monitoring (CPU, memory, disk usage), synthetic monitoring:

- Tests your application from the user's perspective
- Detects issues before real users encounter them
- Validates complete business processes (like login flows)
- Measures actual user experience metrics

### 3.2 Create Mock Web Pages for Synthetic Testing

First, let's create some mock pages to use for our synthetic monitoring:

1. Connect to the web-app container:
   ```bash
   docker-compose exec web-app /bin/sh
   ```

2. Verify the current content of the web root directory:
   ```bash
   ls -la /usr/share/nginx/html/
   ```
   You should see the `index.html` file we created in Part 1.

3. Create a login.php file with this command (copy and paste the entire block):
   ```bash
   cat > /usr/share/nginx/html/login.php << 'EOF'
   <?php
   $loggedIn = false;
   $error = "";
   
   if ($_SERVER['REQUEST_METHOD'] === 'POST') {
       if ($_POST['username'] === 'demo' && $_POST['password'] === 'demo123') {
           $loggedIn = true;
       } else {
           $error = "Invalid username or password";
       }
   }
   ?>
   
   <!DOCTYPE html>
   <html>
   <head>
       <title>Login - Monitoring Lab</title>
       <style>
           body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
           h1 { color: #333; }
           .form-container { max-width: 400px; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
           input[type="text"], input[type="password"] { width: 100%; padding: 8px; margin-bottom: 10px; }
           input[type="submit"] { background-color: #4CAF50; color: white; padding: 10px 15px; border: none; cursor: pointer; }
           .error { color: red; }
       </style>
   </head>
   <body>
       <h1>Monitoring Lab Sample Web App</h1>
       
       <?php if ($loggedIn): ?>
           <h2>Welcome, Demo User</h2>
           <p>You have successfully logged in.</p>
           <p><a href="dashboard.php">Go to Dashboard</a></p>
       <?php else: ?>
           <div class="form-container">
               <h2>User Login</h2>
               <?php if ($error): ?>
                   <p class="error"><?php echo $error; ?></p>
               <?php endif; ?>
               
               <form method="post" action="login.php">
                   <div>
                       <label for="username">Username:</label>
                       <input type="text" id="username" name="username" required>
                   </div>
                   <div>
                       <label for="password">Password:</label>
                       <input type="password" id="password" name="password" required>
                   </div>
                   <div>
                       <input type="submit" value="Login">
                   </div>
               </form>
           </div>
       <?php endif; ?>
   </body>
   </html>
   EOF
   ```

4. Create a dashboard.php file (copy and paste the entire block):
   ```bash
   cat > /usr/share/nginx/html/dashboard.php << 'EOF'
   <!DOCTYPE html>
   <html>
   <head>
       <title>Dashboard - Monitoring Lab</title>
       <style>
           body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
           h1, h2 { color: #333; }
           .dashboard-panel { padding: 20px; background-color: #f9f9f9; border-radius: 5px; border: 1px solid #ddd; margin-top: 20px; }
           .metric { margin-bottom: 10px; }
           .metric-label { font-weight: bold; display: inline-block; width: 150px; }
           .status-good { color: green; }
           .status-warning { color: orange; }
           .status-critical { color: red; }
       </style>
   </head>
   <body>
       <h1>User Dashboard</h1>
       <p>Welcome to your monitoring dashboard</p>
       
       <div class="dashboard-panel">
           <h2>Server Status</h2>
           <div class="metric">
               <span class="metric-label">CPU Usage:</span>
               <span class="status-good">32%</span>
           </div>
           <div class="metric">
               <span class="metric-label">Memory Usage:</span>
               <span class="status-warning">78%</span>
           </div>
           <div class="metric">
               <span class="metric-label">Disk Space:</span>
               <span class="status-good">43%</span>
           </div>
           <div class="metric">
               <span class="metric-label">Network Status:</span>
               <span class="status-good">Online</span>
           </div>
           <div class="metric">
               <span class="metric-label">Last Updated:</span>
               <span id="lastUpdated"></span>
           </div>
       </div>
       
       <script>
           document.getElementById('lastUpdated').textContent = new Date().toLocaleString();
           // Refresh data every 30 seconds
           setInterval(function() {
               document.getElementById('lastUpdated').textContent = new Date().toLocaleString();
           }, 30000);
       </script>
   </body>
   </html>
   EOF
   ```

5. Verify the files were created:
   ```bash
   ls -la /usr/share/nginx/html/
   ```
   You should now see `index.html`, `login.php`, and `dashboard.php`.

6. Test the login page by accessing it in your browser:
   ```
   http://your-server-ip:8080/login.php
   ```

7. Exit the container:
   ```bash
   exit
   ```

### 3.3 Import a Web Monitoring Template

1. Go to **Configuration** → **Templates**.
2. Click **Import** (top-right corner).
3. Download a web monitoring template:
   - Open [Zabbix Share](https://share.zabbix.com/) in a new tab
   - Search for "HTTP monitoring" or "Web monitoring"
   - Download a template compatible with Zabbix 7.0
4. In the Zabbix interface, click **Choose File** and select the downloaded template.
5. Keep the default import settings and click **Import**.

### 3.4 Create a Synthetic User Journey

Let's create a monitoring scenario that simulates a complete user journey through our application:

1. Go to **Configuration** → **Hosts**.
2. Click on **Web** next to your host "Lab Server".
3. Click **Create web scenario** (top-right corner).
4. In the "Scenario" tab, enter:
   - Name: **User Login Journey**
   - Application: Click **Select** and choose or create "Web monitoring"
   - Update interval: **2m** (2 minutes)
   - Attempts: **2** (Zabbix will try twice before marking as failed)
   - Agent: Select **Chrome 100.0.4896.127** (simulates a Chrome browser)

5. Switch to the **Steps** tab.
6. Create a series of steps that simulate a complete user journey:

#### Step 1: Homepage
1. Click **Add** to create the first step.
2. Enter:
   - Name: **Homepage**
   - URL: **http://web-app/**
   - Required status codes: **200**
   - Timeout: **15s**
   - Required string: **Monitoring Lab Sample Web App**
3. Click **Add** to add this step.

#### Step 2: Login Form
1. Click **Add** to create the next step.
2. Enter:
   - Name: **Access Login Form**
   - URL: **http://web-app/login.php**
   - Required status codes: **200**
   - Timeout: **15s**
   - Required string: **User Login**
3. Click **Add** to add this step.

#### Step 3: Submit Login
1. Click **Add** to create the next step.
2. Enter:
   - Name: **Login Submission**
   - URL: **http://web-app/login.php**
   - Post fields: **username=demo&password=demo123**
   - Follow redirects: **Yes**
   - Timeout: **15s**
   - Required string: **Welcome, Demo User**
3. Click **Add** to add this step.

#### Step 4: Access Dashboard
1. Click **Add** to create the next step.
2. Enter:
   - Name: **User Dashboard**
   - URL: **http://web-app/dashboard.php**
   - Timeout: **15s**
   - Required string: **Server Status**
3. Click **Add** to add this step.

7. Click **Add** at the bottom of the page to create the web scenario.

### 3.5 Configure Performance Triggers

Now let's set up triggers to alert us about performance issues:

1. Go to **Configuration** → **Hosts**.
2. Click on **Triggers** next to your host "Lab Server".
3. Click **Create trigger** (top-right corner).
4. For the Login Journey Too Slow trigger, enter:
   - Name: **Web: Login journey too slow**
   - Severity: **Warning**
   - Expression: Click on **Add** and use the expression constructor:
     - Select item: **web.test.time[User Login Journey,,last]**
     - Function: **avg(5m)**
     - Condition: **>**
     - Value: **3** (seconds)
   - Click **Add** to save.

5. Create another trigger for Login Failures:
   - Name: **Web: Login process failure**
   - Severity: **High**
   - Expression: Click on **Add** and use the expression constructor:
     - Select item: **web.test.fail[User Login Journey]**
     - Function: **last()**
     - Condition: **=**
     - Value: **1** (failed)
   - Click **Add** to save.

### 3.6 Simulate Web Performance Issues

To test your monitoring, let's introduce artificial latency to the login page:

1. Connect to the web-app container:
   ```bash
   docker-compose exec web-app /bin/sh
   ```

2. Add a random delay to the login.php file:
   ```bash
   sed -i 's/<?php/<?php\n\/\/ Sometimes add delay to simulate slowness\nif(rand(1, 10) > 7) {\n  sleep(2);\n}\n/g' /usr/share/nginx/html/login.php
   ```

3. Verify the change was applied:
   ```bash
   head -10 /usr/share/nginx/html/login.php
   ```
   You should see the added delay code at the beginning of the file.

4. Exit the container:
   ```bash
   exit
   ```

### 3.7 Verify Your Synthetic Monitoring

1. Go to **Monitoring** → **Latest data**.
2. Filter by your host and select Web monitoring items.
3. Look for data from your "User Login Journey" scenario.
4. You should see metrics for:
   - Download speed
   - Response time for the entire scenario
   - Response time for each step
   - Success/failure status

5. Wait 5-10 minutes and then check **Monitoring** → **Problems**.
   - You may see warning alerts about response time, depending on the random delays we added

**Why This Matters**: Synthetic monitoring gives you the ability to detect issues from the user's perspective before they impact real users. By monitoring complete user journeys, you can identify problems that might not be visible from server-side monitoring alone.

---

## 4. Database Monitoring Setup (15 min)

Now let's configure Zabbix to monitor our MySQL database using a public template and minimal configuration.

### 4.1 Verify Database Monitoring User in MySQL

We already created a monitoring user in the previous section, but let's verify it:

1. Open a terminal and connect to the MySQL service:
   ```bash
   docker-compose exec mysql-service mysql -u root -pmysql_pwd
   ```

2. Verify the monitoring user exists and has the correct permissions:
   ```sql
   SELECT user, host FROM mysql.user WHERE user = 'monitor';
   SHOW GRANTS FOR 'monitor'@'%';
   ```

3. If the user doesn't exist, create it:
   ```sql
   CREATE USER 'monitor'@'%' IDENTIFIED BY 'monitor_pwd';
   GRANT SELECT, PROCESS, SHOW DATABASES, REPLICATION CLIENT ON *.* TO 'monitor'@'%';
   FLUSH PRIVILEGES;
   ```

4. Exit MySQL:
   ```sql
   EXIT;
   ```

### 4.2 Import MySQL Monitoring Template

1. Go to **Configuration** → **Templates**.
2. Click **Import** (top-right corner).
3. Several MySQL monitoring templates are available from Zabbix out of the box, but if you prefer an enhanced version:
   - Open [Zabbix Share](https://share.zabbix.com/) in a new tab
   - Search for "MySQL monitoring" and download a comprehensive template
   - Choose one that's compatible with Zabbix 7.0
4. In the Zabbix interface, click **Choose File** and select the downloaded template.
5. Keep the default import settings and click **Import**.

### 4.3 Configure MySQL Host with the Template

1. Go to **Configuration** → **Hosts**.
2. Click **Create host**.
3. Enter:
   - Host name: **mysql-service**
   - Visible name: **MySQL Database**
   - Groups: Click **Select** and choose or create "Databases"
   - Interfaces: Click **Add** under Agent interfaces and enter:
     - IP address: **mysql-service** (Docker service name)
     - Port: **3306**
   - Click **Add** to save the interface.

4. Switch to the **Templates** tab.
5. Click **Select** next to "Link new templates".
6. Search for and select the MySQL template you imported (or use **MySQL by Zabbix agent 2** that comes with Zabbix).
7. Click **Select** and then **Add**.

8. Switch to the **Macros** tab.
9. Add the following macros:
   - `{$MYSQL.DSN}`: **mysql://monitor:monitor_pwd@mysql-service:3306**
   - `{$MYSQL.USER}`: **monitor**
   - `{$MYSQL.PASSWORD}`: **monitor_pwd**

10. Click **Add** at the bottom of the page to create the host.

> **Note:** The beauty of using templates is that they come with pre-defined items, triggers, and often graphs. Review the template to see what's already being monitored.

### 4.4 Generate Test Database Activity

Let's create some database activity to test our monitoring:

1. Connect to the MySQL service:
   ```bash
   docker-compose exec mysql-service mysql -u testuser -ptest_pwd testdb
   ```

2. Run a few queries to generate some activity:
   ```sql
   -- Simple queries
   SELECT * FROM test_data;
   UPDATE test_data SET value = value + 1.0 WHERE name = 'Server CPU';
   
   -- Create a more complex query that will show up in monitoring
   SELECT name, AVG(value) as avg_value 
   FROM test_data 
   GROUP BY name 
   ORDER BY avg_value DESC;
   
   -- Generate a slow query (this will take a few seconds)
   SELECT SLEEP(5), name, value FROM test_data;
   ```

3. Exit MySQL:
   ```sql
   EXIT;
   ```

4. View the MySQL metrics in Zabbix:
   - Go to **Monitoring** → **Latest data**
   - Filter by the MySQL host and apply
   - You should see various MySQL metrics being collected
   - Look specifically for connection-related metrics and query statistics

---

## 5. Verify Your Monitoring Setup (10 min)

Now that you've configured various monitoring aspects in Zabbix, let's verify that everything is working properly.

### 5.1 Check Host Availability

1. Go to **Monitoring** → **Hosts**.
2. You should see your hosts "Lab Server" and "MySQL Database" with green "Available" status.
3. If any hosts show "Not available" or "Unknown", check the troubleshooting section.

### 5.2 View Latest Data

1. Go to **Monitoring** → **Latest data**.
2. Use the filter to select your hosts and click **Apply**.
3. You should see data from various items you've configured, including:
   - CPU usage
   - Memory usage
   - Disk space
   - Number of logged-in users
   - Web application response times
   - MySQL connection counts

### 5.3 Test Problem Detection

Let's generate some test events to verify that your triggers work:

1. Generate CPU load to trigger alerts:
   ```bash
   # Install stress tool if needed
   docker-compose exec zabbix-agent apt-get update
   docker-compose exec zabbix-agent apt-get install -y stress
   
   # High CPU load for 60 seconds
   docker-compose exec zabbix-agent stress --cpu 2 --timeout 60
   ```

2. Go to **Monitoring** → **Problems**.
3. You should see problem alerts appear as the triggers are activated.
4. After the stress test completes, watch the problems resolve as conditions return to normal.

> **Note:** Real-world monitoring is about detecting problems before they affect users. This simple test confirms your triggers are configured correctly.

---

## Troubleshooting Tips

### Zabbix Agent Connection Issues
- Check that the Zabbix agent is running: `docker-compose ps zabbix-agent`
- Verify agent configuration: `docker-compose exec zabbix-agent cat /etc/zabbix/zabbix_agent2.d/zabbix_agent2.conf`
- Test connectivity: `docker-compose exec zabbix-server zabbix_get -s zabbix-agent -k system.hostname`

### Template Import Issues
- Ensure the template is compatible with your Zabbix version (7.0)
- Check that required macros are defined for the template
- Review the template documentation for any special requirements

### Web Monitoring Issues
- Verify web application is accessible: `docker-compose exec zabbix-server curl http://web-app/`
- Check web scenario settings for correct URLs and expected content
- Review latest data for web monitoring items to see specific errors

### Database Monitoring Issues
- Verify MySQL connection: `docker-compose exec zabbix-server mysql -h mysql-service -u monitor -pmonitor_pwd -e "SELECT VERSION()"`
- Check MySQL user permissions: `docker-compose exec mysql-service mysql -u root -pmysql_pwd -e "SHOW GRANTS FOR 'monitor'@'%'"`
- Review macros used in the MySQL template for correct connection details

### Dashboard Import Issues
- If dashboard widgets are empty, check that the required hosts and items exist
- Some dashboards may require specific templates to be installed first
- Check Zabbix documentation for dashboard compatibility information

---

## Conclusion

You have now completed Part 2 of the Monitoring Lab. You have:
- Configured Zabbix for initial use
- Set up system resource monitoring using both templates and custom items
- Created web application monitoring using both templates and custom scenarios
- Established database monitoring using pre-configured templates
- Verified the monitoring system can detect problems

**Key Takeaways:**
- Templates save time while providing comprehensive monitoring
- Custom items and triggers allow specific monitoring requirements to be met
- Combining both approaches gives you the best balance of efficiency and customization
- Zabbix provides basic monitoring visualization, but more advanced visualization will be covered in Part 3

In Part 3, you will extend your monitoring capabilities using Grafana for advanced visualization and Loki for log monitoring, building on the foundation you've established here.
