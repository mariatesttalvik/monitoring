# Configuring Slack Alerts for Your Monitoring Lab

## Introduction

This guide will walk you through setting up Slack alerts for your monitoring environment. By the end of this guide, you'll have your own Slack workspace with a dedicated channel for receiving monitoring alerts from both Zabbix and Grafana.

**Time allocation:** 15 minutes

---

## 1. Creating Your Own Slack Workspace

First, let's create your personal Slack workspace:

1. Open your browser and go to [slack.com/create](https://slack.com/create)

2. Sign in with your Google account:
   - Click "Continue with Google"
   - Select your Google account
   - Authorize Slack to access your account

3. Enter your name and create a workspace:
   - Enter your full name
   - Name your workspace: `YourName-Monitoring-Lab` (replace YourName with your actual name)
   - Skip the team invitation step (click "Skip for now")

4. You now have your own Slack workspace!

## 2. Creating a Monitoring Alerts Channel

Next, create a dedicated channel for your monitoring alerts:

1. In the left sidebar of Slack, click the "+" icon next to "Channels"

2. Click "Create a channel"

3. Enter the following details:
   - Channel name: `monitoring-alerts`
   - Description: `Channel for receiving monitoring alerts from Zabbix and Grafana`
   - Make private: Leave unchecked
   - Click "Create"

4. Your new channel is now ready to receive alerts

## 3. Setting Up an Incoming Webhook

Now, create a webhook that will allow your monitoring tools to send messages to Slack:

1. Go to [api.slack.com/apps](https://api.slack.com/apps)

2. Click "Create New App"
   - Choose "From scratch"
   - Name your app "Monitoring Alerts"
   - Select your newly created workspace from the dropdown
   - Click "Create App"

3. In the left sidebar, click on "Incoming Webhooks"

4. Toggle the switch to "On" to activate incoming webhooks

5. Scroll down and click "Add New Webhook to Workspace"

6. Select the `#monitoring-alerts` channel you created earlier

7. Click "Allow"

8. You'll now see your webhook URL. Click "Copy" to copy it to your clipboard

9. ⚠️ **Important:** Save this webhook URL securely - you'll need it for configuring both Zabbix and Grafana

## 4. Configuring Zabbix to Send Alerts to Slack

Now, set up Zabbix to send alerts to your Slack channel:

### 4.1 Create a Slack Media Type in Zabbix

1. Log in to your Zabbix web interface

2. Navigate to **Administration** → **Media types**

3. Click **Create media type** (in the top-right corner)

4. Configure the following settings:
   - Name: `Slack Alerts`
   - Type: `Webhook`
   - Click "Add" in the Parameters section and add:
     - Name: `webhook_url`
     - Value: Paste your Slack webhook URL that you copied earlier

5. In the Script field, paste the following code:
```javascript
try {
    var params = JSON.parse(value);
    var req = new CurlHttpRequest();
    req.AddHeader('Content-Type: application/json');
    
    // Format timestamp
    var timestamp = params.event_date + ' ' + params.event_time;
    
    // Determine emoji based on severity
    var emoji = "🔵"; // Info default
    if (params.severity == "Warning") {
        emoji = "🟡";
    } else if (params.severity == "Average") {
        emoji = "🟠";
    } else if (params.severity == "High") {
        emoji = "🔴";
    } else if (params.severity == "Disaster") {
        emoji = "⚫";
    }
    
    var data = {
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": emoji + " " + params.event_status + ": " + params.trigger_name
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": "*Host:*\n" + params.host_name
                    },
                    {
                        "type": "mrkdwn",
                        "text": "*Severity:*\n" + params.severity
                    },
                    {
                        "type": "mrkdwn",
                        "text": "*Time:*\n" + timestamp
                    },
                    {
                        "type": "mrkdwn",
                        "text": "*Event ID:*\n" + params.event_id
                    }
                ]
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "*Description:*\n" + params.trigger_description
                }
            }
        ]
    };
    
    var resp = req.Post(params.webhook_url, JSON.stringify(data));
    
    if (req.Status() != 200) {
        throw "Response code: " + req.Status();
    }
    
    return resp;
} catch (error) {
    return "Error: " + error;
}
```

6. Click the **Message templates** tab

7. Add the following templates:
   - For **Problem**:
     Click "Add" and paste the following:
```
{
    "webhook_url": "{ALERT.SENDTO}",
    "event_status": "PROBLEM",
    "trigger_name": "{TRIGGER.NAME}",
    "trigger_description": "{TRIGGER.DESCRIPTION}",
    "host_name": "{HOST.NAME}",
    "severity": "{TRIGGER.SEVERITY}",
    "event_id": "{EVENT.ID}",
    "event_date": "{EVENT.DATE}",
    "event_time": "{EVENT.TIME}"
}
```

   - For **Recovery**:
     Click "Add" and paste the following:
```
{
    "webhook_url": "{ALERT.SENDTO}",
    "event_status": "RESOLVED",
    "trigger_name": "{TRIGGER.NAME}",
    "trigger_description": "{TRIGGER.DESCRIPTION}",
    "host_name": "{HOST.NAME}",
    "severity": "{TRIGGER.SEVERITY}",
    "event_id": "{EVENT.ID}",
    "event_date": "{EVENT.DATE}",
    "event_time": "{EVENT.TIME}"
}
```

8. Click **Add** at the bottom to save the media type

### 4.2 Set Up User Media

Now, configure how you'll receive these Slack notifications:

1. Go to **Administration** → **Users**

2. Click on your username (e.g., Admin)

3. Switch to the **Media** tab

4. Click **Add**

5. Enter:
   - Type: `Slack Alerts` (select from dropdown)
   - Send to: Paste your webhook URL
   - When active: Leave as default (1-7,00:00-24:00)
   - Use if severity: Check all severities you want to receive
   - Enabled: Checked

6. Click **Add** to save the media

7. Click **Update** to save the user configuration

### 4.3 Create an Action

Finally, create an action that will send alerts when triggers activate:

1. Go to **Configuration** → **Actions**

2. Make sure "Trigger actions" is selected in the dropdown

3. Click **Create action**

4. In the Action tab:
   - Name: `Send to Slack`
   - Conditions: By default, this will fire for all triggers. You can add conditions to limit which triggers send alerts.
   - Click "Add" under "New condition" if you want to add specific conditions (such as minimum severity)

5. Switch to the **Operations** tab:
   - Default operation step duration: `1h` (this ensures you don't get flooded with alerts)
   - Add an operation:
     - Operation type: `Send message`
     - Steps: `1-10` (will send for steps 1-10)
     - User groups: Select `Administrators` (or appropriate group)
     - Send to users: Select your username
     - Send only to: `Slack Alerts`

6. Add a recovery operation:
   - Operation type: `Send message`
   - User groups: Select `Administrators` (or appropriate group)
   - Send to users: Select your username
   - Send only to: `Slack Alerts`

7. Click **Add** at the bottom to create the action

## 5. Configuring Grafana to Send Alerts to Slack

Now, set up Grafana to also send alerts to your Slack channel:

1. Log in to your Grafana web interface

2. In the left sidebar, click on the gear icon (⚙️) to open the **Configuration** menu

3. Select **Notification channels**

4. Click **Add channel**

5. Enter the following details:
   - Name: `Slack Alerts`
   - Type: Select `Slack` from the dropdown
   - URL: Paste your Slack webhook URL
   - Recipient: `#monitoring-alerts`
   - Mention: Leave blank (or add `@here` if you want to be notified)
   - Token: Leave blank (not needed with webhooks)
   - Check "Include image" if you want graph images in alerts
   - Default (send on all alerts): Check this box

6. Click **Send Test** to verify your configuration works

7. Check your Slack channel for the test message

8. Click **Save** after confirming the test worked

## 6. Creating a Test Alert in Grafana

Let's create a simple test alert in Grafana:

1. Navigate to one of your dashboards (e.g., System Monitoring Dashboard)

2. Find a panel showing CPU usage and click on its title, then select **Edit**

3. In the panel editor, click the **Alert** tab

4. Click **Create Alert**

5. Configure the alert:
   - Name: `Test Alert - High CPU Usage`
   - Evaluate every: `1m`
   - For: `5m` (alert will trigger if condition is true for 5 minutes)
   - Conditions:
     - WHEN: `avg()` of query(A, 5m, now)
     - IS ABOVE: `80`
   - No Data & Error Handling:
     - If no data or all values are null: `No Data`
     - If execution error: `Alerting`

6. Under **Notifications**:
   - Send to: Select `Slack Alerts`
   - Message: Enter a custom message like:
     ```
     This is a test alert for high CPU usage. This would indicate a real problem in production.
     ```

7. Click **Save** in the upper right

## 7. Testing Your Alerts

Let's verify both alerting systems are working:

### 7.1 Testing Zabbix Alerts

Generate some load to trigger a Zabbix alert:

```bash
docker-compose exec zabbix-agent stress --cpu 4 --timeout 120
```

### 7.2 Testing Grafana Alerts

For Grafana alerts, you can either:
- Wait for the CPU alert to trigger naturally (if CPU stays high)
- Or temporarily lower the threshold in your Grafana alert to trigger it with normal load

### 7.3 Verify in Slack

After running the tests:
1. Open your Slack workspace
2. Go to the `#monitoring-alerts` channel
3. Verify you received alerts from both systems
4. Check that the alert formatting looks correct and contains all necessary information

## 8. Testing Alert Scenarios and Troubleshooting

### 8.1 Testing Real-World Alert Scenarios

Let's test your alerts with real-world scenarios:

#### Scenario 1: Container Failure

Simulate a service going down by stopping a critical container:

```bash
# Stop the web application container
docker-compose stop web-app

# Wait 2-3 minutes for alerts to trigger
# Then restart the container
docker-compose start web-app
```

This should trigger alerts related to web service availability. In your Slack channel, you should see alerts about the web application being unreachable, followed by recovery notifications when you restart the container.

#### Scenario 2: High System Load

Generate high CPU load to trigger resource alerts:

```bash
# Generate CPU load for 2 minutes
docker-compose exec zabbix-agent stress --cpu 4 --timeout 120
```

#### Scenario 3: Database Connection Failure

Simulate database problems by stopping the MySQL service:

```bash
# Stop the MySQL container
docker-compose stop mysql-service

# Wait 2-3 minutes for alerts to trigger
# Then restart the container
docker-compose start mysql-service
```

This should trigger database connectivity alerts in both Zabbix and Grafana.

### 8.2 Troubleshooting Alert Issues

If your alerts aren't working properly, here are some steps to diagnose and fix the problems:

### 8.1 Test Slack Webhook Directly

You can test if your Slack webhook is working correctly using a simple curl command:

```bash
curl -X POST -H 'Content-type: application/json' --data '{"text":"This is a test message from curl"}' YOUR_WEBHOOK_URL
```

Replace `YOUR_WEBHOOK_URL` with your actual Slack webhook URL. If successful, you should see a "ok" response and the message should appear in your Slack channel.

### 8.2 Check Zabbix Media Type Configuration

Verify your Zabbix Slack media type is set up correctly:

1. In Zabbix, go to **Administration** → **Media types**
2. Find your Slack media type and click **Test**
3. Enter your webhook URL in the "Send to" field
4. Add test values:
   ```
   {
       "event_status": "TEST",
       "trigger_name": "Test Trigger",
       "trigger_description": "This is a test alert",
       "host_name": "Test Host",
       "severity": "High",
       "event_id": "12345",
       "event_date": "2025-03-12",
       "event_time": "15:45:00"
   }
   ```
5. Click **Test** to send a test message

If the test fails, check:
- Your webhook URL for typos
- That your script has no JavaScript errors
- That your script has access to the CurlHttpRequest function

### 8.3 Check Zabbix Action Configuration

Verify your action is properly configured:

```bash
docker-compose exec zabbix-server zabbix_server -R config_cache_reload
```

Then check the Zabbix server logs for any errors:

```bash
docker-compose logs zabbix-server | grep -i error
```

### 8.4 Test Grafana Webhook

Check if Grafana can reach your Slack webhook:

1. In Grafana, go to **Alerting** → **Notification channels**
2. Find your Slack channel and click **Test**
3. If it fails, check Grafana's logs:
   ```bash
   docker-compose logs grafana | grep -i error
   ```

### 8.5 Check Network Connectivity

Make sure your containers can reach the Slack API:

```bash
docker-compose exec zabbix-server curl -I https://hooks.slack.com
```

You should see an HTTP/2 200 response. If not, there might be network connectivity issues.

### 8.6 Verify Trigger Conditions

If alerts aren't firing when you expect:

1. Check if your triggers are actually being activated:
   - In Zabbix, go to **Monitoring** → **Problems**
   - In Grafana, go to **Alerting** → **Alert Rules**

2. Make sure the conditions are being met:
   - For CPU alerts, verify the load is actually high enough
   - Check the time conditions (has it been in alert state long enough?)

3. For Zabbix, you can manually check the current value:
   ```bash
   docker-compose exec zabbix-server zabbix_get -s zabbix-agent -k system.cpu.util[,idle]
   ```
   This returns the idle CPU percentage - if it's below 20%, a CPU alert (80% usage) should trigger

### 8.7 Check Webhook Response Codes

If you suspect the webhook is receiving but not processing your alerts:

```bash
# For Zabbix
docker-compose exec zabbix-server tail -f /var/log/zabbix/zabbix_server.log | grep -i webhook

# For Grafana
docker-compose exec grafana tail -f /var/log/grafana/grafana.log | grep -i slack
```

Look for HTTP status codes in the logs - you want to see 200 responses.

---

## Conclusion

You've successfully set up Slack alerting for your monitoring lab! Your alerts will now be delivered to your dedicated Slack channel, making it easy to track and respond to monitoring events.

This integration demonstrates how modern monitoring systems can connect with communication tools to streamline incident response. In a production environment, you might extend this system with additional features like:

- Different channels for different severity levels
- Integration with incident management systems
- Automated escalation procedures
- Runbook links in alerts to guide troubleshooting

For this lab, your current setup provides a solid foundation for understanding how alerting works in a monitoring environment.
